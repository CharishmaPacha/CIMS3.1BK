/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/15  MS      pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNHdr_Delete, pr_Imports_ASNLPNDetails, pr_Imports_CIMSDE_ImportData
  2020/02/16  AY      pr_Imports_ASNLPNDetails: Migrated changes from CID to recalc LPNs in background
  2020/02/10  SPP     pr_Imports_ASNLPNDetails: Added Join with RD in HostReceiptline to RD and Receiptline to ttASNLD (CID-136) (Ported from Prod)
  2020/02/04  MS      pr_Imports_ASNLPNDetails, pr_Imports_ASNLPNDtl_Insert,
  2019/12/23  TD      pr_Imports_ASNLPNDetails:Changes to consider HostReceiptLine when update Receiptline info on ASNDetail (CID-1233)
  2019/01/25  HB      pr_Imports_ASNLPNHeaders & pr_Imports_ASNLPNDetails : Renamed pr_Imports_ASNLPNs to pr_Imports_ASNLPNHeaders and pr_Imports_ValidateASNLPN
  2018/09/14  TK      pr_Imports_InventoryAdjustments, pr_Imports_ASNLPNs & pr_Imports_ASNLPNDetails:
  2015/10/14  TK      pr_Imports_ASNLPNs & pr_Imports_ASNLPNDetails: Bug fix (ACME-370)
  2015/05/10  YJ      pr_Imports_ASNLPNDetails: Corrected Audit trail
  2015/04/27  TK      pr_Imports_ASNLPNDetails: Enhanced to add SKU and Inventory to picklane if they pass in Logical/Picklane LPN
  pr_Imports_ASNLPNDetails:Changes to update UnitsPerPackage.
  2014/03/25  TD      pr_Imports_ASNLPNDetails:Changes to update putawayClass on LPNs.
  2014/03/04  TD      pr_Imports_ASNLPNDetails:Changes to log audit trail.
  2014/02/26  TD      pr_Imports_ASNLPNDetails:Changes to add receipts if there is no recipt found.
  2012/12/12  PK      pr_Imports_ASNLPNDetails: Enhancements to gather SKU info by using LD UDF's.
  2012/06/27  YA      pr_Imports_ASNLPNDetails: Update counts on ReceiptDetails after importing ASN LPNs.
  > Create #Error temp table if it does not exists - done in pr_Imports_ASNLPNDetails as well.
  Procedure names 'pr_Imports_ASNLPNs' & 'pr_Imports_ASNLPNDetails'
  pr_Imports_ASNLPNDetails  :Addded UDF1 - UDF5.
  2011/02/24  PK      pr_Imports_ASNLPNs, pr_Imports_ASNLPNDetails : Added Default values for fields in temp tabel.
  2011/02/07  PK      Created pr_Imports_Vendors, pr_Imports_ASNLPNs, pr_Imports_ASNLPNDetails,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNDetails') is not null
  drop Procedure pr_Imports_ASNLPNDetails;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_ASNLPNDetails
    * In this procedure we are assuming that we have only one detail line.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNDetails
  (@xmlData           Xml              = null,
   @documentHandle    TInteger         = null,
   @InterfaceLogId    TRecordId        = null,
   @Action            TFlag            = null,
   @LPN               TLPN             = null,
   @CoO               TCoO             = null,
   @SKU               TSKU             = null,
   @SKU1              TSKU             = null,
   @SKU2              TSKU             = null,
   @SKU3              TSKU             = null,
   @SKU4              TSKU             = null,
   @SKU5              TSKU             = null,
   @InnerPacks        TInnerPacks      = null,
   @Quantity          TQuantity        = null,
   @ReceiptNumber     TReceiptNumber   = null,
   @HostReceiptLine   THostReceiptLine = null,
   @Weight            TWeight          = null,
   @Lot               TLot             = null,
   @UDF1              TUDF             = null,
   @UDF2              TUDF             = null,
   @UDF3              TUDF             = null,
   @UDF4              TUDF             = null,
   @UDF5              TUDF             = null,
   @UDF6              TUDF             = null,
   @UDF7              TUDF             = null,
   @UDF8              TUDF             = null,
   @UDF9              TUDF             = null,
   @UDF10             TUDF             = null,
   @UDF11             TUDF             = null,
   @UDF12             TUDF             = null,
   @UDF13             TUDF             = null,
   @UDF14             TUDF             = null,
   @UDF15             TUDF             = null,
   @UDF16             TUDF             = null,
   @UDF17             TUDF             = null,
   @UDF18             TUDF             = null,
   @UDF19             TUDF             = null,
   @UDF20             TUDF             = null,
   @UDF21             TUDF             = null,
   @UDF22             TUDF             = null,
   @UDF23             TUDF             = null,
   @UDF24             TUDF             = null,
   @UDF25             TUDF             = null,
   @BusinessUnit      TBusinessUnit    = null,
   @CreatedDate       TDateTime        = null,
   @ModifiedDate      TDateTime        = null,
   @CreatedBy         TUserId          = null,
   @ModifiedBy        TUserId          = null,
   @HostRecId         TRecordId        = null
  )
as
  declare @vLPNId           TRecordId,
          @LPNType          TTypeCode,
          @vReceiptId       TRecordId,
          @vReceiptDetailId TRecordId,
          @vSKUId           TRecordId,
          @LocationId       TRecordId,
          @Count            TInteger,
          @vNextSeqNo       TSequence,
          @vNextLPNLine     TSequence,
          @vPrevLPNQty      TQuantity,
          @vReturnCode      TInteger,
          @UserId           TRecordId,
          @vAddReceipts     TControlValue,
          @vAuditActivity   TActivityType,
          @vLPNDetailId     TRecordId;

          /* Table variables for ASNLPNDetails */
  declare @ttImportASNLPNDetails      TASNLPNImportType,
          @ttASNLPNDetailValidations  TImportValidationType,
          @ttLPNsToRecount            TRecountKeysTable,
          @ttReceiptsToPreProcess     TRecountKeysTable,
          @ttAuditInfo                TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#ImportASNAuditInfo') is null
    select * into #ImportASNAuditInfo
    from @ttAuditInfo;
  else
    delete from #ImportASNAuditInfo;

  select @InnerPacks = coalesce(@InnerPacks, 0),
         @Quantity   = coalesce(@Quantity,   0),
         @Weight     = coalesce(@Weight,   0.0);

  if (@xmldata is not null) and (@InterfaceLogId is null)
    begin
      select @InterfaceLogId = Record.Col.value('ParentLogId[1]',     'TRecordId')
      from @xmlData.nodes('//msg/msgHeader') as Record(Col);
    end

  /* Populate the temp table */
  if (@documentHandle is not null)
    begin
      insert into @ttImportASNLPNDetails (
        InputXML,
        RecordType,
        RecordAction,
        ReceiptNumber,
        HostReceiptLine,
        LPN,
        SKU,
        SKU1,
        SKU2,
        SKU3,
        SKU4,
        SKU5,
        InnerPacks,
        Quantity,
        LPND_UDF1,
        LPND_UDF2,
        LPND_UDF3,
        LPND_UDF4,
        LPND_UDF5,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId,
        OnhandStatus)
      select
        *,
        'U' /* Unavailable */
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="ASNLD"]', 2) -- condition forces to read only Records with RecordType ASND
      with (InputXML           nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType         TRecordType,
            Action             TFlag,
            ReceiptNumber      TReceiptNumber,
            HostReceiptLine    THostReceiptLine,
            LPN                TLPN,
            SKU                TSKU,
            SKU1               TSKU,
            SKU2               TSKU,
            SKU3               TSKU,
            SKU4               TSKU,
            SKU5               TSKU,
            InnerPacks         TInnerPacks,
            Quantity           TQuantity,
            LPND_UDF1          TUDF,
            LPND_UDF2          TUDF,
            LPND_UDF3          TUDF,
            LPND_UDF4          TUDF,
            LPND_UDF5          TUDF,
            BusinessUnit       TBusinessUnit,
            CreatedDate        TDateTime                'CreatedDate/text()',
            ModifiedDate       TDateTime                'ModifiedDate/text()',
            CreatedBy          TUserId,
            ModifiedBy         TUserId,
            RecordId           TRecordId);
    end
  else
    begin
      insert into @ttImportASNLPNDetails (
        RecordAction, RecordType,
        ReceiptNumber, HostReceiptLine,
        LPN, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
        InnerPacks, Quantity, OnhandStatus,
        LPND_UDF1, LPND_UDF2, LPND_UDF3, LPND_UDF4, LPND_UDF5,
        BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action, 'ASNLPND',
        @ReceiptNumber, @HostReceiptLine,
        @LPN, @SKU, @SKU1, @SKU2, @SKU3, @SKU4, @SKU5,
        @InnerPacks, @Quantity, 'U' /* Unavailable */,
        @UDF1, @UDF2, @UDF3, @UDF4, @UDF5,
        @BusinessUnit, @CreatedDate, @ModifiedDate, @CreatedBy, @ModifiedBy, @HostRecId;
    end

  /* Get the BusinessUnit, if it is not passed in caller */
  if (coalesce(@BusinessUnit, '') = '')
    select top 1 @BusinessUnit = BusinessUnit from @ttImportASNLPNDetails

  /* Get control value here */
  select @vAddReceipts = dbo.fn_Controls_GetAsString('IMPORT_ASNLD', 'AddReceipts', 'N' /* Default: No*/, @BusinessUnit, '' /* UserId */);

  /* Add or Update the receipts if not exists */
  if (@vAddReceipts = 'Y')
    exec pr_Imports_ASNs_AddOrUpdateReceipts @ttImportASNLPNDetails;

  /* Get the LPN information */
  update ttASNLD
  set LPNId         = L.LPNId,
      Status        = L.Status,
      LPNType       = coalesce(ttASNLD.LPNType,L.LPNType, 'C'),
      DestWarehouse = L.DestWarehouse,
      Ownership     = L.Ownership,
      PrevLPNQty    = L.Quantity
  from @ttImportASNLPNDetails ttASNLD
    join LPNs L on (ttASNLD.LPN = L.LPN) and (ttASNLD.BusinessUnit = L.BusinessUnit);

  /* Get the valid SKU information */
  update ttASNLD
  set SKUId = S.SKUId,
      SKU   = S.SKU
  from @ttImportASNLPNDetails ttASNLD
    /* As we do not know user passed the either UPC or SKU, or SKU attributes */
    cross apply dbo.fn_SKUs_GetScannedSKUs(ttASNLD.SKU, ttASNLD.BusinessUnit) S

  /* Get the LPN detail information */
  update ttASNLD
  set ttASNLD.LPNId       = L.LPNId,
      ttASNLD.LPNDetailId = LD.LPNDetailId,
      ttASNLD.Status      = L.Status
  from @ttImportASNLPNDetails  ttASNLD
               join LPNs       L  on (ttASNLD.LPN = L.LPN) and (ttASNLD.BusinessUnit = L.BusinessUnit)
    left outer join LPNDetails LD on (LD.LPNId = ttASNLD.LPNId) and (LD.SKUId = ttASNLD.SKUId);

  /* Get ReceiptId/ReceiptDetailId */
  update ttASNLD
  set ttASNLD.ReceiptId       = RD.ReceiptId,
      ttASNLD.ReceiptDetailId = RD.ReceiptDetailId
  from @ttImportASNLPNDetails ttASNLD
    join ReceiptHeaders RH on (RH.ReceiptNumber = ttASNLD.ReceiptNumber) and (RH.BusinessUnit = ttASNLD.BusinessUnit)
    join ReceiptDetails RD on (RH.ReceiptId = RD.ReceiptId) and (RD.SKUId = ttASNLD.SKUId) and (RD.HostReceiptLine = ttASNLD.HostReceiptLine)

  /* Validate the records */
  insert @ttASNLPNDetailValidations
    exec pr_Imports_ValidateASNLPNDetails @ttImportASNLPNDetails;

  /* Set RecordAction for ASNLPNDetail Records  */
  update @ttImportASNLPNDetails
  set RecordAction = ALDV.RecordAction
  from @ttImportASNLPNDetails ALDI
    join @ttASNLPNDetailValidations ALDV on (ALDV.RecordId = ALDI.RecordId);

  /* Old Requirement - If the SKU is a Prepack SKU then set the Quantity to 1 */
  /* Update ttASNLD
     set Quantity      = 1
     from @ttImportASNLPNDetails ttASNLD
       join SKUPrepacks SP on (SP.MasterSKUId = ttASNLD.SKUId) */

  /*--------------------------------------------------------------------------*/
  /* Insert LPN Details */
  if (exists (select * from @ttImportASNLPNDetails where RecordAction = 'I' /* Insert */ and LPNType = 'C'/* Carton */))
    exec pr_Imports_ASNLPNDtl_Insert @ttImportASNLPNDetails;

  /*--------------------------------------------------------------------------*/
  /* Add SKU to Picklanes */
  if (exists (select * from @ttImportASNLPNDetails where RecordAction = 'I' /* Insert */ and LPNType = 'L'/* Carton */))
    exec pr_Imports_ASNLPNDtl_AddSKUsToPicklane @ttImportASNLPNDetails;

  /*--------------------------------------------------------------------------*/
  if (exists (select * from @ttImportASNLPNDetails where RecordAction = 'U' /* Update */ and LPNType = 'C'/* Carton */))
    exec pr_Imports_ASNLPNDtl_Insert @ttImportASNLPNDetails;

  /*--------------------------------------------------------------------------*/
  if (@Action = 'D' /* Delete */) and (@LPNType = 'C'/* Carton */)
    exec pr_Imports_ASNLPNDtl_Delete @ttImportASNLPNDetails;

  /* Add or Update ReceivedCounts bases on the updates */
  exec pr_Imports_ASNs_AddOrUpdateReceivedCounts @ttImportASNLPNDetails;

  /*--------------------------------------------------------------------------*/
  /* Get all the LPNs to Recount - Recount does preprocess the LPNs as well and
     calls SetStatus too */
  insert into @ttLPNsToRecount(EntityType, EntityId, EntityKey)
    select distinct 'LPN', LPNId, LPN
    from @ttImportASNLPNDetails
    where RecordAction not in ('D', 'E' /* Delete, Error */);

  exec pr_Entities_RequestRecalcCounts 'LPN', @RecalcOption = 'PC', @ProcId = @@ProcId,
                                        @BusinessUnit     = @BusinessUnit,
                                        @RecountKeysTable = @ttLPNsToRecount;

  /* MS: We are not building the Audit comment with proper info and so it is raising UniqueKey constraint error
      when we have multiple LD's for the same LPN.*/
  /* Verify if Audit Trail should be created */
--  if (exists(select * from #ImportASNAuditInfo))
--    begin
--      /* Update comment. The comment will be used later to handle updating audit id values */
--      insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId, Comment)
--        select EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId,
--               dbo.fn_Messages_BuildDescription(ActivityType, 'LPN', EntityKey, 'SKU', null , null, null , null, null, null, null, null, null)
--        from #ImportASNAuditInfo IALH

--      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
--    end

  /* Get the Receipts to PreProcess */
  insert into @ttReceiptsToPreProcess(EntityId, EntityKey)
    select distinct ReceiptId, ReceiptNumber
    from @ttImportASNLPNDetails
    where ReceiptId is not null;

  /* Preprocess receipts in back ground */
  exec pr_Entities_ExecuteInBackGround 'ReceiptHdr', @Operation = 'Preprocess_Import_ASNLPNDetail', @EntityKeysTable = @ttReceiptsToPreProcess, @BusinessUnit = @BusinessUnit;

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttASNLPNDetailValidations;

end /* pr_Imports_ASNLPNDetails */

Go
