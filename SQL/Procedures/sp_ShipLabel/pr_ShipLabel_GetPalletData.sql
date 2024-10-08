/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/09/13  RT/AY   pr_ShipLabel_GetPalletData: Include Pallet Tare Volume (S2GCA-961)
  2019/05/08  AY      pr_ShipLabel_GetPalletData: Fix Cust POs and Pallet SeqNos issue (S2GCA-674)
  2019/05/07  AY      pr_ShipLabel_GetPalletData: Get Load info without depending on BoL being available for Load (S2GCA-674)
  2019/05/06  RT      pr_ShipLabel_GetPalletData: To display LoadNumber, NumPallets and NumCases if the pallet is on the Load (S2GCA-674)
  2019/05/01  YJ      pr_ShipLabel_GetPalletData: Migrated from Prod (S2GCA-98)
  2019/05/01  YJ      pr_ShipLabel_GetPalletData: Migrated from Prod (S2GCA-98)
  2019/03/07  RT      pr_ShipLabel_GetPalletData: Considering EntityType as 'Load' to get special instructions from notes (S2GCA-506)
  2019/02/27  RT/PHK  pr_ShipLabel_GetPalletData: Made changes to get special instructions from notes (S2GMI-88)
                      pr_ShipLabel_GetPalletData: stuff all the CustPOs, that is when the pallet is on multiple orders, Made changes to update the Pallet Seq No (S2GMI-76)
  2018/11/20  AY      pr_ShipLabel_GetPalletData: Change to use ClientLoad instead of Load.UDF1
                      pr_ShipLabel_GetPalletData: Joined with OrderShipments to get ShipmentId info (S2G-727)
  2018/05/05  VM      pr_ShipLabel_GetPalletData: Fixes to return right BoL & Pro numbers and ShipFrom (S2G-686)
  2018/05/02  RV      pr_ShipLabel_GetPalletData: Return data set with Ship From AddressLine2 (S2G-765)
  2018/04/30  VM      pr_ShipLabel_GetPalletData: Fixes (S2G-765)
                      pr_ShipLabel_GetPalletDataXML: Initial version (S2G-750)
  2015/09/07  RV      pr_ShipLabel_GetPalletData: Made more enhancements (OB-391)
  2013/12/15  NY      pr_ShipLabel_GetPalletData: Show TotalVolume,(Rounded upto two decimals).
  2013/10/28  NY      pr_ShipLabel_GetPalletData: Retrieve BoL and Carrier Info and ShipToStore from Pallets.
  2013/10/21  NY      pr_ShipLabel_GetPalletData: Retrieve Date and Picker Info for the pallet
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetPalletData') is not null
  drop Procedure pr_ShipLabel_GetPalletData;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetPalletData:   Need to change this once we get the confirmation
       from client.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetPalletData
  (@Pallet       TPallet       = null,
   @PalletId     TRecordId     = null,
   @BusinessUnit TBusinessUnit = null)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @UserId               TUserId,

          @vShipVia             TShipVia,
          @vShipViaDesc         TDescription,
          @vSCAC                TDescription,
          @vShipFrom            TShipFrom,
          @vVisibleFlags        TFlags,
          @vPrintFlags          TFlags,
          @vNotes               TVarchar,
          /* Order Header Info */
          @vOrderId             TRecordId,
          @vLPNOrderId          TRecordId,
          @vLPNShipToId         TShipToId,
          @vPickTicket          TPickTicket,
          @vCustPO              TCustPO,
          @vCustPOsOnPallet     TVarchar,
          @ttCustPOs            TEntityKeysTable,
          @vSoldToId            TCustomerId,
          @vShipToId            TShipToId,
          @vLPNSoldToId         TCustomerId,
          @vReturnAddress       TReturnAddress,
          @vMarkForAddress      TContactRefId,
          @vOH_UDF1             TUDF,
          @vOH_UDF2             TUDF,
          @vOH_UDF3             TUDF,
          @vOH_UDF4             TUDF,
          @vOH_UDF5             TUDF,
          @vOH_UDF6             TUDF,
          @vOH_UDF7             TUDF,
          @vOH_UDF8             TUDF,
          @vOH_UDF9             TUDF,
          @vOH_UDF10            TUDF,
          @vTotalLPNs           TCount,
          @vLPNOrderCount       TCount,
          @vPickBatchNo         TPickBatchNo,
          /* Order Detail Info */
          @vOrderDetailId       TRecordId,
          @vHostOrderLine       THostOrderLine,
          @vCustSKU             TCustSKU,
          @vOD_UDF1             TUDF,
          @vOD_UDF2             TUDF,
          @vOD_UDF3             TUDF,
          @vOD_UDF4             TUDF,
          @vOD_UDF5             TUDF,
          @vOD_UDF6             TUDF,
          @vOD_UDF7             TUDF,
          @vOD_UDF8             TUDF,
          @vOD_UDF9             TUDF,
          @vOD_UDF10            TUDF,
          /* Ship From */
          @vShipFromName        TName,
          @vShipFromAddr1       TAddressLine,
          @vShipFromAddr2       TAddressLine,
          @vShipFromCity        TCity,
          @vShipFromState       TState,
          @vShipFromZip         TZip,
          @vShipFromCountry     TCountry,
          @vShipFromCSZ         TVarchar,
          @vShipFromPhoneNo     TPhoneNo,

          /* Ship To */
          @vLPNShipToCount      TCount,
          @vShipToName          TName,
          @vShipToAddr1         TAddressLine,
          @vShipToAddr2         TAddressLine,
          @vShipToCity          TCity,
          @vShipToState         TState,
          @vShipToZip           TZip,
          @vShipToCSZ           TVarchar,
          @vShipToCountry       TCountry,
          @vShipToReference2    TDescription,
          /* Mark For */
          @vMarkForName         TName,
          @vMarkForAddr1        TAddressLine,
          @vMarkForAddr2        TAddressLine,
          @vMarkForCity         TCity,
          @vMarkForState        TState,
          @vMarkForZip          TZip,
          @vMarkForCSZ          TVarchar,
          @vMarkForReference2   TDescription,
          /* LPN */
          @vLPNQuantity         TQuantity,
          @vCartonType          TCartonType,
          @vCoO                 TCoO,
          @vPrePackQty          TQuantity,
          @vLPNSeqNo            TInteger,
          @vLPN                 TLPN,
          @vSKUId               TRecordId,
          @vSKU                 TSKU,
          @vLPNSKU              TSKU,
          /* LPN Details */
          @vLPNDetailCount      TCount,
          @vLPNOrderDetailCount TCount,
          @vLD_SKU1Count        TCount,
          @vLD_SKU2Count        TCount,
          @vLD_SKU3Count        TCount,
          @vLD_SKU4Count        TCount,
          @vLD_SKU5Count        TCount,
          @vLD_SKU1             TSKU,
          @vLD_SKU2             TSKU,
          @vLD_SKU3             TSKU,
          @vLD_SKU4             TSKU,
          @vLD_SKU5             TSKU,
          @vLD_SKU1Desc         TDescription,
          @vLD_SKU2Desc         TDescription,
          @vLD_SKU3Desc         TDescription,
          @vLD_SKU4Desc         TDescription,
          @vLD_SKU5Desc         TDescription,
          /* Addresses */
          @vCustomerContactId   TRecordId,
          @vShipToContactId     TRecordId,
          /* Carrier Info */
          @vCarrier             TCarrier,
          @vBoL                 TBol,
          @vLoadId              TRecordId,
          @vClientLoad          TLoadNumber,
          @vLoadNumber          TLoadNumber,
          @vLPNLoadId           TRecordId,
          @vLPNLoadCount        TCount,
          @vProNumber           TProNumber,
          @vLoad_UDF1           TUDF,
          /* Pallet Info */
          @vNumLPNs             TCount,
          @vNumCases            TInnerpacks,
          @vNumPallets          TCount,
          @vPalletSeqNo         TRecordId,
          @vTotalWeight         TWeight,
          @vTotalVolume         TVolume,
          @vTotalUnits          TQuantity,
          @vTotalCases          TInteger,
          @vPalletTareWeight    TWeight,
          @vPalletVolume        TVolume,
          @vPickDate            TDate,
          @vPicker              TUserid,

          /* Pallet UDF's */
          @vPT_UDF1             TUDF  = null,
          @vPT_UDF2             TUDF  = null,
          @vPT_UDF3             TUDF  = null,
          @vPT_UDF4             TUDF  = null,
          @vPT_UDF5             TUDF  = null,
          @vPT_UDF6             TUDF  = null,
          @vPT_UDF7             TUDF  = null,
          @vPT_UDF8             TUDF  = null,
          @vPT_UDF9             TUDF  = null,
          @vPT_UDF10            TUDF  = null;

declare   @ttPalletSeqNo        TEntityKeysTable;

begin
  set NOCOUNT ON;
  select @ReturnCode   = 0,
         @Messagename  = null,
         @UserId       = System_User;

  /* If we do not have PalletId, fetch it */
  if (@PalletId is null)
    select @PalletId = PalletId
    from Pallets
    where (Pallet = @Pallet) and (BusinessUnit = @BusinessUnit);

  if (@PalletId is null)
    set @MessageName = 'PalletDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get the PalletTareWeight and Volume and update accordingly */
  select @vPalletTareWeight = dbo.fn_Controls_GetAsInteger('Shipping', 'PalletTareWeight', '35' /* lbs */,
                                                           @BusinessUnit, null),
         @vPalletVolume     = dbo.fn_Controls_GetAsInteger('Shipping', 'PalletVolume', '7680' /* cu.in. */,
                                                           @BusinessUnit, null);

  /* Get Pallet Info */
  select @vSKUId            = P.SKUId,
         @vPickBatchNo      = P.PickBatchNo,
         @vTotalCases       = P.NumLPNs,
         @vTotalUnits       = P.Quantity,
         @vNumLPNs          = P.NumLPNs,
         @vNumCases         = P.InnerPacks,
         @vLoadId           = P.LoadId,
         @vShipToId         = P.ShipToId,
         @vOrderId          = P.OrderId,
         @vPalletSeqNo      = P.PalletSeqNo,
         @vTotalVolume      = cast(P.Volume as numeric(8,2)) + @vPalletVolume,
         @BusinessUnit      = P.BusinessUnit
  from Pallets P
  where (PalletId = @PalletId);

  /* Calculate the NumCases with respect to the LPNs on the Pallet */
  select @vNumCases = sum(GPI.Cases)
  from LPNs
    cross apply dbo.fn_LPNs_GetPackedInfo(LPNId, 'ShipLabel_GetPalletData' /* Operation */, 'L' /* L - LPN (Option) */) GPI
  where PalletId = @PalletId;

  select @vSKU = SKU
  from SKUs
  where (SKUId = @vSKUId);

  select @vSKU = coalesce('SKU# ' + @vSKU, 'Mixed SKUs')

  /* Get BoL Info */
  select @vBoL        = B.BoLNumber,
         @vProNumber  = B.ProNumber
  from Loads L
    join Shipments       S on (S.LoadId     = L.LoadId)
    join BoLs            B on (S.BoLId      = B.BoLId)
    join OrderShipments OS on (S.ShipmentId = OS.ShipmentId)
  where (L.LoadId = @vLoadId) and (OS.OrderId = @vOrderId);

  /* Get Load Info */
  select @vLoad_UDF1  = L.UDF1,
         @vClientLoad = L.ClientLoad,
         @vLoadNumber = L.LoadNumber,
         @vNumPallets = L.NumPallets
  from Loads L
  where (L.LoadId = @vLoadId);

  if ((@vNumPallets = 0) or (@vNumPallets is null))
    select @vNumPallets = Count(*)
    from Pallets
    where LoadId = @vLoadId;

  /* Get the special instructions from Notes */
  exec pr_Notes_GetNotesForEntity @vLoadId, @vLoadNumber, 'Load' /* Entity */, 'SI' /* Note Type */, @vVisibleFlags,
                                 @vPrintFlags, @BusinessUnit, @UserId, @vNotes output;

  /* Get all the CustPOs, that is when the pallet is on multiple orders, then we get all the CustPOs
     to print on Pallet Tag */
  insert into @ttCustPOs (EntityKey)
    select distinct OH.CustPO
    from Pallets P
      left outer join LPNs L on (L.PalletId = P.PalletId)
      left outer join OrderHeaders OH on (OH.OrderId = L.OrderId)
    where (P.PalletId = @PalletId) and
          (coalesce(OH.CustPO, '') <> '');

  select @vCustPOsOnPallet = dbo.fn_ConvertEntityKeysToCSV(@ttCustPOs);

  select @vPalletSeqNo = 0;

  if ((nullif(coalesce(@vPalletSeqNo, ''), 0)) is null)
    exec pr_Pallets_PalletNoResequence @vLoadId, @PalletId;

  /* Get the Pallet Seq No */
  select @vPalletSeqNo = PalletSeqNo
  from Pallets
  where (PalletId = @PalletId);

  /* If all LPNs on the Pallet are of one Order/ShipTo/Load, then figure out what they are */
  if (@vOrderId is null) or (@vShipToId is null) or (nullif(@vLoadId, 0) is null)
    begin
      select @vLPNOrderCount  = count(distinct L.OrderId),
             @vLPNOrderId     = min(L.OrderId),
             @vLPNShipToCount = count(distinct OH.ShipToId),
             @vLPNShipToId    = min (OH.ShipToId),
             @vLPNLoadCount   = count(distinct L.LoadId),
             @vLPNLoadId      = min(L.LoadId),
             --@vShipFrom       = min(ShipFrom),  -- all LPNs on the pallet are assumed to be from same ShipFrom
             @vLPNSoldToId    = min(SoldToId)
      from LPNs L join OrderHeaders OH on (L.OrderId = OH.OrderId)
      where (L.PalletId = @PalletId);

      if (@vLPNOrderCount  = 1) select @vOrderId  = @vLPNOrderId;
      if (@vLPNShipToCount = 1) select @vShipToId = @vLPNShipToId, @vSoldToId = @vLPNSoldToId;
      if (@vLPNLoadCount   = 1) select @vLoadId   = @vLPNLoadId;
    end

  /* get Order info here */
  select @vPickTicket     = PickTicket,
         @vShipFrom       = ShipFrom,
         @vSoldToId       = SoldToId,
         @vShipToId       = ShipToId,
         @vReturnAddress  = ReturnAddress,
         @vMarkForAddress = MarkForAddress,
         @vShipVia        = ShipVia,
         @vCustPO         = CustPO,
         @vTotalLPNs      = LPNsAssigned,
         @vOH_UDF1        = UDF1,
         @vOH_UDF2        = UDF2,
         @vOH_UDF3        = UDF3,
         @vOH_UDF4        = UDF4,
         @vOH_UDF5        = UDF5,
         @vOH_UDF6        = UDF6,
         @vOH_UDF7        = UDF7,
         @vOH_UDF8        = UDF8,
         @vOH_UDF9        = UDF9,
         @vOH_UDF10       = UDF10
  from OrderHeaders
  where (OrderId = @vOrderId);

  select @vCarrier     = Carrier,
         @vSCAC        = ShipVia,
         @vShipViaDesc = Description,
         @vCarrier     = Carrier
  from ShipVias
  where (ShipVia = @vShipVia);

  /* Get Pallet counts */
  select  @vTotalWeight = sum(coalesce(L.EstimatedWeight, 0)) + @vPalletTareWeight,
          @vTotalCases  = sum(case when S.UnitsPerInnerPack > 0 then L.Quantity/S.UnitsPerInnerPack else 1 end)
  from LPNs  L
      join SKUs       S  on (L.SKUId   = S.SKUId)
  where (L.PalletId = @PalletId);

   /* Get ShipFrom Details */
  select @vShipFromName     = SF.Name,
         @vShipFromAddr1    = SF.AddressLine1,
         @vShipFromAddr2    = SF.AddressLine2,
         @vShipFromCity     = SF.City,
         @vShipFromState    = SF.State,
         @vShipFromZip      = SF.Zip,
         @vShipFromCountry  = SF.Country,
         @vShipFromCSZ      = SF.CityStateZip,
         @vShipFromPhoneNo  = SF.PhoneNo
  from vwContacts SF
  where (SF.ContactRefId = @vShipFrom) and (SF.ContactType = 'F' /* Ship From */);

  /* Get ShipTo Details */
  select @vShipToName       = SHTA.Name,
         @vShipToAddr1      = SHTA.AddressLine1,
         @vShipToAddr2      = SHTA.AddressLine2,
         @vShipToCity       = SHTA.City,
         @vShipToState      = SHTA.State,
         @vShipToZip        = SHTA.Zip,
         @vShipToCSZ        = SHTA.CityStateZip,
         @vShipToCountry    = SHTA.Country
  from dbo.fn_Contacts_GetShipToAddress(null /* Order Id */, @vShipToId) SHTA

  /* Get MarkFor Details */
  select @vMarkForName       = MFA.Name,
         @vMarkForAddr1      = MFA.AddressLine1,
         @vMarkForAddr2      = MFA.AddressLine2,
         @vMarkForCity       = MFA.City,
         @vMarkForState      = MFA.State,
         @vMarkForZip        = MFA.Zip,
         @vMarkForCSZ        = MFA.CityStateZip,
         @vMarkForReference2 = MFA.Reference2
  from vwContacts MFA
  where (MFA.ContactRefId = @vMarkForAddress) and (MFA.ContactType in ('S' /* Ship To */, 'M' /* Mark For */));

  /* Return all the info collected */
  select @vShipFromName         as ShipFromName,
         @vShipFromAddr1        as ShipFromAddress1,
         @vShipFromAddr2        as ShipFromAddress2,
         @vShipFromCity         as ShipFromCity,
         @vShipFromState        as ShipFromState,
         @vShipFromZip          as ShipFromZip,
         @vShipFromCountry      as ShipFromCountry,
         @vShipFromCSZ          as ShipFromCSZ,
         @vShipFromPhoneNo      as ShipFromPhoneNo,

         /* Mark for information */
         @vMarkForName          as MarkforName,
         @vMarkForReference2    as MarkforStore,
         @vMarkForAddr1         as MarkforAddress1,
         @vMarkForAddr2         as MarkforAddress2,
         @vMarkForCity          as MarkforCity,
         @vMarkForState         as MarkforState,
         @vMarkForZip           as MarkforZip,
         @vMarkForCSZ           as MarkforCSZ,
         /* ShipTo information. */
         @vShipToName           as ShipToName,
         @vShipToReference2     as ShipToStore,
         @vShipToAddr1          as ShipToAddress1,
         @vShipToAddr2          as ShipToAddress2,
         @vShipToCity           as ShipToCity,
         @vShipToState          as ShipToState,
         @vShipToZip            as ShipToZip,
         @vShipToCountry        as ShipToCountry,
         @vShipToCSZ            as ShipToCSZ,
         /* Shipping Info */
         @vShipVia              as ShipVia,
         @vShipViaDesc          as ShipViaDesc,

         /* Order header Info */
         @vPickTicket           as PickTicket,
         @vCustPO               as CustPO,
         @vCustPOsOnPallet      as CustPOsOnPallet,
         @vOH_UDF1              as OH_UDF1,
         @vOH_UDF2              as OH_UDF2,
         @vOH_UDF3              as OH_UDF3,
         'Vendor Id'            as VendorId,
         /* Order Detail Info */
         @vHostOrderLine        as HostOrderLine,
         @vSKU                  as SKU,
         @vCustSKU              as CustomerItem,

         /* Load Info */
         @vCarrier              as Carrier,
         @vBoL                  as BoL,
         @vLoadNumber           as LoadNumber,
         @vClientLoad           as ClientLoad,
         @vProNumber            as ProNumber,
         @vLoad_UDF1            as LD_UDF1, -- for backward compatibility

         /* Pallet Info */
         @Pallet                as Pallet,
         @vNumLPNs              as NumLPNs,
         @vNumCases             as NumCases,
         @vNumPallets           as NumPallets,
         @vPalletSeqNo          as PalletSeqNo,
         @vTotalCases           as TotalCases,
         @vTotalUnits           as TotalUnits,
         @vTotalWeight          as TotalWeight,
         @vTotalVolume          as TotalVolume,
         @vNotes                as SpecialInstructions,

         /* UDFs */
         @vPT_UDF1              as PT_UDF1,
         @vPT_UDF2              as PT_UDF2,
         @vPT_UDF3              as PT_UDF3,
         @vPT_UDF4              as PT_UDF4,
         @vPT_UDF5              as PT_UDF5,
         @vPT_UDF6              as PT_UDF6,
         @vPT_UDF7              as PT_UDF7,
         @vPT_UDF8              as PT_UDF8,
         @vPT_UDF9              as PT_UDF9,
         @vPT_UDF10             as PT_UDF10;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_ShipLabel_GetPalletData */

Go
