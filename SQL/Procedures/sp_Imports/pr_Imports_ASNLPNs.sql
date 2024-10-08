/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/22  MS      pr_Imports_ReceiptDetails, pr_Imports_OrderDetail, pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNs, pr_Imports_ASNLPNHdr_Insert, pr_Imports_ASNLPNHdr_Update
  2020/03/02  MS      pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNs: Changes to pass BU to caller (JL-130)
  2020/01/16  VS      pr_Imports_ASNLPNs: Made changes to Import the HostReceiptLine (CID-1233)
  2019/01/25  HB      pr_Imports_ASNLPNHeaders & pr_Imports_ASNLPNDetails : Renamed pr_Imports_ASNLPNs to pr_Imports_ASNLPNHeaders and pr_Imports_ValidateASNLPN
  2018/09/14  TK      pr_Imports_InventoryAdjustments, pr_Imports_ASNLPNs & pr_Imports_ASNLPNDetails:
  2015/10/14  TK      pr_Imports_ASNLPNs & pr_Imports_ASNLPNDetails: Bug fix (ACME-370)
  2015/04/28  TK      pr_Imports_ASNLPNs: Generate Logical LPN if they try to import Picklane LPNs.
  2014/08/18  TK      pr_Imports_ASNLPNs: Enhanced to import FIFODate and Location.
                      pr_Imports_ASNLPNs : Fixed issue with default date for ExpiryDate
                      pr_Imports_ASNLPNs:Added ExpiryDate.
                      pr_Imports_ASNLPNs: Default Status should be InTransit
  2011/08/02  YA/VM   pr_Imports_ASNLPNs:
                      Procedure names 'pr_Imports_ASNLPNs' & 'pr_Imports_ASNLPNDetails'
                      pr_Imports_ASNLPNs : Added UDF1 - UDF5 and ReceivedDate, DestWarehouse,
  2011/02/24  PK      pr_Imports_ASNLPNs, pr_Imports_ASNLPNDetails : Added Default values for fields in temp tabel.
  2011/02/07  PK      Created pr_Imports_Vendors, pr_Imports_ASNLPNs, pr_Imports_ASNLPNDetails,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNs') is not null
  drop Procedure pr_Imports_ASNLPNs;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_ASNLPNs: procedure to import ASN LPN Headers and Details
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNs
  (@xmlData           Xml             = null,
   @documentHandle    TInteger        = null,
   @InterfaceLogId    TRecordId       = null,
   @Action            TFlag           = null,
   @LPN               TLPN            = null,
   @LPNType           TTypeCode       = null,
   @LPNWeight         TFloat          = null,
   @SKU               TSKU            = null,
   @SKU1              TSKU            = null,
   @SKU2              TSKU            = null,
   @SKU3              TSKU            = null,
   @SKU4              TSKU            = null,
   @SKU5              TSKU            = null,
   @InnerPacks        TInnerPacks     = null,
   @Quantity          TQuantity       = null,
   @Pallet            TPallet         = null,
   @Ownership         TOwnership      = null,
   @InventoryClass1   TInventoryClass = null,
   @InventoryClass2   TInventoryClass = null,
   @InventoryClass3   TInventoryClass = null,
   @ASNCase           TASNCase        = null,
   @ReceiptNumber     TReceiptNumber  = null,
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
   @LPND_UDF1         TUDF            = null,
   @LPND_UDF2         TUDF            = null,
   @LPND_UDF3         TUDF            = null,
   @LPND_UDF4         TUDF            = null,
   @LPND_UDF5         TUDF            = null,
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
  declare @ttImportASNLPNs            TASNLPNImportType,
          @ttASNLPNValidations        TImportValidationType,
          @ttReceiptsToPreProcess     TRecountKeysTable,
          @ttLPNsToRecount            TRecountKeysTable,
          @ttAuditInfo                TAuditTrailInfo;

begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#ImportASNAuditInfo') is null
    select * into #ImportASNAuditInfo
    from @ttAuditInfo;

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
      insert into @ttImportASNLPNs (
        InputXML,
        RecordType,
        RecordAction,
        LPN,
        LPNType,
        ASNCase,
        LPNWeight,
        SKU,
        SKU1,
        SKU2,
        SKU3,
        SKU4,
        SKU5,
        InnerPacks,
        Quantity,
        Ownership,
        InventoryClass1,
        InventoryClass2,
        InventoryClass3,
        ReceiptNumber,
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
        HostRecId)
      select
        *
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="ASNL"]', 2) -- condition forces to read only Records with RecordType ASNLPN
      with (InputXML           nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType         TRecordType,
            Action             TFlag,
            LPN                TLPN,
            LPNType            TTypeCode,
            ASNCase            TASNCase,
            LPNWeight          TFloat,
            SKU                TSKU,
            SKU1               TSKU,
            SKU2               TSKU,
            SKU3               TSKU,
            SKU4               TSKU,
            SKU5               TSKU,
            InnerPacks         TInnerPacks,
            Quantity           TQuantity,
            Ownership          TOwnership,
            InventoryClass1    TInventoryClass,
            InventoryClass2    TInventoryClass,
            InventoryClass3    TInventoryClass,
            ReceiptNumber      TReceiptNumber,
            CoO                TCoO,
            ReceivedDate       TDateTime,
            ExpiryDate         TDateTime,
            Warehouse          TWarehouse,
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
      insert into @ttImportASNLPNs(
        RecordAction, RecordType,
        LPN, LPNType, Ownership,
        InventoryClass1, InventoryClass2, InventoryClass3,
        SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
        InnerPacks, Quantity,
        ReceiptNumber,
        ASNCase, CoO, ReceivedDate, ExpiryDate, DestWarehouse, Location,
        LPN_UDF1, LPN_UDF2, LPN_UDF3, LPN_UDF4, LPN_UDF5, LPN_UDF6, LPN_UDF7, LPN_UDF8, LPN_UDF9, LPN_UDF10,
        LPND_UDF1, LPND_UDF2, LPND_UDF3, LPND_UDF4, LPND_UDF5,
        BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action,
        'ASNLPN',
        @LPN,
        @LPNType,
        @Ownership,
        @InventoryClass1,
        @InventoryClass2,
        @InventoryClass3,
        @SKU,
        @SKU1,
        @SKU2,
        @SKU3,
        @SKU4,
        @SKU5,
        @InnerPacks,
        @Quantity,
        nullif(@ReceiptNumber, ''),
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
        @LPND_UDF1,
        @LPND_UDF2,
        @LPND_UDF3,
        @LPND_UDF4,
        @LPND_UDF5,
        @BusinessUnit,
        @CreatedDate,
        @ModifiedDate,
        @CreatedBy,
        @ModifiedBy,
        @HostRecId
    end

  /* Update the temp table with RecordIds */
  update ALH
  set ALH.ReceiptId       = RH.ReceiptId,
      ALH.PalletId        = P.PalletId,
      ALH.LPNId           = L.LPNId,
      ALH.LPNType         = coalesce(nullif(ALH.LPNType, ''), 'C'),
      ALH.Status          = L.Status,
      ALH.OnhandStatus    = 'U' /* OnhandStatus - As it cant be null we are updating it directly here with default value */,
      @BusinessUnit       = ALH.BusinessUnit
  from @ttImportASNLPNs ALH
    left outer join ReceiptHeaders RH on RH.ReceiptNumber = ALH.ReceiptNumber
    left outer join Pallets P on ALH.Pallet = P.Pallet and ALH.BusinessUnit = P.BusinessUnit
    left outer join LPNs L on ALH.LPN = L.LPN and ALH.BusinessUnit = L.BusinessUnit

  /* Get the valid SKU information */
  update ALH
  set SKUId     = S.SKUId,
      SKU       = S.SKU
  from @ttImportASNLPNs ALH
    /* As we do not know user passed the either UPC or SKU, or SKU attributes */
    cross apply dbo.fn_SKUs_GetSKUs(ALH.SKU, ALH.BusinessUnit, ALH.SKU1, ALH.SKU2, ALH.SKU3, ALH.SKU4, ALH.SKU5) S

  /* Update the LPN line information if already exists */
  update ALH
  set LPNDetailId     = LD.LPNDetailId,
      UnitsPerPackage = coalesce(LD.UnitsPerPackage, S.UnitsPerInnerPack)
  from @ttImportASNLPNs ALH
    left outer join LPNDetails LD on LD.LPNId = ALH.LPNId and LD.SKUId = ALH.SKUId
    left outer join SKUS S on S.SKUId = ALH.SKUId

  /* Do the header validations */
  insert @ttASNLPNValidations
    exec pr_Imports_ValidateASNLPNHeaders @ttImportASNLPNs;

  /* Set RecordAction for Headers Records */
  update @ttImportASNLPNs
  set RecordAction = ALHV.RecordAction
  from @ttImportASNLPNs ALHI
    join @ttASNLPNValidations ALHV on (ALHV.RecordId = ALHI.RecordId);

  /*--------------------------------------------------------------------------*/
  /* Insert the ASN LPN Details or Picklane LPNs */
  if (exists (select * from @ttImportASNLPNs where RecordAction = 'I' /* Insert */))
    exec pr_Imports_ASNLPNHdr_Insert @ttImportASNLPNs;

  if (exists (select * from @ttImportASNLPNs where RecordAction = 'L' /* Logical */))
    exec pr_Imports_ASNLPNHdr_GeneratePicklane @ttImportASNLPNs;
  /*--------------------------------------------------------------------------*/

  /* Get the LPN information If LPN is inserted above */
  update ALHV
  set LPNId  = L.LPNId,
      Status = L.Status
  from @ttImportASNLPNs ALHV
    join LPNs L on (ALHV.LPN = L.LPN) and (ALHV.BusinessUnit = L.BusinessUnit);

  /* Do the detail validations */
  delete @ttASNLPNValidations;
  insert @ttASNLPNValidations
    exec pr_Imports_ValidateASNLPNDetails @ttImportASNLPNs;

  /* Set RecordAction for Headers Records */
  update ALDI
  set RecordAction = ALHV.RecordAction
  from @ttImportASNLPNs ALDI
    join @ttASNLPNValidations ALHV on (ALHV.RecordId = ALDI.RecordId);

  /*--------------------------------------------------------------------------*/
  /* Insert LPN Details */
  if (exists (select * from @ttImportASNLPNs where RecordAction = 'I' /* Insert */ and LPNType = 'C'/* Carton */))
    exec pr_Imports_ASNLPNDtl_Insert @ttImportASNLPNs;

  /*--------------------------------------------------------------------------*/
  /* Update the ASN LPN Header and Details */
  if (exists (select * from @ttImportASNLPNs where RecordAction = 'U' /* Update */))
    begin
      exec pr_Imports_ASNLPNHdr_Update @ttImportASNLPNs;
      exec pr_Imports_ASNLPNDtl_Update @ttImportASNLPNs;
    end

  /*--------------------------------------------------------------------------*/
  /* Delete the ASN LPN Header; it also deletes the details */
  if (exists (select * from @ttImportASNLPNs where RecordAction = 'D' /* Delete */))
    exec pr_Imports_ASNLPNHdr_Delete @ttImportASNLPNs;

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

  insert into @ttLPNsToRecount (EntityType, EntityId, EntityKey)
    select distinct 'LPN', LPNId, LPN
    from @ttImportASNLPNs
    where RecordAction not in ('E', 'D' /* Error, Delete */) and
          ReceiptId is not null;

  exec pr_Entities_RequestRecalcCounts 'LPN', @RecalcOption = 'PCS', @ProcId = @@ProcId,
                                        @BusinessUnit     = @BusinessUnit,
                                        @RecountKeysTable = @ttLPNsToRecount;

  /* Get the Receipts to PreProcess */
  insert into @ttReceiptsToPreProcess (EntityId, EntityKey)
    select distinct ReceiptId, ReceiptNumber
    from @ttImportASNLPNs
    where ReceiptId is not null;

  /* Preprocess receipts in back ground */
  exec pr_Entities_ExecuteInBackGround 'ReceiptHdr', @Operation = 'Preprocess_Import_ASNLPN', @BusinessUnit = @BusinessUnit, @EntityKeysTable = @ttReceiptsToPreProcess;

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttASNLPNValidations;

end /* pr_Imports_ASNLPNs */

Go
