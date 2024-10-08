/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/16  MS      pr_Imports_SKUPrePacks: Changes to insert or Update MasterSKU & ComponentSKU (JL-261)
                      pr_Imports_ImportRecords, pr_Imports_SKUPrePacks: Changes ported from JL prod (JL-259)
  2020/04/06  TK      pr_Imports_SKUPrePacks: Preprocess SKUs once the SKU PrePack components are imported (HA-124)
  2019/04/05  RIA     pr_Imports_SKUPrePacks: Considered HostRecordId to process and update the exchange status correctly (S2GCA-544)
  2014/11/19  SK      pr_Imports_SKUPrePacks, pr_Impors_ValidateSKUPrePacks: Enhancements to process
  2013/07/30  PK      pr_Imports_SKUPrePacks: Added BusinessUnit.
  2012/03/27  YA      Created pr_Imports_SKUPrePacks, pr_Imports_ValidateSKUPrePacks.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUPrePacks') is not null
  drop Procedure pr_Imports_SKUPrePacks;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUPrePacks:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUPrePacks
  (@xmlData           Xml,
   @Action            TFlag           = null,
   @MasterSKU         TSKU            = null,
   @MasterSKU1        TSKU            = null,
   @MasterSKU2        TSKU            = null,
   @MasterSKU3        TSKU            = null,
   @MasterSKU4        TSKU            = null,
   @MasterSKU5        TSKU            = null,
   @ComponentSKU      TSKU            = null,
   @ComponentSKU1     TSKU            = null,
   @ComponentSKU2     TSKU            = null,
   @ComponentSKU3     TSKU            = null,
   @ComponentSKU4     TSKU            = null,
   @ComponentSKU5     TSKU            = null,
   @ComponentQty      TQuantity       = null,
   @Status            TStatus         = null,
   @SortSeq           TSortSeq        = null,
   @BusinessUnit      TBusinessUnit   = null,
   @CreatedDate       TDateTime       = null,
   @ModifiedDate      TDateTime       = null,
   @CreatedBy         TUserId         = null,
   @ModifiedBy        TUserId         = null,
   @HostRecId         TRecordId       = null)
as
  declare @vReturnCode              TInteger,
          @ComponentSKUId           TRecordId,
          @MasterSKUId              TRecordId,
          @vParentLogId             TRecordId,
          @vBusinessUnit            TBusinessUnit;

          /* Table variables for SKUPrepacks, SKUPrepacksValidations and AuditTrail */
  declare @ttSKUPrepacks            TSKUPrepacksImportType,
          @ttSKUsToPreprocess       TEntityKeysTable,
          @ttSKUPrepacksValidation  TSKUPrepacksImportValidation,
          @ttAuditInfo              TAuditTrailInfo,
          @ttValidationTable        TImportValidationType;
begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  if (@xmldata is not null)
    select @vParentLogId = Record.Col.value('ParentLogId[1]','TRecordId')
    from @xmlData.nodes('//msg/msgHeader') as Record(Col);

  /* Populate the SKUPrepack table type */
  if (@xmlData is not null)
    begin
      insert into @ttSKUPrepacks (
        InputXML,
        RecordAction,
        MasterSKU,
        ComponentSKU,
        ComponentQty,
        Status,
        SortSeq,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId)
      select
        convert(nvarchar(max), Record.Col.query('.')),
        Record.Col.value('Action[1]', 'TFlag'),
        Record.Col.value('MasterSKU[1]', 'TSKU'),
        Record.Col.value('ComponentSKU[1]', 'TSKU'),
        Record.Col.value('ComponentQty[1]', 'TQuantity'),
        Record.Col.value('Status[1]', 'TStatus'),
        Record.Col.value('SortSeq[1]', 'TSortSeq'),
        Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
        nullif(Record.Col.value('CreatedDate[1]', 'TDateTime'), ''),
        nullif(Record.Col.value('ModifiedDate[1]', 'TDateTime'), ''),
        Record.Col.value('CreatedBy[1]', 'TUserId'),
        Record.Col.value('ModifiedBy[1]', 'TUserId'),
        Record.Col.value('RecordId[1]', 'TRecordId')
      from @xmlData.nodes('//msg/msgBody/Record') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @xmlData = null ) )
    end
  else
    begin
      insert into @ttSKUPrepacks (
        RecordAction, MasterSKU, ComponentSKU,
        MasterSKUId, ComponentSKUId,
        ComponentQty, Status, BusinessUnit,
        CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action, @MasterSKU, @ComponentSKU,
        @MasterSKUId, @ComponentSKUId,
        @ComponentQty, @Status, @BusinessUnit,
        @CreatedDate, @ModifiedDate, @CreatedBy, @ModifiedBy, @HostRecId;
    end

  /* Validate and Fetch MasterSKUID and ComponentSKUId */
  insert @ttSKUPrepacksValidation
    exec pr_Imports_ValidateSKUPrepacks @ttSKUPrepacks

  /* Set Record Action for Prepack Records */
  update S
  set S.RecordAction   = SV.RecordAction,
      S.MasterSKU      = SV.MasterSKU,
      S.MasterSKUId    = SV.MasterSKUId,
      S.ComponentSKU   = SV.ComponentSKU,
      S.ComponentSKUId = SV.ComponentSKUId,
      S.SKUPrePackId   = SV.SKUPrePackId
  from @ttSKUPrepacks S
    join @ttSKUPrepacksValidation SV on (SV.RecordId = S.RecordId)

  /* Set Validation tabular values for Logging details */
  insert into @ttValidationTable(RecordId, EntityId, EntityKey, RecordType, KeyData, InputXML,
                                 BusinessUnit, RecordAction, ResultXML, HostRecId)
    select RecordId, SKUPrePackId, right(MasterSKU + ' - ' + ComponentSKU, 50),
          'SMP', right(MasterSKU + ' - ' + ComponentSKU, 50), convert(nvarchar(max), InputXML), BusinessUnit, RecordAction,
             convert(nvarchar(max), ResultXML), HostRecId
    from @ttSKUPrepacksValidation;

  /* Insert update or Delete based on Action */
  if (exists(select * from @ttSKUPrepacks where (RecordAction = 'I' /* Insert */)))
    insert into SKUPrePacks (
      MasterSKUId,
      MasterSKU,
      ComponentSKUId,
      ComponentSKU,
      ComponentQty,
      Status,
      SortSeq,
      BusinessUnit,
      CreatedDate,
      CreatedBy)
    select
      MasterSKUId,
      MasterSKU,
      ComponentSKUId,
      ComponentSKU,
      ComponentQty,
      coalesce(nullif(ltrim(rtrim(Status)), ''), 'A' /* Active */),
      SortSeq,
      BusinessUnit,
      coalesce(CreatedDate, current_timestamp),
      coalesce(CreatedBy, System_User)
    from @ttSKUPrepacks
    where ( RecordAction = 'I' /* Insert */)
    order by HostRecId;

  if (exists(select * from @ttSKUPrepacks where (RecordAction = 'U' /* Update */)))
    update S1
    set
      S1.ComponentQty    = S2.ComponentQty,
      S1.Status          = coalesce(nullif(ltrim(rtrim(S2.Status)), ''), 'A' /* Active */),
      S1.SortSeq         = S2.SortSeq,
      S1.BusinessUnit    = S2.BusinessUnit,
      S1.ModifiedDate    = coalesce(S2.ModifiedDate, current_timestamp),
      S1.ModifiedBy      = coalesce(S2.ModifiedBy, System_User)
      output 'SMP', Inserted.SKUPrepackId, right(S2.MasterSKU + ' - ' + S2.ComponentSKU,50),
             null /* EntityDetails */, 'AT_SKUPrePackModified' /* @SKUPrepacksValues */, S2.RecordAction /* Action */,
             null /* Comment */, Inserted.BusinessUnit, Inserted.ModifiedBy, Inserted.SKUPrepackId /* UDF1 */,
             null /* UDF2 */, null /* UDF3 */, null /* UDF4 */, null /* UDF5 */, null /* Audit Id */ into @ttAuditInfo
    from SKUPrePacks S1
      join @ttSKUPrepacks S2 on (S1.MasterSKUId    = S2.MasterSKUId) and
                                (S1.ComponentSKUId = S2.ComponentSKUId)
    where (S2.RecordAction = 'U' /* Update */);

  if (exists(select * from @ttSKUPrepacks where (RecordAction = 'D' /* Delete */)))
    begin
      /* Capture audit info */
      insert into @ttAuditInfo
      select 'SMP', SKUPrepackId, MasterSKU + ' - ' + ComponentSKU,
             null /* EntityDetails */, 'AT_SKUPrePackDeleted' /* Audit Activity */, RecordAction /* Action */, null /* Comment */,
             BusinessUnit, ModifiedBy, SKUPrepackId /* UDF1 */, null /* UDF2 */, null /* UDF3 */, null /* UDF4 */, null /* UDF5 */, null /* Audit Id */
      from @ttSKUPrepacks
      where RecordAction = 'D';

      update S1
      set S1.Status = 'I' /* Inactive */
      from SKUPrePacks S1
        join @ttSKUPrepacks S2 on (S1.MasterSKUId    = S2.MasterSKUId) and
                                  (S1.ComponentSKUId = S2.ComponentSKUId) and
                                  (S1.BusinessUnit   = S2.BusinessUnit)
      where (S2.RecordAction = 'D');
    end

    /* Verify if Audit Trail should be updated */
  if (exists(select * from @ttAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      update @ttAuditInfo
      set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'MSKU-CSKU', EntityKey /* Master SKU + Component SKU */ , null, null , null, null , null, null, null, null, null, null);

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @vParentLogId, 'Import', null, @ttValidationTable;

  /* if the Action is inserting or updating then we need to pre-process the SKU */
  if (exists (select * from @ttSKUPrepacks where (RecordAction in ('I', 'U'))))
    begin
      /* We need to preprocess SKUs when the SKU Prepack components are imported
         so that necessary updates are done */
      insert into @ttSKUsToPreprocess(EntityId, EntityKey)
        select distinct MasterSKUId, MasterSKU
        from @ttSKUPrepacks
        where (RecordAction in ('I', 'U'));

      select top 1 @vBusinessUnit = BusinessUnit
      from @ttSKUPrepacks
      where (RecordAction in ('I', 'U'));

      exec pr_SKUs_PreProcess @ttSKUsToPreprocess, null /* SKUId */, @vBusinessUnit;
    end

end /* pr_Imports_SKUPrePacks */

Go
