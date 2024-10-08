/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/29  VS      pr_Imports_ReceiptDetails, pr_Imports_ReceiptDetails_Validate: Removed table variable for InterfaceLogDetails (HA-3014)
  2021/04/16  SV      pr_Imports_ReceiptDetails_Validate: Initial Version
                      pr_Imports_ReceiptDetails_AddSpecialSKUs, pr_Imports_ReceiptDetails:
  2021/03/16  TK      pr_Imports_OrderDetails & pr_Imports_ReceiptDetails: Import records in the order they are inserted into DE tables (HA-GoLive)
  2021/03/03  RKC     pr_Imports_ReceiptDetails: Made changes to trim the spaces on the Label code field (HA-2075)
  2020/04/23  OK      pr_Imports_ReceiptDetails: Included Lot (reverse ported from onsite prod)
  2020/04/22  MS      pr_Imports_ReceiptDetails, pr_Imports_OrderDetail, pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNs, pr_Imports_ASNLPNHdr_Insert, pr_Imports_ASNLPNHdr_Update
  2020/03/19  YJ      pr_Imports_OrderDetails, pr_Imports_ReceiptDetails, pr_Imports_SKUs: Fields corrections as per-interface document (CIMS-2984)
  2018/05/10  SV      pr_Imports_ReceiptHeaders and pr_Imports_ReceiptDetails: Code changes to restrict deleting the Receipt and its detaillines
  2018/01/05  SV      pr_Imports_ReceiptDetails: Considered HostRecId as we are validating with it and
  2017/05/29  NB      pr_Imports_ReceiptHeaders, pr_Imports_ReceiptDetails : Change XML
                      pr_Imports_ReceiptDetails: Bug Fix to properly identify SKUId and ReceiptDetailId
                      pr_Imports_ReceiptDetails_AddSpecialSKUs: Commented debug select statements(HPI-1396)
  2017/02/15  AY      pr_Imports_ReceiptDetails_AddSpecialSKUs: Use RD.UDF3 for SKU.Desc for Special Items (HPI-1391)
  2016/10/21  AY      pr_Imports_ReceiptDetails: Bug fix - not updating ROD.SKU (HPI-GoLive)
  2016/09/23  DK      pr_Imports_ReceiptDetails: Bug fix Removed join condition on ReceiptId as it will delete other receipt details along
  2016/07/04  OK      pr_Imports_ReceiptDetails_AddSpecialSKUs: Added to Import Special SKUs if they are not already in cIMS (HPI-230)
                      pr_Imports_ReceiptDetails: Enhanced to add InputXML from XML to Temp Table
  2016/03/22  NB      pr_Imports_ReceiptDetails: Enhanced to transform Ownership value from mapping(NBD-264)
  2016/03/08  AY      pr_Imports_ReceiptDetails: Changed to process input params and not just XML
  2016/01/10  DK      pr_Imports_ReceiptDetails: Enhanced to import ReasonCode (FB-596).
  2015/11/10  OK      pr_Imports_OrderDetails, pr_Imports_ReceiptDetails: Made the changes
  2015/03/03  NY      pr_Imports_ReceiptDetails: Added coalesce condition to UnitCost.
  2014/12/02  SK      pr_Imports_ImportRecords, pr_Imports_ReceiptDetails, pr_Imports_ValidateReceiptDetail:
  2014/06/12  VM      pr_Imports_ReceiptDetails: Bug-fix: Insert UDFs from XML and not from local variables
  2014/03/21  AY      pr_Imports_ReceiptDetails: Delete ROD if nothing has been received against it.
  2012/12/11  PK      pr_Imports_ReceiptDetails: Enhancements to gather SKU info by using RD UDF's.
  2012/06/26  AY      pr_Imports_ReceiptDetails: Fixed all issues.
  2012/05/14  PKS     pr_Imports_ReceiptDetails: Ownership column was added.
  2011/08/04  YA      pr_Imports_ReceiptHeaders, pr_Imports_ReceiptDetails
  2011/07/09  PK      pr_Imports_ReceiptDetails : Added HostReceiptLine.
                      pr_Imports_ReceiptDetails: Send SKU also to validate and validate details before Inserting
  2011/01/17  VK      Made changes to the pr_Imports_ReceiptHeaders,pr_Imports_ReceiptDetails
  2011/01/06  VK      Made changes to procedures pr_Imports_ReceiptHeaders,pr_Imports_ReceiptDetails
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ReceiptDetails') is not null
  drop Procedure pr_Imports_ReceiptDetails;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_ReceiptDetails: There are 3 ways to import RDs into CIMS system.
    1. @xmlData/@documentHandle: Pass data thru @xmlData/@documentHandle. The given xml
       will be parsed and inserted into #ReceiptDetailsImport and processed.
    2. #ReceiptDetailsImport: Provide the data to import via the hash table
    3. Pass individual paramenters: This doesn't require any of @xmlData, @documentHandle
       & #ReceiptDetailsImport. Just pass thru the individual parameters and rest of the
       import process will be taken care by the code.

  In all cases, in the end, data is inserted into #ReceiptDetailsImport and processed
  from there on.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ReceiptDetails
  (@xmlData           Xml                = null,
   @documentHandle    TInteger           = null,
   @InterfaceLogId    TRecordId          = null,
   @Action            TFlag              = null,
   @VendorId          TVendorId          = null,
   @VendorSKU         TVendorSKU         = null,
   @ReceiptNumber     TReceiptNumber     = null,
   @SKU               TSKU               = null,
   @SKU1              TSKU               = null,
   @SKU2              TSKU               = null,
   @SKU3              TSKU               = null,
   @SKU4              TSKU               = null,
   @SKU5              TSKU               = null,
   @CoO               TCoO               = null,
   @QtyOrdered        TQuantity          = null,
   @UnitCost          TCost              = null,
   @CustPO            TCustPO            = null,
   @HostReceiptLine   THostReceiptLine   = null,
   @Ownership         TOwnership         = null,
   @Lot               TLot               = null,
   @InventoryClass1   TInventoryClass    = null,
   @InventoryClass2   TInventoryClass    = null,
   @InventoryClass3   TInventoryClass    = null,
   @ReasonCode        TReasonCode        = null,
   @UDF1              TUDF               = null,
   @UDF2              TUDF               = null,
   @UDF3              TUDF               = null,
   @UDF4              TUDF               = null,
   @UDF5              TUDF               = null,
   @UDF6              TUDF               = null,
   @UDF7              TUDF               = null,
   @UDF8              TUDF               = null,
   @UDF9              TUDF               = null,
   @UDF10             TUDF               = null,
   @UDF11             TUDF               = null,
   @UDF12             TUDF               = null,
   @UDF13             TUDF               = null,
   @UDF14             TUDF               = null,
   @UDF15             TUDF               = null,
   @UDF16             TUDF               = null,
   @UDF17             TUDF               = null,
   @UDF18             TUDF               = null,
   @UDF19             TUDF               = null,
   @UDF20             TUDF               = null,
   @UDF21             TUDF               = null,
   @UDF22             TUDF               = null,
   @UDF23             TUDF               = null,
   @UDF24             TUDF               = null,
   @UDF25             TUDF               = null,
   @UDF26             TUDF               = null,
   @UDF27             TUDF               = null,
   @UDF28             TUDF               = null,
   @UDF29             TUDF               = null,
   @UDF30             TUDF               = null,
   @BusinessUnit      TBusinessUnit      = null,
   @CreatedDate       TDateTime          = null,
   @ModifiedDate      TDateTime          = null,
   @CreatedBy         TUserId            = null,
   @ModifiedBy        TUserId            = null,
   @HostRecId         TRecordId          = null
  )
as
  declare @vReturnCode                TInteger,
          @vRecordId                  TRecordId,
          @vReceiptId                 TRecordId,
          @vNextOrderLine             TSequence,
          @vNextSeqNo                 TSequence,

          @ttReceiptDetailsImport      TReceiptDetailImportType,
          @ttReceiptDetailsValidation  TReceiptDetailValidationType,
          @ttAuditInfo                 TAuditTrailInfo,
          @ttImportValidations         TImportValidationType,
          @vVarReceiptId               TRecordId,
          @vVarReceiptDetailId         TRecordId,
          @vVarRecordId                TRecordId;

begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  if (@xmldata is not null) and (@InterfaceLogId is null)
    select @InterfaceLogId = Record.Col.value('ParentLogId[1]','TRecordId')
    from @xmlData.nodes('//msg/msgHeader') as Record(Col);

  /* In some cases hash table may have been created by caller, if not create it as
     all data is inserted into hash table and then processed */
  if object_id('tempdb..#ReceiptDetailsImport') is null select * into #ReceiptDetailsImport from @ttReceiptDetailsImport;

  if object_id('tempdb..#ImportValidations') is null
    select * into #ImportValidations from @ttImportValidations

  if (@documentHandle is not null)
    begin
      /* Get the required information from the input xml */
      insert into #ReceiptDetailsImport (
        InputXML,
        RecordType,
        RecordAction,

        ReceiptNumber,
        VendorId,
        VendorSKU,
        CoO,
        QtyOrdered,
        UnitCost,
        CustPO,
        HostReceiptLine,
        Ownership,
        Lot,
        InventoryClass1,
        InventoryClass2,
        InventoryClass3,
        SKU,
        SKU1,
        SKU2,
        SKU3,
        SKU4,
        SKU5,
        ReasonCode,
        RD_UDF1,
        RD_UDF2,
        RD_UDF3,
        RD_UDF4,
        RD_UDF5,
        RD_UDF6,
        RD_UDF7,
        RD_UDF8,
        RD_UDF9,
        RD_UDF10,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId,
        ReceiptDetailId,
        ReceiptId,
        SKUId,
        QtyReceived,
        ExtraQtyAllowed
        )
      select *,
             null, /* ReceiptDetailId */
             null, /* ReceiptId */
             null, /* SKUId*/
             0,   /* QtyReceived */
             0    /* ExtraQtyAllowed */
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="RD"]', 2) -- condition forces to read only Records with RecordType OH
      with (InputXML                 nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType               TRecordType,
            RecordAction             TAction        'Action',
            ReceiptNumber            TReceiptNumber,
            VendorId                 TVendorId,
            VendorSKU                TVendorSKU,
            CoO                      TCoO,
            QtyOrdered               TQuantity,
            UnitCost                 TCost,
            CustPO                   TCustPO,
            HostReceiptLine          THostReceiptLine,
            Ownership                TOwnership,
            Lot                      TLot,
            InventoryClass1          TInventoryClass,
            InventoryClass2          TInventoryClass,
            InventoryClass3          TInventoryClass,
            SKU                      TSKU,
            SKU1                     TSKU,
            SKU2                     TSKU,
            SKU3                     TSKU,
            SKU4                     TSKU,
            SKU5                     TSKU,
            ReasonCode               TReasonCode,
            RD_UDF1                  TUDF,
            RD_UDF2                  TUDF,
            RD_UDF3                  TUDF,
            RD_UDF4                  TUDF,
            RD_UDF5                  TUDF,
            RD_UDF6                  TUDF,
            RD_UDF7                  TUDF,
            RD_UDF8                  TUDF,
            RD_UDF9                  TUDF,
            RD_UDF10                 TUDF,
            BusinessUnit             TBusinessUnit,
            CreatedDate              TDateTime   'CreatedDate/text()',
            ModifiedDate             TDateTime   'ModifiedDate/text()',
            CreatedBy                TUserId,
            ModifiedBy               TUserId,
            RecordId                 TRecordId);
    end
  else
  /* if caller already inserted data, then ignore the params */
  if (not exists (select * from #ReceiptDetailsImport))
    begin
      insert into #ReceiptDetailsImport (
        RecordAction,
        --ReceiptDetailId,
        ReceiptNumber,
        --ReceiptId,
        --ReceiptLine,
        --SKUId,
        VendorId,
        VendorSKU,
        SKU,
        SKU1,
        SKU2,
        SKU3,
        SKU4,
        SKU5,
        CoO,
        QtyOrdered,
        QtyReceived,
        --ExtraQtyAllowed,
        UnitCost,
        CustPO,
        HostReceiptLine,
        Ownership,
        Lot,
        InventoryClass1,
        InventoryClass2,
        InventoryClass3,
        ReasonCode,
        RD_UDF1,
        RD_UDF2,
        RD_UDF3,
        RD_UDF4,
        RD_UDF5,
        RD_UDF6,
        RD_UDF7,
        RD_UDF8,
        RD_UDF9,
        RD_UDF10,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId)
      select
        @Action,
        @ReceiptNumber,
        @VendorId,
        @VendorSKU,
        nullif(@SKU, ''),
        @SKU1,
        @SKU2,
        @SKU3,
        @SKU4,
        @SKU5,
        @CoO,
        @QtyOrdered,
        0 /* Received Qty */,
        @UnitCost,
        @CustPO,
        @HostReceiptLine,
        @Ownership,
        @Lot,
        @InventoryClass1,
        @InventoryClass2,
        @InventoryClass3,
        @ReasonCode,
        @UDF1,
        @UDF2,
        @UDF3,
        @UDF4,
        @UDF5,
        @UDF6,
        @UDF7,
        @UDF8,
        @UDF9,
        @UDF10,
        @BusinessUnit,
        @CreatedDate,
        @ModifiedDate,
        @CreatedBy,
        @ModifiedBy,
        @HostRecId;
    end

  /* Import if any Special SKUs exists */
  exec pr_Imports_ReceiptDetails_AddSpecialSKUs

  /* Get the valid SKU information - allow RODs for inactive SKUs */
  update #ReceiptDetailsImport
  set SKUId     = S.SKUId,
      SKU       = S.SKU,
      SKUStatus = S.Status
  from #ReceiptDetailsImport RDI
  /* As we do not know user passed the either UPC or SKU, so update the SKU and SKUId */
  cross apply dbo.fn_SKUs_GetScannedSKUs(RDI.SKU, RDI.BusinessUnit) S
  --where (S.Ownership = RDI.Ownership);

  /* if there are no mappings setup, then the source value will be returned for Target value */
  select top 1
         @BusinessUnit = BusinessUnit
  from #ReceiptDetailsImport;

  update #ReceiptDetailsImport
  set Ownership = coalesce(MO.TargetValue, RDI.Ownership)
  from #ReceiptDetailsImport RDI
       left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'Ownership', 'Import' /* Operation */,  @BusinessUnit) MO on (MO.SourceValue = RDI.Ownership);

  /* Validate the RH records in #ReceiptHeadersImport. Invalid records would be updated with RecordAction of E */
  exec pr_Imports_ReceiptDetails_Validate;

  /* Set Validation tabular values for Logging details
     Here, we need to read the HostRecId as we are using it to send back to the
     called procedure to Acknowledge processed records in host table   */
  insert into #ImportValidations(RecordId, EntityId, EntityKey, RecordType, KeyData, HostRecId,
                                 InputXML, BusinessUnit, RecordAction, ResultXML)
    select RecordId, ReceiptDetailID, ReceiptNumber , 'RD', ReceiptNumber + '.' + HostReceiptLine, HostRecId,
           convert(nvarchar(max), InputXML), BusinessUnit, RecordAction, convert(nvarchar(max), ResultXML)
    from #ReceiptDetailsImport;

  /* Insert update or Delete based on Action */
  if (exists(select * from #ReceiptDetailsImport where RecordAction = 'I' /* Insert */))
    insert into ReceiptDetails (
      ReceiptId,
      SKUId,
      VendorId,
      VendorSKU,
      CoO,
      QtyOrdered,
      ExtraQtyAllowed,
      UnitCost,
      CustPO,
      HostReceiptLine,
      Ownership,
      Lot,
      InventoryClass1,
      InventoryClass2,
      InventoryClass3,
      ReasonCode,
      UDF1,
      UDF2,
      UDF3,
      UDF4,
      UDF5,
      UDF6,
      UDF7,
      UDF8,
      UDF9,
      UDF10,
      BusinessUnit,
      CreatedDate,
      CreatedBy)
    select
      ReceiptId,
      SKUId,
      VendorId,
      VendorSKU,
      CoO,
      QtyOrdered,
      ExtraQtyAllowed,
      UnitCost,
      CustPO,
      HostReceiptLine,
      Ownership,
      Lot,
      coalesce(trim(InventoryClass1), ''),
      coalesce(trim(InventoryClass2), ''),
      coalesce(trim(InventoryClass3), ''),
      ReasonCode,
      RD_UDF1,
      RD_UDF2,
      RD_UDF3,
      RD_UDF4,
      RD_UDF5,
      RD_UDF6,
      RD_UDF7,
      RD_UDF8,
      RD_UDF9,
      RD_UDF10,
      BusinessUnit,
      coalesce(CreatedDate, current_timestamp),
      coalesce(CreatedBy, System_User)
    from #ReceiptDetailsImport where (RecordAction = 'I' /* Insert */)
    order by HostRecId;

  if (exists(select * from #ReceiptDetailsImport where RecordAction = 'U' /* Update */))
    update RD1
    set
       RD1.SKUId           = coalesce(RD2.SKUId, RD1.SKUId),  -- if uniqueness is by RO & Line, then we should update SKU, need to do this based on control var
       RD1.CoO             = RD2.CoO,
       RD1.QtyOrdered      = RD2.QtyOrdered,
       RD1.UnitCost        = RD2.UnitCost,
       RD1.CustPO          = RD2.CustPO,
       RD1.Lot             = RD2.Lot,
       RD1.InventoryClass1 = coalesce(trim(RD2.InventoryClass1), ''),
       RD1.InventoryClass2 = coalesce(trim(RD2.InventoryClass2), ''),
       RD1.InventoryClass3 = coalesce(trim(RD2.InventoryClass3), ''),
       RD1.ReasonCode      = RD2.ReasonCode,
       RD1.UDF1            = RD2.RD_UDF1,
       RD1.UDF2            = RD2.RD_UDF2,
       RD1.UDF3            = RD2.RD_UDF3,
       RD1.UDF4            = RD2.RD_UDF4,
       RD1.UDF5            = RD2.RD_UDF5,
       RD1.UDF6            = RD2.RD_UDF6,
       RD1.UDF7            = RD2.RD_UDF7,
       RD1.UDF8            = RD2.RD_UDF8,
       RD1.UDF9            = RD2.RD_UDF9,
       RD1.UDF10           = RD2.RD_UDF10,
       RD1.ModifiedDate    = coalesce(RD2.ModifiedDate, current_timestamp),
       RD1.ModifiedBy      = coalesce(RD2.ModifiedBy, System_User)
       output 'RD', Inserted.ReceiptDetailId, RD2.ReceiptNumber, null /* EntityDetails */, 'AT_ReceiptDetailModified' /* Audit Activity */, RD2.RecordAction /* Action */,
              null /* Comment */, Inserted.BusinessUnit, Inserted.ModifiedBy, null /* UDF1 */, null /* UDF2 */, null /* UDF3 */, null /* UDF4 */, null /* UDF5 */,
              null /* Audit Id */ into @ttAuditInfo
       from ReceiptDetails RD1 inner join #ReceiptDetailsImport RD2 on (RD1.ReceiptId       = RD2.ReceiptId) and
                                                                        (RD1.ReceiptDetailId = RD2.ReceiptDetailId)
       where RD2.RecordAction = 'U' /* Update */;

  if (exists(select * from #ReceiptDetailsImport where RecordAction = 'D' /* Delete */))
    begin
      /* Capture audit info */
      insert into @ttAuditInfo
      select 'RD', RD.ReceiptDetailId, RD.ReceiptNumber, null /* EntityDetails */, 'AT_ReceiptDetailDeleted' /* Audit Activity */, RD.RecordAction /* Action */,
             null /* Comment */, RD.BusinessUnit, RD.ModifiedBy, null /* UDF1 */, null /* UDF2 */, null /* UDF3 */, null /* UDF4 */, null /* UDF5 */, null /* Audit Id */
      from #ReceiptDetailsImport RD
        join ReceiptDetails R on (RD.ReceiptDetailId = R.ReceiptDetailId)
      where (R.QtyReceived   =  0) and (R.QtyInTransit = 0) and
            (RD.RecordAction = 'D' /* Delete */);

      /* We can delete ReceiptDetails only when the ReceiptDetail doesn't associate with any of the Intansit LPNs */
      /* Delete the ROD if nothing has been received against it */
      delete R
      from ReceiptDetails R
       join #ReceiptDetailsImport RD on (RD.ReceiptDetailId = R.ReceiptDetailId)
      where (R.QtyReceived   =  0) and (R.QtyInTransit = 0) and
            (RD.RecordAction = 'D' /* Delete */);

      /* Capture audit info */
      insert into @ttAuditInfo
      select 'RD', RD.ReceiptDetailId, RD.ReceiptNumber, null /* EntityDetails */, 'AT_ReceiptDetailDeleted' /* Audit Activity */, RD.RecordAction /* Action */,
             null /* Comment */, RD.BusinessUnit, RD.ModifiedBy, null /* UDF1 */, null /* UDF2 */, null /* UDF3 */, null /* UDF4 */, null /* UDF5 */, null /* Audit Id */
      from #ReceiptDetailsImport RD
        join ReceiptDetails R on (RD.ReceiptDetailId = R.ReceiptDetailId)
      where (R.QtyReceived   <>  0) and (R.QtyInTransit = 0) and
            (RD.RecordAction =  'D' /* Delete */);

      /* If something has already been received/Intransit against the ROD, then do not delete it */
      update R
      set R.QtyOrdered = 0 /* Inactive */
      from ReceiptDetails R
        join #ReceiptDetailsImport RD on (RD.ReceiptDetailId = R.ReceiptDetailId)
      where (R.QtyReceived   <>  0) and (R.QtyInTransit = 0) and
            (RD.RecordAction =  'D' /* Delete */);
    end

  /* Verify if Audit Trail should be updated */
  if (exists(select * from @ttAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      update @ttAuditInfo
      set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'RD', EntityKey /* ReceiptNumber */ , null, null , null, null , null, null, null, null, null, null);

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, default;

  /* Preprocess receipt */
  /* Mark the receipt headers of the inserted and updated records for preprocessing */
  update ReceiptHeaders
  set PreprocessFlag = case when (PreprocessFlag <> 'I' /* Ignore */) then 'N' /* No */ else PreprocessFlag end
  where ReceiptId in (select ReceiptId from #ReceiptDetailsImport where RecordAction in ('I' /* Insert */, 'U' /* Update */));

end /* pr_Imports_ReceiptDetails */

Go
