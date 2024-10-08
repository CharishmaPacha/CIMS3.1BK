/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/08  PHK     pr_Imports_SKUs_LoadData: UDF* changed to SKU_UDF* (BK-1012)
  2021/09/17  VS      pr_Imports_CIMSDE_ImportData, pr_Imports_ImportsSQLData, pr_Imports_SKUs,
  2021/01/06  RKC     pr_Imports_SKUs: Changed the data type for HarmonizedCode field (CID-1616)
  2020/03/19  YJ      pr_Imports_OrderDetails, pr_Imports_ReceiptDetails, pr_Imports_SKUs: Fields corrections as per-interface document (CIMS-2984)
  2020/02/10  MS      pr_Imports_SKUAttributes_Update,pr_Imports_SKUs : Changes to update SKUDimentions (JL-76)
  2018/12/11  RIA     pr_Imports_SKUs: Used NullIf and coalesce to update the UoM (OB2-778)
  2018/05/07  SV      pr_Imports_SKUs, pr_Imports_ReceiptHeaders, pr_Imports_OrderHeaders: This is done to fix
  2018/04/05  YJ      pr_Imports_SKUs: Added CaseUPC(S2G-528)
                      pr_Imports_SKUs, pr_Imports_ValidateSKU:
  2018/03/19  RT      pr_Imports_SKUs: Made a minor change(S2G-312)
  2018/03/19  AY/RT   pr_Imports_SKUs: Do not overwrite IP values from Host if they are maintained in CIMS (S2G-312)
  2018/02/06  RT      pr_Imports_SKUs: Added NestingFactor and DefaultCoO (S2G-19)
  2018/02/02  SV      pr_Imports_ImportRecord, pr_Imports_ImportRecords, pr_Imports_SKUs, pr_Imports_UPCs:
                      Implemented OPENXML function in pr_Imports_SKUs and pr_Imports_UPCs for processing
  2017/12/04  PK      pr_Imports_SKUs: Added NMFC, HarmonizedCode (CIMS-1722).
  2017/11/09  TD      pr_Imports_GetXmlResult, pr_Imports_SKUs, pr_Imports_SKUs: changes to use hostrecid (CIMSDE-14)
  2017/02/27  AY      pr_Imports_SKUs: Do not overwrite ProdCategory when PHASed out.
  2016/11/30  AY      pr_Imports_SKUs: Do not overwrite ProdCategory with PHAS (HPI-GoLive)
  2016/05/06  PK/AY   pr_Imports_SKUs: Do not default UnitsPerInnerPack
  2016/03/30  KL      pr_Imports_SKUs: Do not allow  users to modify SKU dimensions and  CubeWeight, PackInfo, TiHi
  2016/03/30  NB      pr_Imports_SKUs: Enhanced to transform Ownership value from mapping(NBD-317)
                      pr_Imports_SKUs:Added field SKUSortOrder  (CIMS-780)
  2015/01/21  TK      pr_Imports_SKUs: SKU5 should be updated with SKU5 only.
  2014/12/24  SK      pr_Imports_SKUs: Added key word distinct to insert temp table for preprocessing to avoid
  2014/11/26  VM      pr_Imports_SKUs: UnitsPerInnerPack should be 1 by default, if it is supplied with null/0
  2014/10/20  NB      pr_Imports_SKUs, pr_Imports_ImportRecords, pr_Imports_ValidateSKU
  2014/07/21  PKS     pr_Imports_SKUs: Set proper parameter variable (BusinessUnit) for pr_SKUs_PreProcess
  2014/07/15  PK      pr_Imports_SKUs: Included PutawayClass.
  2014/05/01  NB      pr_Imports_SKUs - enhanced to fetch distinct orders to preprocess
  2014/02/17  TD      pr_Imports_SKUs: Changes to import Sorting and routing related fields.
  2013/10/10  TD      pr_Imports_SKUs:SKU PreProcess Changes.
  2013/09/03  TD      pr_Imports_SKUs:Add or delete SKU attributes while importing SKUs.
  2013/08/21  AY      pr_Imports_SKUs: Map ProdCategory to SKU PA Class.
  2013/08/14  TD      pr_Imports_SKUs:Setting null if the SKU1 to SKU5 are blank.
  2013/06/10  TD      pr_Imports_SKUs: setting default value to UOM if there is no value.
  2013/01/31  PK      pr_Imports_SKUs: Added SKU1Description, SKU2Description, SKU3Description, SKU4Description
  2012/11/07  YA      pr_Imports_SKUs: On updating SKU, preprocess orders related to SKU (required to recalculate UnitsPerCarton)
  2012/10/31  PK      pr_Imports_SKUs: Bug Fix
  2012/10/29  PK      pr_Imports_SKUs: Calculate UnitsPerCarton while downloading
  2012/10/06  TD      pr_Imports_SKUs: Update UDF7 with correct data.(With out NRF:)
  2012/07/06  YA      pr_Imports_SKUs, pr_Imports_OrderHeaders: fixed on owner validation as we are validting it without asignments.
  2011/10/07  VM      pr_Imports_SKUs: Set Serialized for Gift cards
  2011/07/26  AY      Changed pr_Imports_SKUs to import using data elements instead of XML,
  2011/07/06  PK      pr_Imports_SKUs : Added SKU1 - SKU5.
  2011/01/02  AR      pr_Interface_Import, pr_Imports_SKUs, pr_Imports_ValidateSKU:
  2010/12/21  VK      Made changes in the pr_Imports_SKUs procedure
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_SKUs') is not null
  drop Procedure pr_Imports_SKUs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_SKUs:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_SKUs
  (@xmlData           Xml             = null,
   @documentHandle    TInteger        = null,
   @InterfaceLogId    TRecordId       = null,
   @BusinessUnit      TBusinessUnit   = null,
   @IsDESameServer    TFlag           = null,
   @RecordId          TRecordId       = null)
as
  declare @vBusinessUnit           TBusinessUnit,
          @vReturnCode             TInteger,
          @Serialized              TFlag,
          @ttSKUs                  TEntityKeysTable,
          @vParentLogId            TRecordId;

  /* Table vars for SKUs, SKUValidations and AuditTrail  */
  declare @ttSKUImport       TSKUImportType;
  declare @ttSKUValidations  TImportValidationType;
  declare @ttAuditInfo       TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  if (@xmldata is not null) and (@InterfaceLogId is null)
    begin
      select @InterfaceLogId = Record.Col.value('ParentLogId[1]', 'TRecordId')
      from @xmlData.nodes('//msg/msgHeader') as Record(Col);
    end

  /* Data can be directly passed in thru #ImportSKUs, but if that is not given */
  if (object_id('tempdb..#ImportSKUs') is null)
    select * into #ImportSKUs from @ttSKUImport;

  /* Create #ImportSKUAuditInfo temp table if it does not exist */
  if (object_id('tempdb..#ImportSKUAuditInfo') is null)
    select * into #ImportSKUAuditInfo from @ttAuditInfo;
  else
    delete from #ImportSKUAuditInfo;

  /* create #ImportValidations table with the @ttImportValidations temp table structure
     This is used in pr_InterfaceLog_AddDetails proc */
  if (object_id('tempdb..#ImportValidations') is null)
    select * into #ImportValidations from @ttSKUValidations;

  /* If there is no data in #ImportSKUs, then load it from ##ImportSKUs or XML */
  if (not exists (select * from #ImportSKUs))
    exec pr_Imports_SKUs_LoadData @xmlData, @documentHandle, @IsDESameServer = @IsDESameServer, @RecordId = @RecordId;

  /* Update SKUId of all the records in SKUImports table by using join on SKUs table
     This will be useful for validations, the inserts/updates/deletes */
  update #ImportSKUs
  set SKUId = S.SKUId
  from SKUS S
    join #ImportSKUs SI on (S.SKU = SI.SKU);

  select top 1 @BusinessUnit = BusinessUnit from #ImportSKUs;

  /* Update Ownership from Mapping and UoM with default(if not sent by host) */
  /* If there are no mappings setup, then the source value will be returned for Target value */
  /* UoM assignment: Before the implementation of OpenXML methodology, we used to insert the default
                     value 'EA', if the value from the host is sent as null. With the implementation
                     of OpenXML, we are assigning the value here if it is not sent from host. */
  update #ImportSKUs
  set Ownership    = coalesce(MO.TargetValue,  SI.Ownership),
      UoM          = coalesce(nullif(SI.UoM, ''), 'EA'),
      SourceSystem = coalesce(nullif(SourceSystem, ''), 'HOST')
  from #ImportSKUs SI
    left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'Ownership', 'Import' /* Operation */,  @BusinessUnit) MO on (MO.SourceValue   = SI.Ownership);

  /* Update Owner column in the SKUImports table */
  with OwnerDetails(DefaultOwner)
  as
  (
    /* Until we add Ownership to interface, we will assume all SKUs are for first
       owner in the list of owners */
    select top 1 LookupCode
    from vwLookUps
    where (LookUpCategory = 'Owner')
    order by SortSeq
  )
  update #ImportSKUs
  set Ownership = (select DefaultOwner from OwnerDetails)
  where (coalesce(Ownership, '') = '');

  /* pr_Imports_ValidateSKU procedure will return the result set of validation, captured in SKUValidations Table */
  exec pr_Imports_ValidateSKU;

  /* Set RecordAction for SKU Records  */
  update #ImportSKUs
  set RecordAction = SV.RecordAction
  from #ImportSKUs SI
    join #ImportValidations SV on (SV.RecordId = SI.RecordId);

  /***** Insert, Update or Delete based on Action *****/
  if (exists (select * from #ImportSKUs where (RecordAction = 'I' /* Insert */)))
    exec pr_Imports_SKUs_Insert @BusinessUnit, null /* User Id */;

  if (exists (select * from #ImportSKUs where (RecordAction = 'U' /* Update */)))
    exec pr_Imports_SKUs_Update @BusinessUnit, null /* User Id */;

  if (exists (select * from #ImportSKUs where (RecordAction = 'D')))
    exec pr_Imports_SKUs_Delete @BusinessUnit, null /* User Id */

  /* Verify if Audit Trail should be created */
  if (exists(select * from #ImportSKUAuditInfo))
    begin
      /* update comment. The comment will be used later to handle updating audit id values */
      insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId, Comment)
        select EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId,
               dbo.fn_Messages_BuildDescription(ActivityType, 'SKU', EntityKey /* SKU */, null, null , null, null , null, null, null, null, null, null)
        from #ImportSKUAuditInfo ISA

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, default;

  /* if the Action is inserting or updating then we need to pre-process the SKU */
  if (exists (select * from #ImportSKUs where (RecordAction in ('I', 'U'))))
    begin
    /* Chances of Error : When duplicate records w.r.t SKU are sent
       Future Change    : Control value given by the client should be included
                          to either out or select only distinct values */
      insert into @ttSKUs
        select distinct SKUId, SKU
        from #ImportSKUs
        where (RecordAction in ('I', 'U'));

      exec pr_SKUs_PreProcess @ttSKUs, null /* SKUId */, @BusinessUnit;
    end

  /* Drop the data for each import Batch */
  if (@IsDESameServer = 'Y') and (coalesce(@RecordId,'') = '')
    drop table ##ImportSKUs;

end /* pr_Imports_SKUs */

Go
