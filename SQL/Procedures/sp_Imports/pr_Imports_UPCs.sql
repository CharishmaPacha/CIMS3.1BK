/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/27  MS      pr_Imports_UPCs, pr_Imports_ValidateUPC: Enhance pr_Imports_UPCs to handle OPENXML (CIMS-1841)
  2018/02/02  SV      pr_Imports_ImportRecord, pr_Imports_ImportRecords, pr_Imports_SKUs, pr_Imports_UPCs:
                      Implemented OPENXML function in pr_Imports_SKUs and pr_Imports_UPCs for processing
  2014/11/11  SK      pr_Imports_UPCs, pr_Impors_ValidateUPC: Enhancements to process UPCs
  2013/07/31  NY      Added procedure pr_Imports_UPCs, pr_Imports_ValidateUPC(ta9176).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_UPCs') is not null
  drop Procedure pr_Imports_UPCs;
Go
/*------------------------------------------------------------------------------
  pr_Imports_UPCs: Most customers will have only one UPC by SKU, however, if they
   have multiple, we would use pr_Imports_UPCs. Note that for sake of simplicity
   we are using the same layout as SKUs.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_UPCs
  (@xmlData           Xml             = null,
   @documentHandle    TInteger        = null,
   @InterfaceLogId    TRecordId       = null,
   @Action            TFlag           = null,
   @SKU               TSKU            = null,
   @SKU1              TSKU            = null,
   @SKU2              TSKU            = null,
   @SKU3              TSKU            = null,
   @SKU4              TSKU            = null,
   @SKU5              TSKU            = null,
   @Description       TDescription    = null,
   @SKU1Description   TDescription    = null,
   @SKU2Description   TDescription    = null,
   @SKU3Description   TDescription    = null,
   @SKU4Description   TDescription    = null,
   @SKU5Description   TDescription    = null,
   @AlternateSKU      TSKU            = null,
   @Status            TStatus         = null,
   @UoM               TUoM            = null,
   @InnerPacksPerLPN  TInteger        = null,
   @UnitsPerInnerPack TInteger        = null,
   @UnitsPerLPN       TInteger        = null,
   @InnerPackWeight   TFloat          = null,
   @InnerPackLength   TFloat          = null,
   @InnerPackWidth    TFloat          = null,
   @InnerPackHeight   TFloat          = null,
   @InnerPackVolume   TFloat          = null,
   @UnitWeight        TFloat          = null,
   @UnitLength        TFloat          = null,
   @UnitWidth         TFloat          = null,
   @UnitHeight        TFloat          = null,
   @UnitVolume        TFloat          = null,
   @UnitPrice         TFloat          = null,
   @Barcode           TBarcode        = null,
   @UPC               TUPC            = null,
   @Brand             TBrand          = null,
   @ProdCategory      TCategory       = null,
   @ProdSubCategory   TCategory       = null,
   @ABCClass          TFlag           = null,
   @UDF1              TUDF            = null,
   @UDF2              TUDF            = null,
   @UDF3              TUDF            = null,
   @UDF4              TUDF            = null,
   @UDF5              TUDF            = null,
   @UDF6              TUDF            = null,
   @UDF7              TUDF            = null,
   @UDF8              TUDF            = null,
   @UDF9              TUDF            = null,
   @UDF10             TUDF            = null,
   @UDF11             TUDF            = null,
   @UDF12             TUDF            = null,
   @UDF13             TUDF            = null,
   @UDF14             TUDF            = null,
   @UDF15             TUDF            = null,
   @UDF16             TUDF            = null,
   @UDF17             TUDF            = null,
   @UDF18             TUDF            = null,
   @UDF19             TUDF            = null,
   @UDF20             TUDF            = null,
   @UDF21             TUDF            = null,
   @UDF22             TUDF            = null,
   @UDF23             TUDF            = null,
   @UDF24             TUDF            = null,
   @UDF25             TUDF            = null,
   @UDF26             TUDF            = null,
   @UDF27             TUDF            = null,
   @UDF28             TUDF            = null,
   @UDF29             TUDF            = null,
   @UDF30             TUDF            = null,
   @BusinessUnit      TBusinessUnit   = null,
   @CreatedDate       TDateTime       = null,
   @ModifiedDate      TDateTime       = null,
   @CreatedBy         TUserId         = null,
   @ModifiedBy        TUserId         = null,
   @HostRecId         TRecordId       = null)
as
  declare @vParentLogId     TRecordId,
          /* Table vars for SKUs, SKUValidations and AuditTrail */
          @ttUPCs           TSKUAttributeImportType,
          @ttUPCValidation  TImportValidationType,
          @ttAuditInfo      TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  if (@xmldata is not null) and (@InterfaceLogId is null)
    select @InterfaceLogId = Record.Col.value('ParentLogId[1]','TRecordId')
    from @xmlData.nodes('//msg/msgHeader') as Record(Col);

  /* Populate the values into ttUPC table type */
  if (@documentHandle is not null)
    begin
      insert into @ttUPCs (
        InputXML,
        RecordType,
        RecordAction,
        SKU,
        Status,
        UPC,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId)
      select
        *
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="UPC"]', 2) -- condition forces to read only Records with RecordType UPC
      with (InputXML      nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType    TRecordType,
            Action        TAction,
            SKU           TSKU,
            Status        TStatus,
            UPC           TUPC,
            BusinessUnit  TBusinessUnit,
            CreatedDate   TDateTime         'CreatedDate/text()',
            ModifiedDate  TDateTime         'ModifiedDate/text()',
            CreatedBy     TUserId,
            ModifiedBy    TUserId,
            RecordId      TRecordId);
    end
  else
    begin
      insert into @ttUPCs (
        RecordAction, RecordType,
        SKU, Status, UPC, BusinessUnit,
        CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action, 'UPC',
        @SKU, @Status, @UPC, @BusinessUnit,
        @CreatedDate, @ModifiedDate, @CreatedBy, @ModifiedBy, @HostRecId;
    end

  /* Update table with SKUId's from SKUs table */
  update @ttUPCs
  set U.SKUId = S.SKUId
  from SKUs S
    join @ttUPCs U on (U.SKU = S.SKU) and (U.BusinessUnit = S.BusinessUnit);

    /* pr_Imports_ValidateUPC procedure  will return the result set of validation,
       captured in UPCValidations Table */
  insert @ttUPCValidation
    exec pr_Imports_ValidateUPC @ttUPCs

    /* Set Record Action for UPC Records */
  update @ttUPCs
  set RecordAction = SV.RecordAction
  from @ttUPCs U
    join @ttUPCValidation SV on (SV.RecordId = U.RecordId)

  /* Insert update or Delete based on Action */
  if (exists(select * from @ttUPCs where (RecordAction = 'I' /* Insert */)))
    begin
      insert into SKUAttributes (
        SKUId,
        AttributeType,
        AttributeValue,
        Status,
        BusinessUnit,
        CreatedDate,
        CreatedBy,
        ModifiedBy)
      select
        SKUId,
        'UPC',
        UPC,
        coalesce(nullif(ltrim(rtrim(Status)), ''), 'A' /* Active */),
        BusinessUnit,
        coalesce(CreatedDate, current_timestamp),
        coalesce(CreatedBy, System_User),
        coalesce(ModifiedBy, System_User)
      from @ttUPCs
      where (RecordAction = 'I' /* Insert */)
      order by HostRecId;
    end

  if (exists(select * from @ttUPCs where (RecordAction = 'U' /* Update */)))
    begin
      update SA
      set
        SA.Status            = coalesce(nullif(ltrim(rtrim(U.Status)), ''), 'A' /* Active */),
        SA.ModifiedDate      = coalesce(U.ModifiedDate, current_timestamp),
        SA.ModifiedBy        = coalesce(U.ModifiedBy, System_User)
      output 'UPC', Inserted.SKUId, U.UPC, null, 'AT_UPCModified' /* Audit Activity */, U.RecordAction /* Action */,
             null /* Comment */, Inserted.BusinessUnit, Inserted.ModifiedBy, Inserted.SKUId, U.UPC, null, null, null,
             null /* Audit Id */ into @ttAuditInfo
      from SKUAttributes SA inner join @ttUPCs U on (SA.SKUId = U.SKUId) and (SA.AttributeValue = U.UPC)
      where (U.RecordAction = 'U' /* Update */);
    end

  if (exists(select * from @ttUPCs where (RecordAction = 'D' /* Delete */)))
    begin
      /* Capture audit info */
      insert into @ttAuditInfo
      select 'UPC', SKUId, UPC, null, 'AT_UPCDeleted' /* Audit Activity */, RecordAction /* Action */, null /* Comment */,
              BusinessUnit, ModifiedBy, SKUId /* UDF1 */, SKU /* UDF2 */, null /* UDF3 */, null /* UDF4 */, null /* UDF5 */, null /* Audit Id */
      from @ttUPCs
      where (RecordAction = 'D');

      /* Update Attributes table as Inactive */
      update SKUAttributes
      set Status = 'I' /* Inactive */, Archived = 'Y'
      from SKUAttributes SA
        join @ttUPCs U on (SA.SKUId = U.SKUId) and (SA.AttributeValue = U.UPC)
      where (U.RecordAction = 'D');
    end

  /* Verify if Audit Trail should be updated  */
  if (exists(select * from @ttAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      update @ttAuditInfo
      set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'UPC', EntityKey /* SKU */ , null, null , null, null , null, null, null, null, null, null);

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttUPCValidation;

end /* pr_Imports_UPCs */

Go
