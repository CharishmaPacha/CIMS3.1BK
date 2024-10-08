/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  SAK     pr_Receipts_ReceivingReport: Made changes to get details from vwReceiptDetails (HA-1692)
  2020/08/10  NB      pr_Receipts_ReceivingReport_V3: added procedure for V3 Reports_GetData generic implementation(CIMSV3-1022)
  2020/08/06  HYP     pr_Receipts_ReceivingReport : Added condition in @vReceiptDetail (HA-1121)
  2020/02/09  MS      pr_Receipts_ReceivingReport: Changes to get the Dataset of LPNs & LD's (JL-61)
  2013/10/10  TD      pr_Receipts_ReceivingReport: Sending UPC instead of barcode.
  2103/08/19  TD      pr_Receipts_ReceivingReport:Added to output xml to return InnerPacksPerLPN,
  2013/07/30  NY      Added new procedure pr_Receipts_ReceivingReport(ta9185).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_ReceivingReport') is not null
  drop Procedure pr_Receipts_ReceivingReport;
Go
/*------------------------------------------------------------------------------
Proc pr_Receipts_ReceivingReport:
<REPORTS>
  <RECEIVING_REPORT>
    <ReceiptNumber>SH_44</ReceiptNumber>
      <Type>A</Type>
      <TypeDesc>ASN</TypeDesc>
      <VendorId />
      <VendorName />
      <NumLPNs>10</NumLPNs>
      <LPNsReceived>9</LPNsReceived>
      <NumUnits>120</NumUnits>
      <UnitsReceived>17</UnitsReceived>
      <LPNsRemaining>1</LPNsRemaining>
      <UnitsRemaining>103</UnitsRemaining>
    <ReceiptDetails>
      <ReceiptLine>1</ReceiptLine>
      <SKU>2012-13-25307-10-2-R</SKU>
      <Description>Teen G Sundance Pant</Description>
      <Barcode />
      <Pack />
      <QtyOrdered>20</QtyOrdered>
      <QtyReceived>12</QtyReceived>
      <Remaining>8</Remaining>
    </ReceiptDetails>
  </RECEIVING_REPORT>
</REPORTS>
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_ReceivingReport
  (@ReceiptId         TRecordId,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @xmlReceiptSummary xml output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vReceiptNumber      TReceiptNumber,
          @vReceiptSummaryXML  TXML,
          @vReceiptHeaderXML   TXML,
          @vReceiptDetailsXML  TXML,
          @vPalletsXML         TXML,
          @vLPNDetailsXML      TXML,
          @vNumPallets         TInteger,
          @vPalletsReceived    TInteger,
          @vPalletsToReceive   TInteger;
begin /* pr_Receipts_ReceivingReport */
begin try
  begin transaction;

  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  if (not exists (select *
                  from ReceiptHeaders
                  where ReceiptId = @ReceiptId))
    set @vMessageName = 'ReceiptIsInvalid';

  if (@vMessageName is not null)
    goto ErrorHandler;

  select @vReceiptHeaderXML  = (select *, LPNsInTransit as LPNsRemaining, QtyToReceive as UnitsRemaining
                                from  vwReceiptHeaders
                                where (ReceiptId    = @ReceiptId) and
                                      (BusinessUnit = @BusinessUnit)
                                for xml raw('ReceiptHeader'), elements);

  select @vReceiptDetailsXML = (select *, case when QtyReceived > QtyOrdered then QtyReceived-QtyOrdered else 0 end as QtyOverReceived
                                from  vwReceiptDetails
                                where (ReceiptId = @ReceiptId)
                                for xml raw('ReceiptDetails'), elements);

  select @vLPNDetailsXML     = (select *
                                from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
                                where (L.ReceiptId = @ReceiptId)
                                for xml raw('LPNDetails'), elements);

  /* Get list of Pallets on the Receipt grouped by SKU */
  select L.PalletId, LD.SKUId, sum(LD.InnerPacks) as LDInnerPacks, sum(LD.Quantity) as LDQuantity,
         sum(case when L.Status = 'T' /* InTransit */ then 1 else 0 end) LPNsInTransit,
         sum(case when L.Status = 'R' /* Received */ then 1 else 0 end) LPNsReceived,
         sum(case when L.Status = 'T' /* InTransit */ then LD.Quantity else 0 end) UnitsInTransit,
         sum(case when L.Status = 'R' /* Received */ then LD.Quantity else 0 end) UnitsReceived,
         min(case when L.UDF4   = 'Y' then 'Cross Dock Pallets' + coalesce(' - ' + L.UDF5, '') -- CrossDockFlag
                                      else 'Inventory Pallets' end) LPN_UDF4,
         L.UDF5 LPN_UDF5
  into #ReceiptPallets
  from LPNs L
    join LPNDetails LD on (L.LPNId = LD.LPNId)
    join SKUs S        on (S.SKUId = LD.SKUId)
  where (L.ReceiptId = @ReceiptId)
  group by L.PalletId, LD.SKUId, L.UDF5;

  /* get summary of LPNs for each Pallet */
  select L.PalletId,
         count(*) NumLPNs,
         sum(case when L.Status = 'T' /* InTransit */ then 1 else 0 end) LPNsInTransit,
         sum(case when L.Status = 'R' /* Received */ then 1 else 0 end) LPNsReceived
  into #PalletLPNs
  from LPNs L
  where (L.ReceiptId = @ReceiptId)
  group by L.PalletId
  having (count(*) > 0);

  select @vNumPallets       = @@rowcount;
  select @vPalletsReceived  = count(distinct PalletId) from #PalletLPNs where LPNsInTransit = 0;
  select @vPalletsToReceive = count(distinct PalletId) from #PalletLPNs where LPNsInTransit > 0;

  /* Get the addtional info for the above Pallets & SKUs */
  select @vPalletsXML        = (select RP.*,
                                       LPNsInTransit as RemainingLPNs,
                                       UnitsInTransit as RemainingUnits,
                                       S.SKU, S.UPC, S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5,
                                       S.Description,
                                       P.Pallet, P.Status as PalletStatus, PST.StatusDescription as PalletStatusDesc,
                                       P.PalletType, P.LocationId,
                                       LOC.Location, P.Ownership, P.Warehouse,
                                       P.NumLPNs, P.InnerPacks PalletInnerPacks, P.Quantity PalletQuantity,
                                       P.DestZone, P.DestLocation, P.PutawayClass, P.PickingClass, @vNumPallets as NumPallets,
                                       @vPalletsReceived as PalletsReceived, @vPalletsToReceive as PalletsToReceive
                                from #ReceiptPallets RP
                                  join Pallets P                on (RP.PalletId      = P.PalletId)
                                  left join Locations LOC       on (LOC.LocationId   = P.LocationId)
                                  left join SKUs S              on (RP.SKUId         = S.SKUId)
                                  left outer join Statuses PST  on (P.Status         = PST.StatusCode) and
                                                                   (PST.Entity       = 'Pallet'      ) and
                                                                   (PST.BusinessUnit = P.BusinessUnit)
                                for xml raw('Pallets'), elements);

  select @vReceiptSummaryXML = coalesce(@vReceiptSummaryXML, '') +
                               dbo.fn_XMLNode('RECEIVING_REPORT',
                                 coalesce (@vReceiptHeaderXML,  '') +
                                 coalesce (@vReceiptDetailsXML, '') +
                                 coalesce (@vPalletsXML,        '') +
                                 coalesce (@vLPNDetailsXML,     ''));

  select @xmlReceiptSummary  = dbo.fn_XMLNode('REPORTS', @vReceiptSummaryXML);

ErrorHandler:
  exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch
ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_ReceivingReport */

Go
