/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/10  SV      pr_Imports_ReceiptHeaders_Validate: Changes to validate Warehouse if not passed (FBV3-181)
  2021/06/30  RKC     pr_Imports_ReceiptHeaders, pr_Imports_ReceiptHeaders_Validate, pr_InterfaceLog_AddDetails: Made changes to Replaced temp table with hash table (HA-2933)
  2021/06/23  RKC     pr_Imports_ReceiptHeaders: Corrected the LookUpCategory to get the correct values (HA-2823)
                      Added pr_Imports_ReceiptHeaders_Validate, pr_Imports_ReceiptHeaders
  2020/10/27  MS      pr_Imports_ReceiptHeaders, fn_Imports_ResolveAction: Made changes to delete records recursively (CIMSV3-1146)
                      pr_Imports_ReceiptHeaders_Delete: Added new proc
  2019/01/06  AY      pr_Imports_ReceiptHeaders: Enumerate fields for output into @AuditInfo (CIMS-2375)
  2018/05/10  SV      pr_Imports_ReceiptHeaders and pr_Imports_ReceiptDetails: Code changes to restrict deleting the Receipt and its detaillines
  2018/05/07  SV      pr_Imports_SKUs, pr_Imports_ReceiptHeaders, pr_Imports_OrderHeaders: This is done to fix
                      pr_Imports_ReceiptHeaders, pr_Imports_ValidateReceiptHeader,
  2018/03/03  AY      pr_Imports_ReceiptHeaders: Fixed issue with dates defaulting to 1900-01-01(S2G-347)
  2017/01/08  TD      pr_Imports_ReceiptHeaders:Import valid creadtedatetime (CIMSDE-52)
                      pr_Imports_ReceiptHeaders, pr_Imports_ValidateReceiptHeader: Added and accessed HostRecId (CIMSDE-17)
  2017/05/29  NB      pr_Imports_ReceiptHeaders, pr_Imports_ReceiptDetails : Change XML
  2016/07/20  AY      pr_Imports_ReceiptHeaders: Identifying ReceiptId by ReceiptType - fixed issue.
                      pr_Imports_ReceiptHeaders: Enhanced to add InputXML and RecordType from XML to Temp Table
  2016/03/03  OK      pr_Imports_ReceiptHeaders: Enhanced to Import RH with Mapped/Default Warehouse if user doesn't passed (CIMS-802)
  2016/03/01  YJ      pr_Imports_ReceiptHeaders: Added field PickTicket, pr_Imports_OrderHeaders: Added field ReceiptNumber,
  2015/09/30  DK      pr_Imports_ReceiptHeaders: Enhanced to import PickTicket(FB-416).
  2015/02/02  SK      pr_Imports_ReceiptHeaders: Added RecordAction field to be included in the AuditTrail log
  2014/12/01  SK      pr_Imports_ImportRecords, pr_Imports_ReceiptHeaders, pr_Imports_ValidateReceiptHeader:
              AY      pr_Imports_ReceiptHeaders: Do not allow delete if there are units received against it.
  2103/08/13  TD      pr_Imports_ReceiptHeaders: Setting null if the ETA Date is blank.
  2012/07/02  VM,PK   pr_Imports_ReceiptHeaders: Set status to InTransit, if receipt type is ASN
  2011/08/04  YA      pr_Imports_ReceiptHeaders, pr_Imports_ReceiptDetails
  2011/01/17  VK      Made changes to the pr_Imports_ReceiptHeaders,pr_Imports_ReceiptDetails
  2011/01/06  VK      Made changes to procedures pr_Imports_ReceiptHeaders,pr_Imports_ReceiptDetails
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ReceiptHeaders') is not null
  drop Procedure pr_Imports_ReceiptHeaders;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_ReceiptHeaders: There are 3 ways to import RHs into CIMS system.
    1. @xmlData/@documentHandle: Pass data thru @xmlData/@documentHandle. The xml
       will be parsed and inserted into #ReceiptHeadersImport and processed.
    2. #ReceiptHeadersImport: Provide the data to import via the hash table
    3. Pass individual paramenters: This doesn't require any of @xmlData, @documentHandle
       & #ReceiptHeadersImport. Just pass thru the individual parameters and rest of the
       import process will be taken care by the code.

  In all cases, in the end, data is inserted into #ReceiptHeadersImport and processed
  from there on.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ReceiptHeaders
  (@xmlData         Xml              = null,
   @documentHandle  TInteger         = null,
   @InterfaceLogId  TRecordId        = null,
   @Action          TFlag            = null,
   @ReceiptNumber   TReceiptNumber   = null,
   @ReceiptType     TReceiptType     = null,
   @PickTicket      TPickTicket      = null,
   @VendorId        TVendorId        = null,
   @Ownership       TOwnership       = null,
   @Vessel          TVessel          = null,
   @NumLPNs         TCount           = null,
   @NumUnits        TCount           = null,
   @HostNumLines    TCount           = null,
   @ContainerSize   TContainerSize   = null,
   @Warehouse       TWarehouse       = null,
   @DateOrdered     TDateTime        = null,
   @DateShipped     TDateTime        = null,
   @BillNo          TBoLNumber       = null,
   @SealNo          TSealNumber      = null,
   @InvoiceNo       TInvoiceNo       = null,
   @ContainerNo     TContainer       = null,
   @ETACountry      TDate            = null,
   @ETACity         TDate            = null,
   @ETAWarehouse    TDate            = null,
   @UDF1            TUDF             = null,
   @UDF2            TUDF             = null,
   @UDF3            TUDF             = null,
   @UDF4            TUDF             = null,
   @UDF5            TUDF             = null,
   @UDF6            TUDF             = null,
   @UDF7            TUDF             = null,
   @UDF8            TUDF             = null,
   @UDF9            TUDF             = null,
   @UDF10           TUDF             = null,
   @UDF11           TUDF             = null,
   @UDF12           TUDF             = null,
   @UDF13           TUDF             = null,
   @UDF14           TUDF             = null,
   @UDF15           TUDF             = null,
   @UDF16           TUDF             = null,
   @UDF17           TUDF             = null,
   @UDF18           TUDF             = null,
   @UDF19           TUDF             = null,
   @UDF20           TUDF             = null,
   @UDF21           TUDF             = null,
   @UDF22           TUDF             = null,
   @UDF23           TUDF             = null,
   @UDF24           TUDF             = null,
   @UDF25           TUDF             = null,
   @SourceSystem    TName            = 'HOST',
   @BusinessUnit    TBusinessUnit    = null,
   @CreatedDate     TDateTime        = null,
   @ModifiedDate    TDateTime        = null,
   @CreatedBy       TUserId          = null,
   @ModifiedBy      TUserId          = null,
   @HostRecId       TRecordId        = null
  )
as
  declare @vReturnCode             TInteger,
          @vDefaultWarehouse       TWarehouse,

          @ttReceiptHeadersImport  TReceiptHeaderImportType,
          @ttImportValidations     TImportValidationType,
          @ttAuditInfo             TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  /* Create #ImportRHAuditInfo temp table if it does not exist */
  if object_id('tempdb..#ImportRHAuditInfo') is null
    select * into #ImportRHAuditInfo from @ttAuditInfo;
  else
    delete from #ImportRHAuditInfo;

  /* create #ImportValidations table with the @ttImportValidations temp table structure
     This is used in pr_InterfaceLog_AddDetails proc */
  if object_id('tempdb..#ImportValidations') is null
    select * into #ImportValidations from @ttImportValidations;

  if (@xmldata is not null) and (@InterfaceLogId is null)
    select @InterfaceLogId = Record.Col.value('ParentLogId[1]','TRecordId')
    from @xmlData.nodes('//msg/msgHeader') as Record(Col);

  /* In some cases hash table may have been created by caller, if not create it as
     all data is inserted into hash table and then processed */
  if object_id('tempdb..#ReceiptHeadersImport') is null select * into #ReceiptHeadersImport from @ttReceiptHeadersImport;

  /* Populate the hash table with the data given in xml */
  if (@documentHandle is not null)
    begin
      insert into #ReceiptHeadersImport (
        InputXML,
        RecordType,
        RecordAction,
        ReceiptNumber,
        ReceiptType,
        PickTicket,
        VendorId,
        Ownership,
        Vessel,
        NumLPNs,
        NumUnits,
        HostNumLines,
        ContainerSize,
        Warehouse,
        DateOrdered,
        DateShipped,
        BillNo,
        SealNo,
        InvoiceNo,
        ContainerNo,
        ETACountry,
        ETACity,
        ETAWarehouse,
        RH_UDF1,
        RH_UDF2,
        RH_UDF3,
        RH_UDF4,
        RH_UDF5,
        SourceSystem,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId,
        Status
        )
      select *,
        /* As it cant be null we are updating it directly here with default value */
        case
          when (ReceiptType = 'A' /* ASN */) then
            'T' /* InTransit */
          else
            'I' /* Initial */
        end as Status
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="RH"]', 2) -- condition forces to read only Records with RecordType OH
      with (InputXML                 nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType               TRecordType,
            RecordAction             TAction        'Action',
            ReceiptNumber            TReceiptNumber,
            ReceiptType              TReceiptType,
            PickTicket               TPickTicket,
            VendorId                 TVendorId,
            Ownership                TOwnership,
            Vessel                   TVessel,
            NumLPNs                  TCount,
            NumUnits                 TCount,
            HostNumLines             TCount,
            ContainerSize            TContainerSize,
            Warehouse                TWarehouse,
            DateOrdered              TDateTime  'DateOrdered/text()',
            DateShipped              TDateTime  'DateShipped/text()',
            BillNo                   TBoLNumber,
            SealNo                   TSealNumber,
            InvoiceNo                TInvoiceNo,
            ContainerNo              TContainer,
            ETACountry               TDate   'ETACountry/text()',
            ETACity                  TDate   'ETACity/text()',
            ETAWarehouse             TDate   'ETAWarehouse/text()',
            RH_UDF1                  TUDF,
            RH_UDF2                  TUDF,
            RH_UDF3                  TUDF,
            RH_UDF4                  TUDF,
            RH_UDF5                  TUDF,
            SourceSystem             TName,
            BusinessUnit             TBusinessUnit,
            CreatedDate              TDateTime      'CreatedDate/text()', -- returns null when the xml contains only the CreatedDate element with no data. Acts as NullIf function
            ModifiedDate             TDateTime      'ModifiedDate/text()',
            CreatedBy                TUserId,
            ModifiedBy               TUserId,
            RecordId                 TRecordId)
    end
  else
  /* if caller already inserted data, then ignore the params */
  if (not exists (select * from #ReceiptHeadersImport))
    begin
      insert into #ReceiptHeadersImport (
        RecordAction,
        ReceiptNumber,
        ReceiptType,
        PickTicket,
        Status,
        VendorId,
        Ownership,
        Vessel, NumLPNs, NumUnits, HostNumLines,
        ContainerSize, Warehouse,
        DateOrdered, DateShipped,
        BillNo, SealNo, InvoiceNo, ContainerNo,
        ETACountry, ETACity, ETAWarehouse,
        RH_UDF1, RH_UDF2, RH_UDF3, RH_UDF4, RH_UDF5,
        SourceSystem, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action,
        @ReceiptNumber,
        @ReceiptType,
        @PickTicket,
        /* As it cant be null we are updating it directly here with default value */
        case
          when (@ReceiptType = 'A' /* ASN */) then
            'T' /* InTransit */
          else
            'I' /* Initial */
        end,
        @VendorId,
        @Ownership,
        @Vessel, @NumLPNs, @NumUnits, @HostNumLines,
        @ContainerSize, @Warehouse,
        @DateOrdered, @DateShipped,
        @BillNo, @SealNo, @InvoiceNo, @ContainerNo,
        @ETACountry, @ETACity, @ETAWarehouse,
        @UDF1, @UDF2, @UDF3, @UDF4, @UDF5,
        @SourceSystem, @BusinessUnit, @CreatedDate, @ModifiedDate, @CreatedBy, @ModifiedBy, @HostRecId
    end

  /* Update ReceiptId from ReceiptHeaders */
  update #ReceiptHeadersImport
  set ReceiptId = RH.ReceiptId,
      Status    = RH.Status
  from #ReceiptHeadersImport RHI
       join ReceiptHeaders RH on (RHI.ReceiptNumber = RH.ReceiptNumber) and
                                 (RHI.BusinessUnit  = RH.BusinessUnit );

  /* Get the Business unit, assumption is that all will be of same BU */
  select top 1 @BusinessUnit = BusinessUnit from #ReceiptHeadersImport;

  /* if there are no mappings setup, then the source value will be returned for Target value */
  update #ReceiptHeadersImport
  set Ownership    = coalesce(MO.TargetValue, RHI.Ownership),
      Warehouse    = coalesce(MW.TargetValue, RHI.Warehouse),
      SourceSystem = coalesce(nullif(RHI.SourceSystem, ''), 'HOST')
  from #ReceiptHeadersImport RHI
       left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'Ownership', 'Import' /* Operation */,   @BusinessUnit) MO on (MO.SourceValue   = RHI.Ownership)
       left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'Warehouse', 'RHImport' /* Operation */, @BusinessUnit) MW on (MW.SourceValue   = RHI.Warehouse);

  /* Read the default Warehouse applicable for all Owners */
  select @vDefaultWarehouse = LookUpDescription
  from LookUps
  where (LookUpCategory = 'OwnerDefaultWarehouse') and
        (LookUpCode     = '*') and
        (Status         = 'A');

  /* Identify all the records which do not have valid Warehouse codes, and update them with
     mapping of Owner Warehouse from Look ups */
  update #ReceiptHeadersImport
  set Warehouse = coalesce(DW.LookupDescription, @vDefaultWarehouse, RHI.Warehouse)
    from #ReceiptHeadersImport RHI
       left outer join Lookups DW on (DW.LookUpCategory = 'OwnerDefaultWarehouse') and
                                     (DW.Status         = 'A'                    ) and
                                     (DW.LookUpCode     = RHI.Ownership          )
  where (RHI.Warehouse not in (select LookUpCode
                               from LookUps
                               where (LookUpCategory = 'Warehouse'    ) and
                                     (Status         = 'A'/* Active */)
                              ));

  /* Validate the RH records in #ReceiptHeadersImport. Invalid records would be updated with RecordAction of E */
  exec pr_Imports_ReceiptHeaders_Validate;

  /* Insert update or Delete based on Action */
  if (exists (select * from #ReceiptHeadersImport where RecordAction = 'I' /* Insert */))
    insert into ReceiptHeaders (
      ReceiptNumber,
      ReceiptType,
      PickTicket,
      Status,
      VendorId,
      Ownership,
      Vessel,
      NumLPNs,
      NumUnits,
      HostNumLines,
      ContainerSize,
      Warehouse,
      DateOrdered,
      DateShipped,
      BillNo,
      SealNo,
      InvoiceNo,
      ContainerNo,
      ETACountry,
      ETACity,
      ETAWarehouse,
      UDF1,
      UDF2,
      UDF3,
      UDF4,
      UDF5,
      SourceSystem,
      BusinessUnit,
      CreatedDate,
      CreatedBy)
    select
      ReceiptNumber,
      ReceiptType,
      PickTicket,
      Status,
      VendorId,
      Ownership,
      Vessel,
      NumLPNs,
      NumUnits,
      HostNumLines,
      ContainerSize,
      Warehouse,
      DateOrdered,
      DateShipped,
      BillNo,
      SealNo,
      InvoiceNo,
      ContainerNo,
      ETACountry,
      ETACity,
      ETAWarehouse,
      RH_UDF1,
      RH_UDF2,
      RH_UDF3,
      RH_UDF4,
      RH_UDF5,
      SourceSystem,
      BusinessUnit,
      coalesce(CreatedDate, current_timestamp),
      coalesce(CreatedBy, System_User)
    from #ReceiptHeadersImport
    where (RecordAction = 'I' /* Insert */)
    order by HostRecId;

  if (exists (select * from #ReceiptHeadersImport where RecordAction = 'U' /* Update */))
    update RH1
    set RH1.ReceiptType     = RH2.ReceiptType,
        RH1.PickTicket      = RH2.PickTicket,
        RH1.VendorId        = RH2.VendorId,
        RH1.Ownership       = RH2.Ownership,
        RH1.Vessel          = RH2.Vessel,
        RH1.NumLPNs         = RH2.NumLPNs,
        RH1.NumUnits        = RH2.NumUnits,
        RH1.HostNumLines    = RH2.HostNumLines,
        RH1.ContainerSize   = RH2.ContainerSize,
        RH1.Warehouse       = RH2.Warehouse,
        RH1.DateOrdered     = RH2.DateOrdered,
        RH1.DateShipped     = RH2.DateShipped,
        RH1.BillNo          = RH2.BillNo,
        RH1.SealNo          = RH2.SealNo,
        RH1.InvoiceNo       = RH2.InvoiceNo,
        RH1.ContainerNo     = RH2.ContainerNo,
        RH1.ETACountry      = RH2.ETACountry,
        RH1.ETACity         = RH2.ETACity,
        RH1.ETAWarehouse    = RH2.ETAWarehouse,
        RH1.PreprocessFlag  = case when (RH1.PreprocessFlag <> 'I' /* Ignore */) then 'N' /* No */else RH1.PreprocessFlag end,
        RH1.UDF1            = RH2.RH_UDF1,
        RH1.UDF2            = RH2.RH_UDF2,
        RH1.UDF3            = RH2.RH_UDF3,
        RH1.UDF4            = RH2.RH_UDF4,
        RH1.UDF5            = RH2.RH_UDF5,
        --RH1.SourceSystem    = RH2.SourceSystem, Should not change source system
        RH1.ModifiedDate    = coalesce(RH2.ModifiedDate, current_timestamp),
        RH1.ModifiedBy      = coalesce(RH2.ModifiedBy, System_User)
    -- We are fetching AT with 'Receipt' entity in UI
    output 'Receipt', Inserted.ReceiptId, Inserted.ReceiptNumber, 'AT_ReceiptHeaderModified',
           RH2.RecordAction /* Action */,Inserted.BusinessUnit, Inserted.ModifiedBy
    into #ImportRHAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
    from ReceiptHeaders RH1 inner join #ReceiptHeadersImport RH2 on (RH1.ReceiptId = RH2.ReceiptId)
    where RH2.RecordAction = 'U' /* Update */;

  if (exists (select * from #ReceiptHeadersImport where RecordAction = 'C' /* Closed */))
    update RH1
    set RH1.Status       = 'C' /* Closed */,
        RH1.ModifiedDate = coalesce(RH2.ModifiedDate, current_timestamp),
        RH1.ModifiedBy   = coalesce(RH2.ModifiedBy, System_User)
    output 'Receipt', Inserted.ReceiptId, Inserted.ReceiptNumber, 'AT_ReceiptHeaderClosed',
           RH2.RecordAction, Inserted.BusinessUnit, Inserted.ModifiedBy
    into #ImportRHAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
    from ReceiptHeaders RH1 inner join #ReceiptHeadersImport RH2 on (RH1.ReceiptId = RH2.ReceiptId)
    where (RH2.RecordAction = 'C' /* Closed */);

  if (exists (select * from #ReceiptHeadersImport where RecordAction = 'R' /* Re-open */))
    update RH1
    set RH1.Status       = 'I' /* Initial */,
        RH1.ModifiedDate = coalesce(RH2.ModifiedDate, current_timestamp),
        RH1.ModifiedBy   = coalesce(RH2.ModifiedBy, System_User)
    output 'Receipt', Inserted.ReceiptId, Inserted.ReceiptNumber, 'AT_ReceiptHeaderReopened',
           RH2.RecordAction, Inserted.BusinessUnit, Inserted.ModifiedBy
    into #ImportRHAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
    from ReceiptHeaders RH1 inner join #ReceiptHeadersImport RH2 on (RH1.ReceiptId = RH2.ReceiptId)
    where (RH2.RecordAction = 'R' /* Re-open */);

  /* Process the D, DR actions */
  if (exists (select * from #ReceiptHeadersImport where RecordAction in ('D', 'DR' /* Delete Recursively */)))
    exec pr_Imports_ReceiptHeaders_Delete;

  /* Verify if Audit Trail should be updated */
  if (exists(select * from #ImportRHAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      update #ImportRHAuditInfo
      set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'Receipt', EntityKey /* ReceiptNumber */ , null, null , null, null , null, null, null, null, null, null);

      insert into @ttAuditInfo
        select * from #ImportRHAuditInfo;

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttImportValidations;

end /* pr_Imports_ReceiptHeaders */

Go
