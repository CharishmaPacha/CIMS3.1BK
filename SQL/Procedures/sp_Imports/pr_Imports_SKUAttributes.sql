/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/10  MS      pr_Imports_SKUAttributes_Update,pr_Imports_SKUs : Changes to update SKUDimentions (JL-76)
  2019/03/12  RIA     Added pr_Imports_SKUAttributes, pr_Imports_SKUAttributes_Insert, pr_Imports_SKUAttributes_Update, pr_Imports_SKUAttributes_Delete (HPI-2485)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUAttributes') is not null
  drop Procedure pr_Imports_SKUAttributes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUAttributes:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUAttributes
  (@xmlData           Xml             = null,
   @documentHandle    TInteger        = null,
   @InterfaceLogId    TRecordId       = null)
as
  declare @vBusinessUnit       TBusinessUnit,
          @vReturnCode         TInteger,
          @ttSKUs              TEntityKeysTable,
          @vParentLogId        TRecordId;

  /* Table vars for SKUs, SKUValidations and AuditTrail  */
  declare @ttSKUAttrImport   TSKUImportType;
  declare @ttSKUValidations  TImportValidationType;
  declare @ttAuditInfo       TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Create an #ImportSKUAttrInfo temp table if it does not exist */
  if object_id('tempdb..#ImportSKUAttrAuditInfo') is null
    select * into #ImportSKUAttrAuditInfo
    from @ttAuditInfo;

  if (@xmldata is not null) and (@InterfaceLogId is null)
    begin
      select @InterfaceLogId = Record.Col.value('ParentLogId[1]',     'TRecordId')
      from @xmlData.nodes('//msg/msgHeader') as Record(Col);
    end

  /* Populate the temp table */
  if (@documentHandle is not null)
    begin
      /* insert into SKUImports Table from the xmldata */
      insert into @ttSKUAttrImport (
        InputXML,
        RecordType,
        RecordAction,
        SKU,
        InnerPacksPerLPN,
        UnitsPerInnerPack,
        UnitsPerLPN,
        InnerPackWeight,
        InnerPackLength,
        InnerPackWidth,
        InnerPackHeight,
        InnerPackVolume,
        UnitWeight,
        UnitLength,
        UnitWidth,
        UnitHeight,
        UnitVolume,
        PalletTie,
        PalletHigh,
        ShipUoM,
        ShipPack,
        SourceSystem,
        BusinessUnit)
      select
        *
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="SKUA"]', 2) -- condition forces to read only Records with RecordType SKU
      with (InputXML           nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType         TRecordType,
            Action             TAction,
            SKU                TSKU,
            InnerPacksPerLPN   TInteger,
            UnitsPerInnerPack  TInteger,
            UnitsPerLPN        TInteger,
            InnerPackWeight    TFloat,
            InnerPackLength    TFloat,
            InnerPackWidth     TFloat,
            InnerPackHeight    TFloat,
            InnerPackVolume    TFloat,
            UnitWeight         TFloat,
            UnitLength         TFloat,
            UnitWidth          TFloat,
            UnitHeight         TFloat,
            UnitVolume         TFloat,
            PalletTie          TInteger,
            PalletHigh         TInteger,
            ShipUoM            TFlags,
            ShipPack           TInteger,
            SourceSystem       TName,
            BusinessUnit       TBusinessUnit);
    end

  select Top 1
         @vBusinessUnit = BusinessUnit
  from @ttSKUAttrImport;

  /* Update SKUId of all the records in SKUImports table by using join on SKUs table
     This will be useful for validations, the inserts/updates/deletes */
  update @ttSKUAttrImport
  set SKUId        = S.SKUId,
      SourceSystem = coalesce(nullif(SI.SourceSystem, ''), 'HOST'),
      RecordAction = case when (SI.RecordAction = 'I') then replace(SI.RecordAction, 'I', 'U') else SI.RecordAction end
  from SKUS S
       join @ttSKUAttrImport SI on (S.SKU = SI.SKU) and (S.BusinessUnit = SI.BusinessUnit)
       left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'Ownership', 'Import' /* Operation */,  @vBusinessUnit) MO on (MO.SourceValue   = SI.Ownership);

  /* pr_Imports_ValidateSKU procedure  will return the result set of validation, captured in SKUValidations table */
  Insert @ttSKUValidations
    exec pr_Imports_ValidateSKU @ttSKUAttrImport;

  /*--------------------------------------------------------------------------*/
  /* Insert SKU Attributes - Not supported */
  -- if (exists (select * from @ttSKUAttrImport where RecordAction = 'I' /* Insert */))
  --   exec pr_Imports_SKUAttributes_Insert @ttSKUAttrImport;

  /*--------------------------------------------------------------------------*/
  /* Update SKU Attributes */
  if (exists (select * from @ttSKUAttrImport where RecordAction = 'U' /* Update */))
    exec pr_Imports_SKUAttributes_Update @ttSKUAttrImport;

  /*--------------------------------------------------------------------------*/
  /* Delete SKU Attributes - Not supported */
  --if (exists (select * from ttSKUAttrImport where RecordAction = 'D' /* Delete */))
  --  exec pr_Imports_SKUAttributes_Delete @ttSKUAttrImport;

  /* Verify if Audit Trail should be updated  */
  if (exists (select * from #ImportSKUAttrAuditInfo))
    begin
      /* update comment . The comment will be used later to handle updating audit id values */
      insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId, Comment)
        select EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId,
                dbo.fn_Messages_BuildDescription(ActivityType, 'SKU', EntityKey, null, null, null, null, null, null, null, null, null, null)
        from #ImportSKUAttrAuditInfo

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttSKUValidations;

  /* if the Action is inserting or updating then we need to pre-process the SKU */
 if (exists (select * from @ttSKUAttrImport where (RecordAction in ('I', 'U'))))
    begin
    /* Chances of Error : When duplicate records w.r.t SKU are sent
       Future Change    : Control value given by the client should be included
                          to either out or select only distinct values */
      insert into @ttSKUs
        select distinct SKUId, SKU
        from @ttSKUAttrImport
        where (RecordAction in ('I', 'U')) and
              (BusinessUnit = @vBusinessUnit);

      exec pr_SKUs_PreProcess @ttSKUs, null /* SKUId */, @vBusinessUnit;
    end
end /* pr_Imports_SKUAttributes */

Go
