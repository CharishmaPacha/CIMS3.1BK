/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/19  MS      pr_Imports_ASNLPNHeaders: Bug fix in AuditTrail Insert (JL-312)
  2020/10/15  MS      pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNHdr_Delete, pr_Imports_ASNLPNDetails, pr_Imports_CIMSDE_ImportData
  2020/04/22  MS      pr_Imports_ReceiptDetails, pr_Imports_OrderDetail, pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNs, pr_Imports_ASNLPNHdr_Insert, pr_Imports_ASNLPNHdr_Update
  2020/03/02  MS      pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNs: Changes to pass BU to caller (JL-130)
  pr_Imports_ASNLPNHeaders, pr_Imports_ASNs_AddOrUpdateReceipts: Corrections migrated from CID (JL-93)
  2019/01/25  HB      pr_Imports_ASNLPNHeaders & pr_Imports_ASNLPNDetails : Renamed pr_Imports_ASNLPNs to pr_Imports_ASNLPNHeaders and pr_Imports_ValidateASNLPN
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNHeaders') is not null
  drop Procedure pr_Imports_ASNLPNHeaders;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_ASNLPNHeaders
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNHeaders
  (@xmlData           Xml             = null,
   @documentHandle    TInteger        = null,
   @InterfaceLogId    TRecordId       = null,
   @Action            TFlag           = null,
   @LPN               TLPN            = null,
   @LPNType           TTypeCode       = null,
   @LPNWeight         TFloat          = null,
   @Pallet            TPallet         = null,
   @Ownership         TOwnership      = null,
   @InventoryClass1   TInventoryClass = null,
   @InventoryClass2   TInventoryClass = null,
   @InventoryClass3   TInventoryClass = null,
   @ASNCase           TASNCase        = null,
   @ReceiptNumber     TReceiptNumber  = null,
   @HostNumLines      TCount          = null,
   @CountryOfOrigin   TCoO            = null,
   @ReceivedDate      TDateTime       = null,
   @ExpiryDate        TDateTime       = null,
   @DestWarehouse     TWarehouse      = null,
   @Location          TLocation       = null,   /* Randomly choosen order of the fields needs to be updated as per latest interface document*/
   @LPN_UDF1          TUDF            = null,
   @LPN_UDF2          TUDF            = null,   /* Field FIFODate */
   @LPN_UDF3          TUDF            = null,
   @LPN_UDF4          TUDF            = null,
   @LPN_UDF5          TUDF            = null,
   @LPN_UDF6          TUDF            = null,
   @LPN_UDF7          TUDF            = null,
   @LPN_UDF8          TUDF            = null,
   @LPN_UDF9          TUDF            = null,
   @LPN_UDF10         TUDF            = null,
   @BusinessUnit      TBusinessUnit   = null,
   @CreatedDate       TDateTime       = null,
   @ModifiedDate      TDateTime       = null,
   @CreatedBy         TUserId         = null,
   @ModifiedBy        TUserId         = null,
   @HostRecId         TRecordId       = null
  )
as
  declare @vLPNId          TRecordId,
          @vReceiptId      TRecordId,
          @vLocationId     TRecordId,
          @vPalletId       TRecordId,
          @vReturnCode     TInteger,
          @vLPNStatus      TStatus,
          @vRecordId       TRecordId;

          /* Table variables for ASNLPNHeaders */
  declare @ttImportASNLPNHeaders      TASNLPNImportType,
          @ttASNLPNHeaderValidations  TImportValidationType,
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

  if (@xmldata is not null) and (@InterfaceLogId is null)
    begin
      select @InterfaceLogId = Record.Col.value('ParentLogId[1]',  'TRecordId')
      from @xmlData.nodes('//msg/msgHeader') as Record(Col);
    end

  /* Get control value */
  select @vLPNStatus = dbo.fn_Controls_GetAsString('IMPORT_ASNLD', 'LPNStatus', 'R' /* Received */, @BusinessUnit, '' /* UserId */) ;

  /* Populate the temp table */
  if (@documentHandle is not null)
    begin
      insert into @ttImportASNLPNHeaders (
        InputXML,
        RecordType,
        RecordAction,
        LPN,
        LPNType,
        ASNCase,
        LPNWeight,
        Ownership,
        InventoryClass1,
        InventoryClass2,
        InventoryClass3,
        ReceiptNumber,
        HostNumLines,
        CoO,
        ReceivedDate,
        ExpiryDate,
        DestWarehouse,
        Location,
        LPN_UDF1,
        LPN_UDF2,
        LPN_UDF3,
        LPN_UDF4,
        LPN_UDF5,
        LPN_UDF6,
        LPN_UDF7,
        LPN_UDF8,
        LPN_UDF9,
        LPN_UDF10,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId)
      select
        *
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="ASNLH"]', 2) -- condition forces to read only Records with RecordType ASNLH
      with (InputXML           nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType         TRecordType,
            Action             TFlag,
            LPN                TLPN,
            LPNType            TTypeCode,
            ASNCase            TASNCase,
            LPNWeight          TFloat,
            Ownership          TOwnership,
            InventoryClass1    TInventoryClass,
            InventoryClass2    TInventoryClass,
            InventoryClass3    TInventoryClass,
            ReceiptNumber      TReceiptNumber,
            HostNumLines       TCount,
            CoO                TCoO,
            ReceivedDate       TDateTime,
            ExpiryDate         TDateTime,
            DestWarehouse      TWarehouse,
            Location           TLocation,
            LPN_UDF1           TUDF,
            LPN_UDF2           TUDF,
            LPN_UDF3           TUDF,
            LPN_UDF4           TUDF,
            LPN_UDF5           TUDF,
            LPN_UDF6           TUDF,
            LPN_UDF7           TUDF,
            LPN_UDF8           TUDF,
            LPN_UDF9           TUDF,
            LPN_UDF10          TUDF,
            BusinessUnit       TBusinessUnit,
            CreatedDate        TDateTime                'CreatedDate/text()',
            ModifiedDate       TDateTime                'ModifiedDate/text()',
            CreatedBy          TUserId,
            ModifiedBy         TUserId,
            RecordId           TRecordId);
    end
  else
    begin
      insert into @ttImportASNLPNHeaders(
        RecordAction, RecordType,
        LPN, LPNType, Ownership,
        InventoryClass1, InventoryClass2, InventoryClass3,
        ReceiptNumber, HostNumLines,
        ASNCase, CoO, ReceivedDate, ExpiryDate, DestWarehouse, Location,
        LPN_UDF1, LPN_UDF2, LPN_UDF3, LPN_UDF4, LPN_UDF5, LPN_UDF6, LPN_UDF7, LPN_UDF8, LPN_UDF9, LPN_UDF10,
        BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action,
        'ASNLPNH',
        @LPN,
        @LPNType,
        @Ownership,
        @InventoryClass1,
        @InventoryClass2,
        @InventoryClass3,
        nullif(@ReceiptNumber, ''),
        @HostNumLines,
        @ASNCase,
        @CountryOfOrigin,
        @ReceivedDate,
        @ExpiryDate,
        @DestWarehouse,
        @Location,
        @LPN_UDF1,
        @LPN_UDF2,
        @LPN_UDF3,
        @LPN_UDF4,
        @LPN_UDF5,
        @LPN_UDF6,
        @LPN_UDF7,
        @LPN_UDF8,
        @LPN_UDF9,
        @LPN_UDF10,
        @BusinessUnit,
        @CreatedDate,
        @ModifiedDate,
        @CreatedBy,
        @ModifiedBy,
        @HostRecId
    end

  /* Updating temp table */
  update ALH
  set ALH.ReceiptId       = RH.ReceiptId,
      ALH.PalletId        = P.PalletId,
      ALH.LPNId           = L.LPNId,
      ALH.LPNType         = coalesce(nullif(ALH.LPNType, ''), 'C'),
      ALH.OnhandStatus    = 'U', /* OnhandStatus - As it cant be null we are updating it directly here with default value */
      @BusinessUnit       = ALH.BusinessUnit
  from @ttImportASNLPNHeaders ALH
    left outer join ReceiptHeaders RH on RH.ReceiptNumber = ALH.ReceiptNumber and RH.BusinessUnit = ALH.BusinessUnit
    left outer join Pallets P on ALH.Pallet = P.Pallet and ALH.BusinessUnit = P.BusinessUnit
    left outer join LPNs L on ALH.LPN = L.LPN and ALH.BusinessUnit = L.BusinessUnit

  /* Validate the records */
  insert @ttASNLPNHeaderValidations
    exec pr_Imports_ValidateASNLPNHeaders @ttImportASNLPNHeaders;

  /* Set RecordAction for OrderHeader Records  */
  update @ttImportASNLPNHeaders
  set RecordAction = ALHV.RecordAction
  from @ttImportASNLPNHeaders ALHI
    join @ttASNLPNHeaderValidations ALHV on (ALHV.RecordId = ALHI.RecordId);

  /*--------------------------------------------------------------------------*/
  /* Insert update or Delete based on Action */
  if (exists (select * from @ttImportASNLPNHeaders where RecordAction = 'I' /* Insert */))
    exec pr_Imports_ASNLPNHdr_Insert @ttImportASNLPNHeaders;

  if (exists (select * from @ttImportASNLPNHeaders where RecordAction = 'U' /* Update */))
    exec pr_Imports_ASNLPNHdr_Update @ttImportASNLPNHeaders;

  if (exists (select * from @ttImportASNLPNHeaders where RecordAction = 'D' /* Delete */))
    exec pr_Imports_ASNLPNHdr_Delete @ttImportASNLPNHeaders;

  if (exists (select * from @ttImportASNLPNHeaders where RecordAction = 'L' /* Logical */))
    exec pr_Imports_ASNLPNHdr_GeneratePicklane @ttImportASNLPNHeaders;
  /*--------------------------------------------------------------------------*/

  /* Verify if Audit Trail should be created */
  if (exists(select * from #ImportASNAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId, Comment)
        select EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId,
               dbo.fn_Messages_BuildDescription(ActivityType, EntityType, EntityKey /* LPN */, null, null , null, null , null, null, null, null, null, null)
        from #ImportASNAuditInfo IALH

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Get the Receipts to PreProcess */
  insert into @ttReceiptsToPreProcess(EntityId, EntityKey)
    select distinct ReceiptId, ReceiptNumber
    from @ttImportASNLPNHeaders
    where ReceiptId is not null;

  /* Preprocess receipts in back ground */
  exec pr_Entities_ExecuteInBackGround 'ReceiptHdr', @Operation = 'Preprocess_Import_ASNLPN', @BusinessUnit = @BusinessUnit, @EntityKeysTable = @ttReceiptsToPreProcess;

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttASNLPNHeaderValidations;

end /* pr_Imports_ASNLPNHeaders */

Go
