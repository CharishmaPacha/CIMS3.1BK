/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/04  MS      pr_ShipLabel_GetLPNData: Changes to print WaveSeqNo (BK-344)
  2021/04/21  PK/YJ   pr_ShipLabel_GetLPNData: ported changes from prod onsite (HA-2678)
  2021/04/14  MS      pr_ShipLabel_GetLPNData: Changes to format LPNWeight (BK-290)
  2021/03/26  RV      pr_ShipLabel_GetLPNData: Ported changes done by Ramana (HA-2452)
  2021/03/24  AY      pr_ShipLabel_GetLPNData: Return IP spread to print on labels (HA GoLive)
  2021/03/24  AY      pr_ShipLabel_GetLPNData: Get the first order detail for multi line carton (HA Golive)
  2020/10/21  PK      pr_ShipLabel_GetLPNData: Included OD_UDF11..OD_UDF30 - Port back from HA Prod/Stag by VM (HA-1483)
  2020/09/29  RV      pr_ContentLabel_GetPrintDataStream, pr_ShipLabel_GetLPNData: Added markers (HA-1476)
  2020/07/07  VM      pr_ShipLabel_GetLPNData: Return LPNNumLines, LPNNumSKUs, LPNNumSizes as well - WIP (HA-1072)
  2020/07/01  VM      pr_ShipLabel_GetLPNData: Return SizeList as well (HA-1037)
  2020/06/30  VM/AY   pr_ShipLabel_GetLPNData: Get and return SCC_Barcode as well (HA-1037)
  2020/06/26  VM      pr_ShipLabel_GetLPNData: Add OH_UDF11..OH_UDF30 (HA-1037)
  2020/06/25  VM      pr_ShipLabel_GetLPNData: Bug-fix and return SKUSizeScale and SKUSizeSpread as well (HA-1013)
  2020/06/24  VM      pr_ShipLabel_GetLPNDataAndContents: Cannot use nested insert exec, so handled it (HA-1013)
                      pr_ShipLabel_GetLPNData: Changed to return data set or insert into #table (HA-1013)
  2020/06/23  AY      pr_ShipLabel_GetLPNDataAndContents: Bug fixes (HA-1013)
  2020/06/04  AY      pr_ShipLabel_GetLPNData: Bug fix to pass in right BU to get CartonTypdesc (HA-660)
                      pr_ShipLabel_GetLPNData: Made changes to do not return label image as we do not get image data conversion issues while converting to xml (HA-667)
  2020/05/13  AY      pr_ShipLabel_GetLPNData: Corrected to be in sync with TLPNShipLabelData (HA-410)
  2019/05/23  MS      pr_ShipLabel_GetLPNData : Changes to consider Estimated Weight when ActualWeight is 0 (CID-420)
  2019/06/04  KSK     pr_ShipLabel_GetLPNData: Made changes to Reorder the Package Seq No (CID-505)
  2019/04/03  MS      pr_ShipLabel_GetLPNDataAndContents: Made changes get details from procedure (CID-221)
  2019/03/26  MJ      pr_ShipLabel_GetLPNData: Made changes to return AlternateLPN (CID-209)
  2018/06/05  YJ      pr_ShipLabel_GetLPNData: Added changes to retrieve ProNumber
              MJ      pr_ShipLabel_GetLPNData: Added more fields as per the requirement (S2G-803)
  2018/04/05  MJ      pr_ShipLabel_GetLPNData: Return MarkForAddress as well as Sears ShipLabel requires it (SRI-862)
  2016/10/18  PSK     pr_ShipLabel_GetLPNData: Changes to get the Ordercategory1 (HPI-873)
  2016/09/13  PSK     pr_ShipLabel_GetLPNData:
  2016/07/05  TK      pr_ShipLabel_GetLPNDataAndContents: We don't need all the fields returned from Shippig GetLPNData, SKU1 - SKU5 needs to be considered which is returned from Function
  2016/06/28  DK      Added new procedure pr_ShipLabel_GetLPNDataAndContentsXML
  2016/06/25  AY      pr_ShipLabel_GetLPNData: Return LPN.Lot
  2016/06/23  TK      pr_ShipLabel_GetLPNDataAndContents: Changed input xml structure (HPI-176)
  2016/06/17  DK      pr_ShipLabel_GetLPNDataAndContents: Added  additional XML input parameter
                      pr_ShipLabel_GetLPNData: Made changes to return Account informataion as well (HPI-169)
  2016/04/01  VM      pr_ShipLabel_GetLPNData: Get TaskId from LPN.TaskId as we have introduced this field instead of UDF (NBD-291)
  2016/02/23  DK      pr_ShipLabel_GetLPNData: Made changes to print VICSBoLNumber instead of BoLNumber on Labels (FB-644).
  2015/11/24  TK      pr_ShipLabel_GetLPNData: Changed RuleSet Name(ACME-417.3)
  2015/11/24  KN      pr_ShipLabel_GetLPNDataXML: Added  additional input parameters to fix label printing issue (Ship_4x7_1516).
  2015/10/26  AY      pr_ShipLabel_GetLPNDataAndContents: New procedure to print Shipping and contents combo label.
                      pr_ShipLabel_GetLPNData: Reverted to only be used for shipping label.
  2015/10/08  TK      pr_ShipLabel_GetLPNData: Changes made to return DEPT and PO (ACME-324)
  2015/10/07  TK      pr_ShipLabel_GetLPNData: Return CartonType and CartonType Desc (ACME-352)
  2015/10/06  AY      pr_ShipLabel_GetLPNData: By default if no LabelFormat is specified then assume it does not have
  2015/09/21  AY      pr_ShipLabel_GetLPNData: Changed to update LPN.PrintFlags
  2015/08/13  SV      pr_ShipLabel_GetLPNData: Made changes required for Ship&ContentLabels (ACME-290)
  2015/02/06  PKS     pr_ShipLabel_GetLPNData: Added Warehouse
  2015/01/20  PKS     pr_ShipLabel_GetLPNData: SKU Description is set to mutiple SKUs if LPN has mutiple details.
  2015/01/16  TK      pr_ShipLabel_GetLPNData: Enhanced to return TaskId in the dataset
  2014/09/08  AY      pr_ShipLabel_GetLPNData: Added input param Operation to be able to return based upon context.
  2014/07/30  PKS     pr_ShipLabel_GetLPNData: Added Location Row, Level and Section.
  2014/07/24  PKS     pr_ShipLabel_GetLPNData: Added Current time stamp, PickZone and PickedBy. Mapped ShipToStore column with OH.ShipToStore
  2014/05/27  PKS     pr_ShipLabel_GetLPNData: Added SKUDescription, PickBatchNo, RetailUnitPrice and LPN.ReferenceLocation.
  2012/10/08  AY      pr_ShipLabel_GetLPNData: ShipToStore is Reference2 of ShipToId not Reference1
  2012/10/04  VM      pr_ShipLabel_GetLPNData: Show color description from SKU_UDF7
  2012/09/29  AY      pr_ShipLabel_GetLPNData: Return OD_UDF6 to be printed on WM label for LineNo,
  2012/08/28  AY      pr_ShipLabel_GetLPNData: Return LPN to print on Shipping label
  2012/07/11  PKS     pr_ShipLabel_GetLPNData: vUCCCheckDigit,vUCCSeqNo fetch from LPNs.UCCBarcode,
  2012/07/02  AY      pr_ShipLabel_GetLPNData: WIP
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLPNData') is not null
  drop Procedure pr_ShipLabel_GetLPNData;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLPNData: Returns the data set to be used to print a UCC Label.

  This procedure is called from Bartender labels.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLPNData
  (@LPN              TLPN          = null,
   @LPNId            TRecordId     = null,
   @Operation        TOperation    = null,
   @BusinessUnit     TBusinessUnit = null,
   @LabelFormatName  TName         = null,
   @ReturnDataSet    TFlags        = 'Y')
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @UserId               TUserId,
          @vDebug               TControlValue = 'N',

          @vShipVia             TShipVia,
          @vShipViaDesc         TDescription,
          @vSCAC                TDescription,
          @vShipFrom            TShipFrom,
          /* Wave Info */
          @vWaveId              TRecordId,
          @vWaveNo              TWaveNo,
          @vWaveType            TTypeCode,
          @vWaveNumOrders       TInteger,
          /* Order Header Info */
          @vOrderId             TRecordId,
          @vPickTicket          TPickTicket,
          @vSalesOrder          TSalesOrder,
          @vCustPO              TCustPO,
          @vAccount             TCustomerId,
          @vAccountName         TName,
          @vPickZone            TZoneId,
          @vSoldToId            TCustomerId,
          @vShipToId            TShipToId,
          @vReturnAddress       TReturnAddress,
          @vShipToStore         TShipToStore,
          @vShippedDate         TDateTime,
          @vWaveSeqNo           TInteger,
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
          @vOH_UDF11            TUDF,
          @vOH_UDF12            TUDF,
          @vOH_UDF13            TUDF,
          @vOH_UDF14            TUDF,
          @vOH_UDF15            TUDF,
          @vOH_UDF16            TUDF,
          @vOH_UDF17            TUDF,
          @vOH_UDF18            TUDF,
          @vOH_UDF19            TUDF,
          @vOH_UDF20            TUDF,
          @vOH_UDF21            TUDF,
          @vOH_UDF22            TUDF,
          @vOH_UDF23            TUDF,
          @vOH_UDF24            TUDF,
          @vOH_UDF25            TUDF,
          @vOH_UDF26            TUDF,
          @vOH_UDF27            TUDF,
          @vOH_UDF28            TUDF,
          @vOH_UDF29            TUDF,
          @vOH_UDF30            TUDF,
          @vTotalLPNs           TCount,
          @vOrderCategory1      TOrderCategory,
          /* Order Detail Info */
          @vOrderDetailId       TRecordId,
          @vHostOrderLine       THostOrderLine,
          @vRetailUnitPrice     TRetailUnitPrice,
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
          @vOD_UDF11            TUDF,
          @vOD_UDF12            TUDF,
          @vOD_UDF13            TUDF,
          @vOD_UDF14            TUDF,
          @vOD_UDF15            TUDF,
          @vOD_UDF16            TUDF,
          @vOD_UDF17            TUDF,
          @vOD_UDF18            TUDF,
          @vOD_UDF19            TUDF,
          @vOD_UDF20            TUDF,
          @vOD_UDF21            TUDF,
          @vOD_UDF22            TUDF,
          @vOD_UDF23            TUDF,
          @vOD_UDF24            TUDF,
          @vOD_UDF25            TUDF,
          @vOD_UDF26            TUDF,
          @vOD_UDF27            TUDF,
          @vOD_UDF28            TUDF,
          @vOD_UDF29            TUDF,
          @vOD_UDF30            TUDF,
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
          @vShipToName          TName,
          @vShipToAddr1         TAddressLine,
          @vShipToAddr2         TAddressLine,
          @vShipToCity          TCity,
          @vShipToState         TState,
          @vShipToZip           TZip,
          @vShipToCSZ           TVarchar,
          @vShipToReference1    TDescription,
          @vShipToReference2    TDescription,
          /* Sold To */
          @vSoldToName          TName,
          @vSoldToAddr1         TAddressLine,
          @vSoldToAddr2         TAddressLine,
          @vSoldToCity          TCity,
          @vSoldToState         TState,
          @vSoldToZip           TZip,
          @vSoldToCSZ           TVarchar,
          @vSoldToEmail         TEmailAddress,
          /* Mark For */
          @vMarkForAddress      TContactRefId,
          @vMarkForName         TName,
          @vMarkForAddr1        TAddressLine,
          @vMarkForAddr2        TAddressLine,
          @vMarkForCity         TCity,
          @vMarkForState        TState,
          @vMarkForZip          TZip,
          @vMarkForCSZ          TVarchar,
          @vMarkForReference1   TDescription,
          @vMarkForReference2   TDescription,
          /* SSCC Barcode */
          @vSSCC_Barcode        TBarcode,
          @vSCC_Barcode         TBarcode,
          @vSSCC_PackageCode    TFlag,
          @vSSCC_CompanyId      TBarcode,
          @vSSCC_SeqNo          TBarcode,
          @vSSCC_CheckDigit     TFlag,
          @vTrackingNo          TTrackingNo,
          /* LPN */
          @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vLPNInnerPacks       TInnerPacks,
          @vLPNQuantity         TQuantity,
          @vCartonType          TCartonType,
          @vCartonTypeDesc      TDescription,
          @vCoO                 TCoO,
          @vPickedBy            TUserId,
          @vPrePackQty          TQuantity,
          @vLPNSeqNo            TInteger,
          @vLPNSKU              TSKU,
          @vLPNLot              TLot,
          @vAlternateLPN        TLPN,
          @vEstimatedWeight     TWeight,
          @vActualWeight        TWeight,
          @vLPNWeight           TWeight,
          @vLPNNumLines         TCount,
          @vLPNNumSKUs          TCount,
          @vLPNNumSizes         TCount,
          /* LPN Details */
          @vLPNDetailCount      TCount,
          @vLPNOrderDetailCount TCount,
          @vUnitsPerPackage     TInteger,
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
          @vSizeScale           TSizeScale,
          @vSizeSpread          TSizeSpread,
          @vIPSpread            TSizeSpread,
          @Sizes                TSizeList,
          /* Location Info */
          @vPickLocation        TLocation,
          @vPickLocationRow     TRow,
          @vPickLocationLevel   TLevel,
          @vPickLocationSection TSection,
          /* Addresses */
          @vCustomerContactId   TRecordId,
          @vShipToContactId     TRecordId,
          /* Carrier Info */
          @vCarrier             TCarrier,
          @vVICSBoLNumber       TVICSBoLNumber,
          /* SKU */
          @vSKUId               TRecordId,
          @vSKU                 TSKU,
          @vSKUDescription      TDescription,
          @vUPC                 TUPC,
          @vSKUUoM              TUoM,
          /* Tasks */
          @vTaskId              TRecordId,
          @vTaskDetailId        TRecordId,
          @vCasesToPick         TCount,
          /* Loads */
          @vLoadId              TRecordId,
          @vLoadNumber          TLoadNumber,
          @vClientLoad          TLoadNumber,
          @vShipmentId          TShipmentId,
          @vProNumber           TProNumber,
          @vDesiredShipDate     TDateTime,
          @vWarehouse           TWarehouse,
          @vCurrentDate         TDateTime = current_timestamp,
          /* Label Info */
          @vPrintOptionsXml     xml,
          @xmlData              TXML,
          @vLabelType           TEntity,
          @vGetAdditionalInfo   TFlag,
          @vAdditionalInfo      varchar(max),
          @vPrintFlags          TPrintFlags,
          @vContentsInfo        TFlag,
          @vContentLinesPerLabel
                                TCount,
          @vMaxLabelsToPrint    TCount,
          @vShipNotifications   TVarChar,
          @vNoOfPrepacks        bigint;

  declare @ttLPNShipLabelData   TLPNShipLabelData,
          @ttMarkers            TMarkers

begin
  set NOCOUNT ON;
  select @ReturnCode   = 0,
         @Messagename  = null,
         @UserId       = System_User;

  /* Create required hash tables if they does not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  if object_id('tempdb..#LPNShipLabelData') is null
    select * into #LPNShipLabelData from @ttLPNShipLabelData;

  /* If we do not have LPNId, fetch it */
  if (@LPNId is null)
    select @LPNId = LPNId
    from LPNs
    where (LPN = @LPN) and (BusinessUnit = @BusinessUnit);

  if (@LPNId is null)
    set @MessageName = 'LPNDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  select @vPrintOptionsXml = PrintOptions,
         @vLabelType       = EntityType
  from LabelFormats
  where (LabelFormatName = @LabelFormatName) and (BusinessUnit = @BusinessUnit);

  select @vContentsInfo         = Record.Col.value('ContentsInfo[1]',   'TFlag'),
         @vContentLinesPerLabel = Record.Col.value('ContentsLinesPerLabel[1]', 'TCount'),
         @vMaxLabelsToPrint     = Record.Col.value('MaxLabelsToPrint[1]', 'TCount'),
         @vGetAdditionalInfo    = Record.Col.value('GetAdditionalInfo[1]', 'TFlag')
  from @vPrintOptionsXml.nodes('printoptions') as Record(Col);

  select @vOrderId         = L.OrderId,
         @vCartonType      = L.CartonType,
         @vCartonTypeDesc  = CT.Description,
         @vEstimatedWeight = L.EstimatedWeight,
         @vActualWeight    = L.ActualWeight,
         @vTrackingNo      = L.TrackingNo,
         @vSSCC_Barcode    = L.UCCBarcode,
         @vLPNInnerPacks   = L.InnerPacks,
         @vLPNQuantity     = L.Quantity,
         @vLPNSeqNo        = L.PackageSeqNo,
         @vSKUId           = L.SKUId,
         @vLPN             = L.LPN,
         @vLPNNumLines     = L.NumLines,
         @vLoadId          = L.LoadId,
         @vShipmentId      = L.ShipmentId,
         @vWaveId          = L.PickBatchId,
         @vTaskId          = L.TaskId,         --We are updating TaskId to UDF2 field while creating PickTasks
         @BusinessUnit     = L.BusinessUnit,
         @vLPNLot          = L.Lot,
         @vAlternateLPN    = L.AlternateLPN,
         @vLPNWeight       = coalesce(nullif(ActualWeight, 0), EstimatedWeight)
  from LPNs L
    left outer join CartonTypes CT on (L.CartonType = CT.CartonType) and (CT.BusinessUnit = L.BusinessUnit)
  where (L.LPNId = @LPNId);

  /* Reorder the Package Seq No */
  exec pr_LPNs_PackageNoResequence @vOrderId, @LPNId;

  /* Fetching SKU Info - if Multi SKU LPN then we skip it */
  if (@vSKUId is not null)
    select @vSKU            = SKU,
           @vSKUDescription = Description,
           @vUPC            = UPC,
           @vSKUUoM         = UoM
    from SKUs
    where (SKUId = @vSKUId);

  /* First digit of SCC is 0 for multi-SKU carton, 1 for single SKU carton */
  select @vSCC_Barcode = case when @vLPNNumLines > 1 then '0' else '1' end + @vUPC;
  select @vSCC_Barcode += dbo.fn_GetMod10CheckDigit('0' + @vSCC_Barcode);

  /* Fetching PrePackQty if SKU is a Prepack */
  if (@vSKUId is not null) and (@vSKUUoM = 'PP')
    select @vPrePackQty = sum(ComponentQty)
    from SKUPrePacks
    where (MasterSKUId = @vSKUId);

  /* Get the order detail this LPN is associated with - this assumes
     that the LPN does not have multiple SKUs */
  select @vLPNDetailCount      = count(*),
         @vUnitsPerPackage     = Min(UnitsPerPackage),
         @vOrderDetailId       = Min(LD.OrderDetailId),
         @vLPNOrderDetailCount = count(distinct LD.OrderDetailId),
         @vLPNNumSKUs          = count(distinct S.SKU),
         @vLD_SKU1Count        = count(distinct S.SKU1),
         @vLD_SKU2Count        = count(distinct S.SKU2),
         @vLD_SKU3Count        = count(distinct S.SKU3),
         @vLD_SKU4Count        = count(distinct S.SKU4),
         @vLD_SKU5Count        = count(distinct S.SKU5),
          /* VM: When LPN has multiple SKUs, LPN NumSizes should be distinct by SKU1+SKU3 as multiple SKUs can have same size */
         @vLPNNumSizes         = count(distinct S.SKU1+S.SKU3),
         @vLD_SKU1             = Min(S.SKU1),
         @vLD_SKU2             = Min(S.SKU2),
         @vLD_SKU3             = Min(S.SKU3),
         @vLD_SKU4             = Min(S.SKU4),
         @vLD_SKU5             = Min(S.SKU5),
         @vLD_SKU1Desc         = Min(S.SKU1Description),
         @vLD_SKU2Desc         = Min(S.SKU2Description),
         @vLD_SKU3Desc         = Min(S.SKU3Description),
         @vLD_SKU4Desc         = Min(S.SKU4Description),
         @vLD_SKU5Desc         = Min(S.SKU5Description),
         @vCoO                 = Min(LD.CoO),
         @vPickedBy            = Min(LD.PickedBy)
  from LPNDetails LD join SKUs S on LD.SKUId = S.SKUId
  where (LPNId = @LPNId);

  if (@vLPNOrderDetailCount > 1)
    select top 1 @vOrderDetailId = OD.OrderDetailId
    from LPNDetails LD join OrderDetails OD on LD.OrderDetailId = OD.OrderDetailId
    where (LD.LPNId = @LPNId)
    order by OD.SortOrder;

  /* If any of the SKU1..5 are not unique in the LPN, clear them so we do not
     print anything on the label. if all Details are of same SKU1 (style), but
     not same SKU2 (size), then we would want to print nothing for SKU2 */
  if (@vLD_SKU1Count > 1) select @vLD_SKU1 = 'Mixed', @vLD_SKU1Desc = null;
  if (@vLD_SKU2Count > 1) select @vLD_SKU2 = 'Mixed', @vLD_SKU2Desc = null;
  if (@vLD_SKU3Count > 1) select @vLD_SKU3 = 'Mixed', @vLD_SKU3Desc = null;
  if (@vLD_SKU4Count > 1) select @vLD_SKU4 = 'Mixed', @vLD_SKU4Desc = null;
  if (@vLD_SKU5Count > 1) select @vLD_SKU5 = 'Mixed', @vLD_SKU5Desc = null;

  if (@vLPNDetailCount > 1) select @vUnitsPerPackage = null;

  /* Prepare Size List */
  select * into #SizeList from @Sizes;

  insert into #SizeList (SKUId, Count1, Count2)
    select LD.SKUId, LD.Quantity, OD.UnitsPerInnerPack
    from LPNDetails LD join OrderDetails OD on LD.OrderDetailId = OD.OrderDetailId
    where (LD.LPNId = @LPNId);

  /* No of Prepacks */
  select @vNoOfPrepacks = case when sum(count2) > 0 then sum(Count1)/sum(Count2) else 0 end from #SizeList;

  /* Get the Size Scale & Spread */
  exec pr_SKUs_GetSizeSpread @SizeScale = @vSizeScale out, @Count1Spread = @vSizeSpread out, @Count2Spread = @vIPSpread out;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'SKUs_GetSizeSpread_', @@ProcId;

  if (@vGetAdditionalInfo = 'Y' /* Yes */)
    begin
      select @xmlData = dbo.fn_XMLNode('RootNode', dbo.fn_XMLNode('LPNId', cast(@LPNId as varchar)));

      /* Get additional Packing List info */
      exec pr_RuleSets_Evaluate 'ShipLabel_Info', @xmlData, @vAdditionalInfo output;

      set @vAdditionalInfo = replace(@vAdditionalInfo, '|', (char(13) + char(10)))
    end

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetAdditionalInfo', @@ProcId;

  /* Fetching WaveNo from Waves table */
  if (@vWaveId is not null)
    select @vWaveNo   = WaveNo,
           @vWaveType      = WaveType,
           @vWaveNumOrders = NumOrders
    from Waves
    where (RecordId = @vWaveId);

  /* If printing batch labels, then get the task info */
  if (@Operation = 'PrintBatchLabel')
    begin
      select @vTaskId       = TaskId,
             @vTaskDetailId = TaskDetailId
      from vwLPNTasks
      where (LPNId = @LPNId);

      select @vCasesToPick = TotalInnerPacks
      from Tasks
      where (TaskId = @vTaskId);
    end

  /* If we are printing Batch labels, then determine where the LPN is being picked from */
  if (@Operation = 'PrintBatchLabel')
    begin
      select @vPickLocation = Location
      from vwTaskDetails
      where (TaskDetailId = @vTaskDetailId);
    end
  else
  /* If it is a single SKU LPN, then get the pick location of the SKU */
  if (@vSKUId is not null)
    begin
      select Top 1 @vPickLocation = Location
      from LPNs
      where (SKUId   = @vSKUId) and
            (LPNType = 'L' /* Logical */) and
            (Status  <> 'I' /* Inactive */);
    end

  if (@vPickLocation is not null)
    select @vPickLocationRow     = LocationRow,
           @vPickLocationLevel   = LocationLevel,
           @vPickLocationSection = LocationSection
    from Locations
    where (Location = @vPickLocation) and (BusinessUnit = @BusinessUnit);

  select @vPickTicket     = PickTicket,
         @vSalesOrder     = SalesOrder,
         @vSoldToId       = SoldToId,
         @vShipToId       = ShipToId,
         @vReturnAddress  = ReturnAddress,
         @vMarkForAddress = MarkForAddress,
         @vShipToStore    = ShipToStore,
         @vShipVia        = ShipVia,
         @vShipFrom       = ShipFrom,
         @vCustPO         = CustPO,
         @vAccount        = Account,
         @vAccountName    = AccountName,
         @vPickZone       = PickZone,
         @vTotalLPNs      = LPNsAssigned,
         @vShippedDate    = ShippedDate,
         @vWaveSeqNo      = WaveSeqNo,
         @vOH_UDF1        = UDF1,
         @vOH_UDF2        = UDF2,
         @vOH_UDF3        = UDF3,
         @vOH_UDF4        = UDF4,
         @vOH_UDF5        = UDF5,
         @vOH_UDF6        = UDF6,
         @vOH_UDF7        = UDF7,
         @vOH_UDF8        = UDF8,
         @vOH_UDF9        = UDF9,
         @vOH_UDF10       = UDF10,
         @vOH_UDF11       = UDF11,
         @vOH_UDF12       = UDF12,
         @vOH_UDF13       = UDF13,
         @vOH_UDF14       = UDF14,
         @vOH_UDF15       = UDF15,
         @vOH_UDF16       = UDF16,
         @vOH_UDF17       = UDF17,
         @vOH_UDF18       = UDF18,
         @vOH_UDF19       = UDF19,
         @vOH_UDF20       = UDF20,
         @vOH_UDF21       = UDF21,
         @vOH_UDF22       = UDF22,
         @vOH_UDF23       = UDF23,
         @vOH_UDF24       = UDF24,
         @vOH_UDF25       = UDF25,
         @vOH_UDF26       = UDF26,
         @vOH_UDF27       = UDF27,
         @vOH_UDF28       = UDF28,
         @vOH_UDF29       = UDF29,
         @vOH_UDF30       = UDF30,
         @vWarehouse      = Warehouse
  from OrderHeaders
  where (OrderId = @vOrderId);

  if ((@vLoadId is not null) and
      (exists (select LoadId
               from Loads
               where (LoadId = @vLoadId))))
    begin
      select @vShipvia         = ShipVia,
             @vProNumber       = ProNumber,
             @vDesiredShipDate = DesiredShipDate
      from Loads
      where (LoadId = @vLoadId);

      /* Get BoL Info */
      select @vLoadNumber    = L.LoadNumber,
             @vClientLoad    = L.ClientLoad,
             @vVICSBoLNumber = B.VICSBoLNumber,
             @vProNumber     = coalesce(@vProNumber, B.ProNumber)
      from Loads L
        join Shipments       S on (S.LoadId     = L.LoadId)
        join BoLs            B on (S.BoLId      = B.BoLId)
        join OrderShipments OS on (S.ShipmentId = OS.ShipmentId)
      where (L.LoadId = @vLoadId) and (OS.OrderId = @vOrderId);
    end

  select @vHostOrderLine   = HostOrderLine,
         @vCustSKU         = CustSKU,
         @vRetailUnitPrice = RetailUnitPrice,
         @vOD_UDF1         = UDF1,
         @vOD_UDF2         = UDF2,
         @vOD_UDF3         = UDF3,
         @vOD_UDF4         = UDF4,
         @vOD_UDF5         = UDF5,
         @vOD_UDF6         = UDF6,
         @vOD_UDF7         = UDF7,
         @vOD_UDF8         = UDF8,
         @vOD_UDF9         = UDF9,
         @vOD_UDF10        = UDF10,
         @vOD_UDF11        = UDF11,
         @vOD_UDF12        = UDF12,
         @vOD_UDF13        = UDF13,
         @vOD_UDF14        = UDF14,
         @vOD_UDF15        = UDF15,
         @vOD_UDF16        = UDF16,
         @vOD_UDF17        = UDF17,
         @vOD_UDF18        = UDF18,
         @vOD_UDF19        = UDF19,
         @vOD_UDF20        = UDF20,
         @vOD_UDF21        = UDF21,
         @vOD_UDF22        = UDF22,
         @vOD_UDF23        = UDF23,
         @vOD_UDF24        = UDF24,
         @vOD_UDF25        = UDF25,
         @vOD_UDF26        = UDF26,
         @vOD_UDF27        = UDF27,
         @vOD_UDF28        = UDF28,
         @vOD_UDF29        = UDF29,
         @vOD_UDF30        = UDF30
  from OrderDetails
  where (OrderDetailId = @vOrderDetailId);

  select @vCarrier     = Carrier,
         @vSCAC        = ShipVia,
         @vShipViaDesc = Description
  from ShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

   /* Get Company Details*/
  select @vShipFromName     = SF.Name,
         @vShipFromAddr1    = SF.AddressLine1,
         @vShipFromAddr2    = SF.AddressLine2,
         @vShipFromCity     = SF.City,
         @vShipFromState    = SF.State,
         @vShipFromZip      = SF.Zip,
         @vShipFromCountry  = SF.Country,
         @vShipFromCSZ      = SF.CityStateZip,
         @vShipFromPhoneNo  = SF.PhoneNo
  from Contacts SF
  where (SF.ContactRefId = @vShipFrom) and
        (SF.ContactType = 'F' /* Ship From */) and
        (SF.BusinessUnit = @BusinessUnit);

  /* Get ShipTo Details*/
  select @vShipToName       = SHTA.Name,
         @vShipToAddr1      = SHTA.AddressLine1,
         @vShipToAddr2      = SHTA.AddressLine2,
         @vShipToCity       = SHTA.City,
         @vShipToState      = SHTA.State,
         @vShipToZip        = SHTA.Zip,
         @vShipToCSZ        = SHTA.CityStateZip,
         @vShipToReference1 = SHTA.Reference1,
         @vShipToReference2 = SHTA.Reference2
  from dbo.fn_Contacts_GetShipToAddress(null /* Order Id */, @vShipToId) SHTA

  /* Get Sold To Details*/
  select @vSoldToName       = SOTA.Name,
         @vSoldToAddr1      = SOTA.AddressLine1,
         @vSoldToAddr2      = SOTA.AddressLine2,
         @vSoldToCity       = SOTA.City,
         @vSoldToState      = SOTA.State,
         @vSoldToZip        = SOTA.Zip,
         @vSoldToCSZ        = SOTA.CityStateZip,
         @vSoldToEmail      = SOTA.Email
  from Contacts SOTA
  where (SOTA.ContactRefId = @vSoldToId) and
        (SOTA.ContactType in ('C' /* Customer/SoldTo */)) and
        (SOTA.BusinessUnit = @BusinessUnit);

  /* Get MarkFor Details*/
  select @vMarkForName       = MFA.Name,
         @vMarkForAddr1      = MFA.AddressLine1,
         @vMarkForAddr2      = MFA.AddressLine2,
         @vMarkForCity       = MFA.City,
         @vMarkForState      = MFA.State,
         @vMarkForZip        = MFA.Zip,
         @vMarkForCSZ        = MFA.CityStateZip,
         @vMarkForReference1 = MFA.Reference1,
         @vMarkForReference2 = MFA.Reference2
  from Contacts MFA
  where (MFA.ContactRefId = @vMarkForAddress) and
        (MFA.ContactType in ('S' /* Ship To */, 'M' /* Mark For */)) and
        (BusinessUnit = @BusinessUnit);

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Retrieve all data', @@ProcId;

  /* Get Ship Notifications */
  select @vShipNotifications = dbo.fn_ShipLabel_GetNotification(@vLPN);

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'ShipLabel_GetNotification', @@ProcId;

  /* Split the SSCC barcode into individual components as some labels use it that way */
  exec pr_ShipLabel_SplitSSCCBarcode  @vSSCC_Barcode, default /* Barcode Type */,
                                      @vSSCC_PackageCode output, @vSSCC_CompanyId  output,
                                      @vSSCC_SeqNo       output, @vSSCC_CheckDigit output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'ShipLabel_SplitSSCCBarcode', @@ProcId;

  /* To Get the SCC barcode */
  -- TODO --

  /* If printing batch labels, then in 1 of N, N is the total cases on the Task */
  if (@Operation = 'PrintBatchLabel')
    select @vTotalLPNs = @vCasesToPick;

  /* Validating whether given carton is a multi SKU Carton or not*/
  if ((@vSKUId is null) and (@vLPNQuantity > 0))
      select @vSKU            = 'Multiple',
             @vSKUDescription = 'Multiple SKUs';

  /* If LabelType is unknown, assume it is a ship label */
  select @vLabelType  = coalesce(@vLabelType, 'Ship');
  select @vPrintFlags = case when @vLabelType = 'Ship' then 'SL'
                             when @vLabelType = 'Contents' then 'CL'
                             when @vLabelType = 'ShipContents' then 'SCL'
                             when @vLabelType = 'Return' then 'RL'
                             else ''
                        end;

  /* Update print flags only if is not already recorded */
  update LPNs
  set PrintFlags = case when PrintFlags is null then @vPrintFlags
                        when charindex(@vPrintFlags, coalesce(PrintFlags, '')) = 0 then ',' + @vPrintFlags
                        else PrintFlags
                   end
  where (LPNId = @LPNId);

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'LPNLabelled', @UserId, null /* ActivityTimestamp */,
                            @LPNId   = @LPNId,
                            @Note1   = @vLabelType;

  /* !!!! WARNING !!!WARNING !!!WARNING !!!
    If an new field is added to following dataset,
     TLPNShipLabelData should be updated to return the new field as well
    Otherwise, there will be issues in callers. One is Printing labels from ShippingDocs - pr_ShipLabel_GetLPNDataXML calls it */

  /* Return all the info collected */
  insert into #LPNShipLabelData
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
         @vMarkForAddress       as MarkForAddress,
         @vMarkForName          as MarkforName,
         @vMarkForReference2    as MarkforStore,
         @vMarkForAddr1         as MarkforAddress1,
         @vMarkForAddr2         as MarkforAddress2,
         @vMarkForCity          as MarkforCity,
         @vMarkForState         as MarkforState,
         @vMarkForZip           as MarkforZip,
         @vMarkForCSZ           as MarkforCSZ,
         @vMarkForReference1    as MarkForReference1,
         @vMarkForReference2    as MarkForReference2,
         /* ShipTo information. */
         @vShipToId             as ShipToId,
         @vShipToName           as ShipToName,
         @vShipToStore          as ShipToStore,
         @vShipToAddr1          as ShipToAddress1,
         @vShipToAddr2          as ShipToAddress2,
         ''                     as ShipToAddress3,
         @vShipToCity           as ShipToCity,
         @vShipToState          as ShipToState,
         @vShipToZip            as ShipToZip,
         @vShipToCSZ            as ShipToCSZ,
         @vShipToReference1     as ShipToReference1,
         @vShipToReference2     as ShipToReference2,
         /* Sold To information */
         @vSoldToName           as SoldToName,
         @vSoldToAddr1          as SoldToAddr1,
         @vSoldToAddr2          as SoldToAddr2,
         @vSoldToCity           as SoldToCity,
         @vSoldToState          as SoldToState,
         @vSoldToZip            as SoldToZip,
         @vSoldToCSZ            as SoldToCSZ,
         @vSoldToEmail          as SoldToEmail,
         /* Shipping Info */
         @vShipVia              as ShipVia,
         @vShipViaDesc          as ShipViaDesc,
         @vSCAC                 as SCAC,
         @vVICSBoLNumber        as BillofLading,
         @vProNumber            as ProNumber,
         @vDesiredShipDate      as DesiredShipDate,
         @vLoadNumber           as LoadNumber,
         @vClientLoad           as ClientLoad,
         /* UCC & SCC Barcodes */
         ''                     as BarcodeType,
         @vSSCC_Barcode         as UCCBarcode, /* UCC */
         @vSCC_Barcode          as SCCBarcode,
         @vSSCC_PackageCode     as PackingCode,
         @vSSCC_CompanyId       as CompanyID,
         @vSSCC_SeqNo           as SequentialNumber,
         @vSSCC_CheckDigit      as CheckDigit,
         @vTrackingNo           as TrackingNo,
         /* WaveNo Info */
         @vWaveId               as WaveId,
         @vWaveNo               as WaveNo,
         @vWaveType             as WaveType,
         @vWaveNumOrders        as WaveNumOrders,
         @vWaveNo               as PickBatchNo,
         /* Order header Info */
         @vOrderId              as OrderId,
         @vPickTicket           as PickTicket,
         @vSalesOrder           as SalesOrder,
         @vCustPO               as CustPO,
         @vAccount              as Account,
         @vAccountName          as AccountName,
         @vPickZone             as PickZone,
         @vShippedDate          as ShippedDate,
         @vWaveSeqNo            as WaveSeqNo,
         @vOH_UDF1              as OH_UDF1,
         @vOH_UDF2              as OH_UDF2,
         @vOH_UDF3              as OH_UDF3,
         @vOH_UDF4              as OH_UDF4,
         @vOH_UDF5              as OH_UDF5,
         @vOH_UDF6              as OH_UDF6,
         @vOH_UDF7              as OH_UDF7,
         @vOH_UDF8              as OH_UDF8,
         @vOH_UDF9              as OH_UDF9,
         @vOH_UDF10             as OH_UDF10,
         @vOH_UDF11             as OH_UDF11,
         @vOH_UDF12             as OH_UDF12,
         @vOH_UDF13             as OH_UDF13,
         @vOH_UDF14             as OH_UDF14,
         @vOH_UDF15             as OH_UDF15,
         @vOH_UDF16             as OH_UDF16,
         @vOH_UDF17             as OH_UDF17,
         @vOH_UDF18             as OH_UDF18,
         @vOH_UDF19             as OH_UDF19,
         @vOH_UDF20             as OH_UDF20,
         @vOH_UDF21             as OH_UDF21,
         @vOH_UDF22             as OH_UDF22,
         @vOH_UDF23             as OH_UDF23,
         @vOH_UDF24             as OH_UDF24,
         @vOH_UDF25             as OH_UDF25,
         @vOH_UDF26             as OH_UDF26,
         @vOH_UDF27             as OH_UDF27,
         @vOH_UDF28             as OH_UDF28,
         @vOH_UDF29             as OH_UDF29,
         @vOH_UDF30             as OH_UDF30,
         @vWarehouse            as Warehouse,
         /* Order Detail Info */
         @vHostOrderLine        as HostOrderLine,
         @vCustSKU              as CustomerItem, /* 2020/07/09 Deprecated */
         @vCustSKU              as CustSKU,
         @vRetailUnitPrice      as RetailUnitPrice,
         @vOD_UDF1              as OD_UDF1,
         @vOD_UDF2              as OD_UDF2,
         @vOD_UDF3              as OD_UDF3,
         @vOD_UDF4              as OD_UDF4,
         @vOD_UDF5              as OD_UDF5,
         @vOD_UDF6              as OD_UDF6,
         @vOD_UDF7              as OD_UDF7,
         @vOD_UDF8              as OD_UDF8,
         @vOD_UDF9              as OD_UDF9,
         @vOD_UDF10             as OD_UDF10,
         @vOD_UDF11             as OD_UDF11,
         @vOD_UDF12             as OD_UDF12,
         @vOD_UDF13             as OD_UDF13,
         @vOD_UDF14             as OD_UDF14,
         @vOD_UDF15             as OD_UDF15,
         @vOD_UDF16             as OD_UDF16,
         @vOD_UDF17             as OD_UDF17,
         @vOD_UDF18             as OD_UDF18,
         @vOD_UDF19             as OD_UDF19,
         @vOD_UDF20             as OD_UDF20,
         @vOD_UDF21             as OD_UDF21,
         @vOD_UDF22             as OD_UDF22,
         @vOD_UDF23             as OD_UDF23,
         @vOD_UDF24             as OD_UDF24,
         @vOD_UDF25             as OD_UDF25,
         @vOD_UDF26             as OD_UDF26,
         @vOD_UDF27             as OD_UDF27,
         @vOD_UDF28             as OD_UDF28,
         @vOD_UDF29             as OD_UDF29,
         @vOD_UDF30             as OD_UDF30,
         /* SKU Details */
         @vSKUId                as SKUId,
         @vSKU                  as SKU,
         @vSKUDescription       as SKUDescription,
         @vUPC                  as UPC,
         @vSKUUoM               as UOM,
         @vLD_SKU1              as SKU1,
         @vLD_SKU2              as SKU2,
         @vLD_SKU3              as SKU3,
         @vLD_SKU4              as SKU4,
         @vLD_SKU5              as SKU5,
         @vLD_SKU1Desc          as SKU1Description,
         @vLD_SKU2Desc          as SKU2Description,
         @vLD_SKU3Desc          as SKU3Description,
         @vLD_SKU4Desc          as SKU4Description,
         @vLD_SKU5Desc          as SKU5Description,
         @vSizeScale            as SKUSizeScale,
         @vSizeSpread           as SKUSizeSpread,
         /* LPN info */
         @vLPNId                as LPNId,
         @vLPN                  as LPN,
         @vLPNInnerPacks        as LPNInnerPacks,
         @vLPNQuantity          as LPNQuantity,
         @vUnitsPerPackage      as UnitsperPackage,
         @vPrePackQty           as PrepackQty,
         @vLPNLot               as LPNLot,
         ''                     as ExpiryDate,
         @vAlternateLPN         as AlternateLPN,
         FORMAT(@vLPNWeight, '#####.##')
                                as LPNWeight,
         @vLPNNumLines          as LPNNumLines,
         @vLPNNumSKUs           as LPNNumSKUs,
         @vLPNNumSizes          as LPNNumSizes,
         /* LPN Detail info */
         @vCoO                  as CoO,
         @vPickedBy             as PickedBy,
         /* Label info */
         1                      as NumberofLabels,
         @vLPNSeqNo             as CurrentCarton,
         @vTotalLPNs            as NumberofCartons,
         /*case when (@Operation = 'PrintSPGLabel')
                then SL.Label
              else null end     as Label, */
         coalesce(SL.IsValidTrackingNo, 'N')
                                as IsValidTrackingnNo,
         /* Other Info */
         @vPickLocation         as PickLocation,
         @vPickLocationRow      as PickLocationRow,
         @vPickLocationLevel    as PickLocationLevel,
         @vPickLocationSection  as PickLocationSection,
         @vCurrentDate          as CurrentDateTime,
         @vTaskId               as TaskId,
         ''                     as IsLastPickFromLocation,
         ''                     as Destination,
         @vPrintFlags           as LabelType,
         @vCartonType           as CartonType,
         @vCartonTypeDesc       as CartonTypeDesc,
         @vAdditionalInfo       as UDF1, -- TODO: Cannot fit more than 50 into UDF. Need to evaluate and fix it.
         coalesce(nullif(substring(@vIPSpread, 1, 50), ''), cast(@vLPNQuantity as varchar(max)))
                                as UDF2,
         coalesce(@vNoOfPrepacks, 0)
                                as UDF3,
         substring(@vShipNotifications, 1, 50)
                                as UDF4, -- Cannot fit more than 50 into UDF
         ''                     as UDF5
  from LPNs L
    left outer join ShipLabels SL on (L.LPNId = SL.EntityId) and (SL.Status = 'A') and (SL.LabelType = 'S')
  where (L.LPNId = @LPNId);

  if (@ReturnDataSet = 'Y')
    select * from #LPNShipLabelData;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_ShipLabel_GetLPNData_End', @@ProcId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'LPN', @LPNId, @vLPN, 'ShipLabel_GetLPNData', @@ProcId, 'Markers_ShipLabel_GetLPNData';
ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_ShipLabel_GetLPNData */

Go
