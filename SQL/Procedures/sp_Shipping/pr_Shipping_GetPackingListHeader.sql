/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/06  RT      pr_Shipping_GetPackingListHeader: Included OrderSubTotal (HA-1198)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetPackingListHeader') is not null
  drop Procedure pr_Shipping_GetPackingListHeader;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetPackingListHeader: Returns the Header Info of Packing List
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetPackingListHeader
  (@LoadId           TRecordId,
   @OrderId          TRecordId,
   @LPNId            TRecordId,
   @Report           TName,
   @PackingListType  TTypeCode,
   @xmlRulesData     TXML,
   @PLHeaderxml      TXML     output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription,

          @vWaveType             TTypeCode,
          @vWaveNumOrders        TCount,
          @vLPN                  TLPN,
          @vAdditionalPLInfo1    TVarchar,
          @vIsPLDetailsRequired  TTypeCode,
          @vInsurance            TUDF,
          @vOtherCharges         TUDF,

          @vTotalUnitsAssigned   TQuantity,
          @vOrderTaxAmount       TMoney,
          @vTotalShippingCost    TMoney,
          @vOrderSubTotal        TMoney,
          @vOrderTotal           TMoney,
          @vActualWeight         TWeight,
          @vActualVolume         TVolume,
          @vTotalPages           TInteger,
          @vBusinessUnit         TBusinessUnit,
          @vUserId               TUserId,
          @vPackedDate           TDateTime;

  declare @ttPackingListDetails  TPackingListDetails;

begin
  SET NOCOUNT ON;

  select  @vInsurance     = '0.00', /* Use if host sent */
          @vOtherCharges  = '0.00'; /* Other is for any other charges placed onthe shipment by the shipper (e.g.,handling charge). */

  /* Get the WaveType and BusinessUnit */
  select @vWaveType          = PB.BatchType,
         @vBusinessUnit      = OH.BusinessUnit,
         @vTotalShippingCost = OH.TotalShippingCost,
         @vWaveNumOrders     = PB.NumOrders
  from OrderHeaders OH
    left outer join PickBatches PB on (OH.PickBatchId = PB.RecordId)
  where (OrderId = @OrderId);

  /* Get the LPN */
  select @vLPN = LPN
  from LPNs
  where (LPNId = @LPNId);

  select top 1 @vPackedDate = coalesce(PackedDate, PickedDate)
  from LPNDetails
  where (OrderId = @OrderId)
  order by PickedDate desc;

  /* Get the AddtionalInfo to print on the packing list */
  if (@vWaveType in ('PTL', 'PTLC') and (@vLPN is not null))
    exec pr_ShipLabel_GetPrintDataStream @LPNId, 'PackingList_AddInfo' /* LabelFormatName */, @vBusinessUnit, @vAdditionalPLInfo1 output

  /* Get additional Packing List info */
  exec pr_RuleSets_Evaluate 'PackingList_Info1', @xmlRulesData, @vAdditionalPLInfo1 output;

  /* Compute the Total Tax Amount for this package */
  select @vOrderTaxAmount     = sum(coalesce(UnitTaxAmount, 0) * coalesce(UnitsAssigned, 0)),
         @vOrderSubTotal      = sum(coalesce(UnitSalePrice, 0) * coalesce(UnitsAssigned, 0)),
         @vTotalUnitsAssigned = sum(coalesce(UnitsAssigned, 0))
  from OrderDetails
  where (OrderId = @OrderId);

  select @vActualWeight = sum(ActualWeight),
         @vActualVolume = sum(ActualVolume)
  from vwLPNPackingListHeaders
  where (OrderId = @OrderId);

  select @vOrderTotal = @vOrderTaxAmount + @vTotalShippingCost + @vOrderSubTotal;

  /* Packing List Details for the Order*/
  if (@PackingListType in ('ORD', 'ORDWithLDs'))
    begin
      /* Packing List Header for the Order */
      set @PLHeaderxml = (select *
                                 ,@vTotalUnitsAssigned as TotalUnitsAssigned
                                 ,@vOrderTaxAmount     as OrderTaxAmount
                                 ,@vOrderTotal         as OrderTotal
                                 ,@vOrderSubTotal      as OrderSubTotal
                                 ,@vActualWeight       as ActualWeight
                                 ,@vActualVolume       as TotalVolume
                                 ,'ORD'                as PackingListType
                                 ,@vAdditionalPLInfo1  as AdditionalPLInfo1
                                 ,@vWaveType           as WaveType
                                 ,@vWaveNumOrders      as WaveNumOrders
                                 ,@vInsurance          as Insurance
                                 ,@vOtherCharges       as OtherCharges
                                 ,cast(@vPackedDate as date) as PackedDate
                          from vwPackingListHeaders
                          where (OrderId = @OrderId)
                          for xml raw('PACKINGLISTHEADER'), elements)

      /* Get any one of the LPN of the order
         Assumption is any return label will not have any package details and
         FedEx/UPS only charge for what customer returns */
      select top 1
             @vLPN = LPN
      from LPNs
      where (OrderId = @OrderId) and
            (LPNType in ('C', 'S' /* Carton, ShipCarton */)) and
            (Status  in ('D', 'L', 'S' /* Packed, Loaded, Shipped */))

      /* Returns the top 1 LPN into order packing list header information to print LPN on the order packinglist */
      select @PLHeaderxml = dbo.fn_XMLStuffValue (@PLHeaderxml, 'LPN', @vLPN);
    end
  else
  /* LPNWithODs - Condition to print the LPN with all the Order Details  */
  if (@PackingListType in ('LPN', 'ReturnLPN', 'LPNWithLDs', 'LPNWithODs' /* for return Packing list */))
    begin
      /* Carton / Packing List Header */
      set @PLHeaderxml = (select *
                                 ,@vTotalUnitsAssigned as TotalUnitsAssigned
                                 ,@vOrderTaxAmount     as OrderTaxAmount
                                 ,@vOrderTotal         as OrderTotal
                                 ,@vOrderSubTotal      as OrderSubTotal
                                 ,@vActualWeight       as ActualWeight
                                 ,@vActualVolume       as TotalVolume
                                 ,'LPN'                as PackingListType
                                 ,@vAdditionalPLInfo1  as AdditionalPLInfo1
                                 ,@vWaveType           as WaveType
                                 ,@vWaveNumOrders      as WaveNumOrders
                                 ,@vInsurance          as Insurance
                                 ,@vOtherCharges       as OtherCharges
                                 ,@vPackedDate         as PackedDate
                          from vwLPNPackingListHeaders
                          where (LPNId = @LPNId)
                          for xml raw('PACKINGLISTHEADER'), elements)
    end
  else
  if (@PackingListType = 'Load')
    begin
      /* Carton / Packing List Header */
      set @PLHeaderxml = (select *
                                 ,@vTotalUnitsAssigned as TotalUnitsAssigned
                                 ,@vOrderTaxAmount     as OrderTaxAmount
                                 ,@vOrderTotal         as OrderTotal
                                 ,@vOrderSubTotal      as OrderSubTotal
                                 ,@vActualWeight       as ActualWeight
                                 ,@vActualVolume       as TotalVolume
                                 ,'Load'               as PackingListType
                                 ,@vAdditionalPLInfo1  as AdditionalPLInfo1
                                 ,@vWaveType           as WaveType
                                 ,@vWaveNumOrders      as WaveNumOrders
                                 ,@vInsurance          as Insurance
                                 ,@vOtherCharges       as OtherCharges
                                 ,@vPackedDate         as PackedDate
                          from vwLPNPackingListHeaders
                          where (LoadId = @LoadId)
                          for xml raw('PACKINGLISTHEADER'), elements)
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_GetPackingListHeader */

Go
