/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/30  OK      pr_Imports_OrderDetails: Enhanced to use hash tables and created seperate procs for Insert, Update and delete (CIMSV3-1625)
  2021/09/23  VS      pr_Imports_OrderDetails, pr_Imports_OrderDetails_LoadData, pr_Imports_OrderHeaders
  2021/09/22  VS      pr_Imports_OrderDetails: Removed Transfer Order RH & RD creation (HA-3177)
  2021/09/08  VS      pr_Imports_OrderHeaders, pr_Imports_OrderDetails: Generate TransferOrder Receipts and ReceiptDetails (HA-3058)
  2021/09/06  SV      pr_Imports_OrderDetails, pr_Imports_OrderDetails_Update: Port back from FB (FBV3-175)
  2021/03/27  PK      pr_Imports_OrderDetails: Added changes to update UnitsPerInnerpack Ported changes done by Pavan (HA-2465)
  2020/10/21  PK      pr_Imports_OrderDetails: Included OD_UDF11..OD_UDF30 - Port back from HA Prod/Stag by VM (HA-1483)
  2020/06/05  SPP     pr_Imports_OrderDetails: Added PickingGroup (HA-296) (Ported from Prod)
  2020/05/30  TK      pr_Imports_OrderDetails: Insert/Update SKU as well (HA-623)
  2020/05/12  TK      pr_Imports_OrderDetails: AuditTrail info UDF1 to be OrderDetailId to avoid unique key error as there may be
  2020/03/19  YJ      pr_Imports_OrderDetails, pr_Imports_ReceiptDetails, pr_Imports_SKUs: Fields corrections as per-interface document (CIMS-2984)
  2019/05/01  YJ      pr_Imports_OrderDetails: Import OD.ParentLineNo (S2GCA-98)
  2018/02/23  TK      pr_Imports_OrderDetails: Chages to nullify Lot if it is empty (S2G-151)
  2017/09/05  AY      pr_Imports_OrderDetails: Performance improvement
                      pr_Imports_OrderHeaders, pr_Imports_OrderDetails: code optimization clean up (HPI-1396)
  2017/05/25  NB      pr_Imports_OrderHeaders, pr_Imports_OrderDetails: enhanced to work with sequential processing
  2017/05/24  NB      pr_Imports_ImportRecords, pr_Imports_OrderHeaders, pr_Imports_OrderDetails,
  2017/05/16  NB/AY   pr_Imports_ImportRecords, pr_Imports_OrderHeaders, pr_Imports_OrderDetails: Change XML
  2016/10/05  AY      pr_Imports_OrderDetails: AT linked to orderdetailid incorrectly.
  2016/08/28  AY      pr_Imports_OrderDetails/Headers: Append X to Waveflag to indicate that the orders has been modified (HPI-524).
  2016/08/19  YJ      pr_Imports_OrderDetails Added contol to get PTHostOrderLine (HPI-454)
  2016/08/09  OK      pr_Imports_OrderDetails: Enhanced to update the SKU as well if any of the Order detail modified (HPI-454)
  2016/08/04  MV      pr_Imports_OrderDetails: Code optimization to update order line (cIMS-1025)
  2016/07/22  DK      pr_Imports_OrderDetails: Bug fix to update order line correctly (HPI-337).
  2016/07/21  AY      pr_Imports_OrderDetails_AddSKUs: Fixed to not update existing SKUs and only add new ones.
  2016/06/27  AY      pr_Imports_OrderDetails_AddSKUs: Added distinct clause to avoid unique key violation issues
                      pr_Imports_OrderDetails: Change to establish uniqueness by OrderId and HostOrderLine,
  2016/05/09  AY      pr_Imports_OrderDetails_AddSKUs: Added
                      pr_Imports_OrderDetails: Introduced UnitsPerCarton import functionality(NBD-59)
                      pr_Imports_OrderDetails: Validating with the set of Order status to restrict importing (SRI-416)
  2015/11/10  OK      pr_Imports_OrderDetails, pr_Imports_ReceiptDetails: Made the changes
  2015/04/23  PK      pr_Imports_OrderDetails: Defaulting ReatilUnitPrice to 0.
  2015/01/21  SK      pr_Imports_OrderDetails: OrderId replaced with OrderDetailId to be inserted into
  2014/06/18  PV      pr_Imports_ImportRecord: Passing businessunit to pr_Imports_OrderDetails
                      pr_Imports_OrderDetails: Fetching the control values,
                      pr_Imports_OrderDetails: Modified to update PreprocessFlag on OrderHeader
  2014/05/28  NB      pr_Imports_OrderDetails: changes to use TAuditTrailInfo type and
                      pr_Imports_OrderDetails: Enhanced to process inserts/Updates/deletes
                      pr_Imports_ImportRecords: Enhanced to invoke pr_Imports_OrderDetails
  2014/04/01  NY      pr_Imports_OrderDetails : Added OrigUnitsAuthorizedToShip.
  2014/02/10  TD      pr_Imports_OrderDetails:Changes to update LocationId to OrderDetails.
  2012/11/14  VM      pr_Imports_OrderDetails: AuditActivity messaged corrected.
  2012/11/09  NY      pr_Imports_OrderDetails:implemented AT for Update and Delete actions
  2012/10/25  VM      pr_Imports_OrderDetails: Do not update UnitsAssinged as cIMS calculates. Preprocess OH After Update.
  2012/10/19  VM      pr_Imports_OrderDetails, pr_Imports_OrderHeaders:
  2012/10/18  VM      pr_Imports_OrderDetails: Preprocess order if any order line is deleted
  2012/10/11  AY      pr_Imports_OrderDetails: Allow delete of Order details.
                      pr_Imports_OrderDetails: Added UDF6..UDF10
  2012/06/28  AY      pr_Imports_OrderDetails: Fix issue with updating all detail lines.
  2011/10/27  AY      pr_Imports_OrderDetails: Added UnitTaxAmount
  2011/10/18  VM/SHR  pr_Imports_OrderDetails, pr_Imports_ValidateOrderDetail:
  2011/10/13  AY      pr_Imports_OrderDetails: Added new field LineType
                      pr_Imports_OrderDetails: New fields UnitSalePrice
  2011/07/30  YA      pr_Imports_OrderHeaders, pr_Imports_OrderDetails
                      pr_Imports_OrderHeaders and pr_Imports_OrderDetails Procedures
                      pr_Imports_OrderHeaders,pr_Imports_OrderDetails,pr_Imports_ValidateReceiptHeader
                      pr_Imports_OrderDetails
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderDetails') is not null
  drop Procedure pr_Imports_OrderDetails;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderDetails: Imports Orderdetails from different sources
    into OrderDetails table. Records can be Inserted/Updated or Deleted based upon
    Action.

  Sources: @xmlData, @DocumentHandle, ##ImportOrderDetails

  Usage:
    a. pr_Imports_OrderDetails @TransferToDBMethod = SQLData after the records are
       loaded into ##ImportOrderDetails. This is the method used by CIMSDE imports
       when CIMSDE is on same server
    b. pr_Imports_OrderDetails @xmlData - pass in data as XML
    c. pr_Imports_OrderDetails @documentHandle - pass in documentHandle of XML
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderDetails
  (@xmlData           Xml             = null,
   @documentHandle    TInteger        = null,
   @InterfaceLogId    TRecordId       = null,
   @BusinessUnit      TBusinessUnit   = null,
   @IsDESameServer    TFlag           = null,
   @UserId            TUserId         = null,
   @RecordId          TRecordId       = null)
as
  declare @vReturnCode          TInteger,
          @vAuditActivity       TActivityType,
          @vVarOrderId          TRecordId,
          @vVarOrderDetailId    TRecordId,
          @vVarRecordId         TRecordId,
          @vAuditRecordId       TRecordId,
          @vValidOrderStatus    TStatus,
          @vODUniqueKey         TControlValue;

  declare @ttOrderDetailsImport       TOrderDetailsImportType;
  declare @ttOrderDetailsValidations  TImportValidationType;
  declare @ttAuditInfo                TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  select @vAuditActivity = null;

  /*--------------------  Setup Hash tables --------------------*/

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  /* Create #AuditInfo temp table if it does not exist */
  if object_id('tempdb..#AuditInfo') is null
    select * into #AuditInfo from @ttAuditInfo;
  else
    delete from #AuditInfo;

  /* create #ImportValidations table with the @ttImportValidations temp table structure
     This is used in pr_InterfaceLog_AddDetails proc */
  if object_id('tempdb..#ImportValidations') is null
    select * into #ImportValidations from @ttOrderDetailsValidations;
  else
    delete from #ImportValidations;

  /* In some cases hash table may have been created by caller, if not create it as
     all data is inserted into hash table and then processed */
  if object_id('tempdb..#OrderDetailsImport') is null select * into #OrderDetailsImport from @ttOrderDetailsImport;

  if (@xmldata is not null) and (@InterfaceLogId is null)
    select @InterfaceLogId = Record.Col.value('ParentLogId[1]','TRecordId')
    from @xmlData.nodes('//msg/msgHeader') as Record(Col);

  /* Get control value */
  select @vODUniqueKey = dbo.fn_Controls_GetAsString('Import_OD', 'ODUniqueKey', 'PTHostOrderLine', @BusinessUnit, '' /* UserId */) ;

  /*-------------------- Load Data & Identify Key fields --------------------*/

  /* If there is no data in #OrderDetailsImport, then load it from ##OrderDetailsImport or XML */
  if not exists (select * from #OrderDetailsImport)
    exec pr_Imports_OrderDetails_LoadData @xmlData, @documentHandle, @IsDESameServer = @IsDESameServer;

  /* Update OrderId from OrderHeaders */
  update #OrderDetailsImport
  set OrderId   = OH.OrderId,
      OHStatus  = OH.Status,
      Ownership = OH.Ownership
  from #OrderDetailsImport ODI
  left outer join OrderHeaders OH on (ODI.PickTicket   = OH.PickTicket  ) and
                                     (ODI.BusinessUnit = OH.BusinessUnit);

  /* If SKUs are to be added to import Order details, do so */
  exec pr_Imports_OrderDetails_AddSKUs @BusinessUnit, @UserId;

  /* Update SKUId from SKUs */
  update #OrderDetailsImport
  set SKUId = S.SKUId,
      SKU   = S.SKU
  from #OrderDetailsImport ODI
  /* As We do not know user passed the either UPC or SKU, so update the SKU and SKUId */
  cross apply dbo.fn_SKUs_GetScannedSKUs(ODI.SKU, ODI.BusinessUnit) S
  where (S.Status = 'A'/* Active */);

  /* Update OrderDetailId of Temp Table from OrderDetails table */
  if (@vODUniqueKey = 'PTHostOrderLine')
    update #OrderDetailsImport
    set OrderDetailId = OD.OrderDetailId
    from #OrderDetailsImport ODI
    left outer join OrderDetails OD on (ODI.OrderId       = OD.OrderId      ) and
                                       (ODI.HostOrderLine = OD.HostOrderLine);
  else
    update #OrderDetailsImport
    set OrderDetailId = OD.OrderDetailId
    from #OrderDetailsImport ODI
    left outer join OrderDetails OD on (ODI.OrderId       = OD.OrderId      ) and
                                       (ODI.HostOrderLine = OD.HostOrderLine) and
                                       (ODI.SKUId         = OD.SKUId        );

  /*-------------------- Validate and Process --------------------*/

  /* Validate Order Details, capture validation results */
  exec pr_Imports_OrderDetails_Validate @BusinessUnit, @UserId;

  /* Set RecordAction for OrderDetail Records  */
  update #OrderDetailsImport
  set RecordAction = ODE.RecordAction
  from #OrderDetailsImport ODI
    join #ImportValidations ODE on (ODE.RecordId = ODI.RecordId);

  if (exists (select * from #OrderDetailsImport where (RecordAction = 'I' /* Insert */)))
    exec pr_Imports_OrderDetails_Insert @BusinessUnit, @UserId;

  if (exists (select * from #OrderDetailsImport where (RecordAction = 'U' /* Update */)))
    exec pr_Imports_OrderDetails_Update @BusinessUnit, @UserId;

  if (exists (select * from #OrderDetailsImport where (RecordAction = 'D')))
    exec pr_Imports_OrderDetails_Delete @BusinessUnit, @UserId;

  /*-------------------- Audit & Logging --------------------*/

  /* Verify if Audit Trail should be updated  */
  if (exists (select * from @ttAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId, Comment)
        select EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId,
               dbo.fn_Messages_BuildDescription(ActivityType, 'DisplaySKU', UDF2 /* SKU */ ,'OrderLine', UDF3 /* HostOrderLine */, 'PickTicket', EntityKey /* PickTicket */, null, null, null, null, null, null)
        from #AuditInfo AI

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, default;

  /*-------------------- Pre-Process Orders --------------------*/

  /* Mark the order headers of the inserted and updated records for preprocessing */
  update OH
  set OH.PreprocessFlag = case when (PreprocessFlag <> 'I') then 'N' else PreprocessFlag end,
      OH.WaveFlag       = case when (charindex('X', WaveFlag) = 0) /* If it already has X then ignore */
                            then coalesce(WaveFlag, '') + 'X'
                            else WaveFlag
                          end /* Append X to indicate order has been modified and the wave has to be re-evaluated */
  from OrderHeaders OH
    join #OrderDetailsImport OD on (OD.OrderId = OH.OrderId)
  where (OD.RecordAction in ('I' /* Insert */, 'U' /* Update */));

  if (@IsDESameServer = 'Y') and (coalesce(@RecordId,'') = '')
    drop table ##ImportOrderDetails;

end /* pr_Imports_OrderDetails */

Go
