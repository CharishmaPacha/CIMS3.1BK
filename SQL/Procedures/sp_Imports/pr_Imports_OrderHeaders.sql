/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/04  LAC     pr_Imports_OrderHeaders_LoadData/Addresses, pr_Imports_AddOrUpdateAddresses: Added ShipToContactPerson field (BK-941)
  2022/01/20  OK      pr_Imports_OrderHeaders_LoadData: Included missing address fields for ShipTo, SoldTo, return, Mark for and BillTo (BK-742)
  2022/02/10  RKC     pr_Imports_OrderHeaders_LoadData: Removed the Duplicate column in the insert statement (BK-750)
  2021/09/23  VS      pr_Imports_OrderDetails, pr_Imports_OrderDetails_LoadData, pr_Imports_OrderHeaders
                      pr_Imports_OrderHeaders_LoadData, pr_Imports_OrderHeaders_Validate: Made changes to import the OH & OD through ##Tables (CIMSV3-1604)
  2021/09/08  VS      pr_Imports_OrderHeaders, pr_Imports_OrderDetails: Generate TransferOrder Receipts and ReceiptDetails (HA-3058)
  2021/08/24  RT      pr_Imports_OrderHeaders: Calling new procedure to create Receipts for Transfers Orders (HA-3058)
  2021/08/20  OK      pr_Imports_OrderHeaders: Enhanced to use Hash tables and refactored the code to have seperate procs for insert, update and delete
  2020/04/24  TK      pr_Imports_OrderHeaders: ShipCompletePercent defaulted to '0' is nothing passed in (HA-281)
  2019/08/29  RKC     pr_Imports_OrderHeaders_Addresses:Added AddressLine3 (HPI-2711)
                      pr_Imports_OrderHeaders:Pass the UDF19 value to ShipToAddressLine3
  2019/07/12  KBB     pr_Imports_OrderHeaders: Addded ShipCompletePercent to import the Orders (CID-533)
  2018/05/07  SV      pr_Imports_SKUs, pr_Imports_ReceiptHeaders, pr_Imports_OrderHeaders: This is done to fix
  2018/03/22  DK/SV   pr_Imports_OrderHeaders, pr_Imports_ValidateOrderHeader, pr_Imports_ImportRecords,
  2017/09/06  DK      pr_Imports_OrderHeaders: Enahanced to insert CarrierOptions(FB-1020)
  2017/08/21  SP/SV   pr_Imports_OrderHeaders: Added UDF21 - UDF30 (OB-548).
  2017/07/24  TK      pr_Imports_OrderHeaders: Changes to log AT if the Orders are being deleted (HPI-1597)
                      pr_Imports_OrderHeaders, pr_Imports_OrderDetails: code optimization clean up (HPI-1396)
  2017/05/25  NB      pr_Imports_OrderHeaders, pr_Imports_OrderDetails: enhanced to work with sequential processing
  2017/05/24  NB      pr_Imports_ImportRecords, pr_Imports_OrderHeaders, pr_Imports_OrderDetails,
  2017/05/16  NB/AY   pr_Imports_ImportRecords, pr_Imports_OrderHeaders, pr_Imports_OrderDetails: Change XML
  2017/04/12  NB      pr_Imports_OrderHeaders, pr_Imports_OrderHeaders_Addresses(CIMS-1289)
  2017/04/11  DK      pr_Imports_OrderHeaders, pr_Imports_OrderHeaders_Addresses, pr_Imports_AddOrUpdateAddresses, pr_Imports_ContactsClearDuplicates,
  2017/02/20  YJ      pr_Imports_OrderHeaders: Added Change to populate value of DownloadedDate (HPI-1382)
  2017/01/03  SV      pr_Imports_OrderHeaders, pr_Imports_ValidateOrderHeader: Need to validate with the status in case of delete action (HPI-1230)
  2016/07/05  AY      pr_Imports_OrderHeaders: Set ReturnAddrId to be R + ShipFrom which is typical usage.
  2016/05/22  AY      pr_Imports_OrderHeaders: HPI is going to generate PTs so we undid the changes we had done
  2016/04/05  NB/AY   pr_Imports_OrderHeaders: Enhanced to transform Warehouse value mapping with Ownership, if Warehouse is missing(NBD-353)
  2016/04/05  OK      pr_Imports_OrderHeaders: Refactor the code as pr_Imports_OrderHeaders_Addresses to import contacts (CIMS-862)
  2016/03/01  YJ      pr_Imports_ReceiptHeaders: Added field PickTicket, pr_Imports_OrderHeaders: Added field ReceiptNumber,
  2016/02/25  TK      pr_Imports_OrderHeaders: Bug fix to update Warehouse correctly on the Order (NBD-175)
                      pr_Imports_OrderHeaders: Enhanced read default Warehouse from LookUps, to update when Warehouse mapping is absent,
  2016/01/04  NB      pr_Imports_OrderHeaders: Introduced ShipFrom transformation for EDI Implementation (NBD-59)
  2016/01/01  NB      pr_Imports_OrderHeaders: Code optimization for  Warehouse, Ownership and OrderType transformation (NBD-59)
  2015/12/23  NB      pr_Imports_OrderHeaders: Introduced Warehouse, Ownership and OrderType transformation for EDI Implementation (NBD-59)
  2015/10/28  RV      pr_Imports_OrderHeaders: Included Replenish orders to update orderheaders with New (FB-472)
  2015/10/15  RV      pr_Imports_OrderHeaders_Delete: Modified procedure to handle as flag changes in pr_LPNs_Unallocate (FB-441).
  2015/07/09  SK      pr_Imports_OrderHeaders: Modified to include procedure to remove duplicate records in the incoming file for bulk imports.
  2015/03/26  SV      pr_Imports_OrderHeaders: Resolved the duplicacy issue while importing the contacts of all types.
  2015/03/03  NY      pr_Imports_OrderHeaders: Added null if condition to ContactRefId's.
  2015/02/25  NB      pr_Imports_OrderHeaders: Fix to add or update addresses only when they are part of the input xml
                      pr_Imports_OrderHeaders : Corrected to insert data from XML file from msg node.
  2015/01/08  SK      pr_Imports_OrderHeaders_Delete, pr_Imports_AddOrUpdateAddresses: Added procedures
  2015/01/07  SK      pr_Imports_OrderHeaders, pr_Imports_ValidateOrderHeader: Migration of Optimization of Order Headers
  2014/11/04  SK      pr_Imports_OrderHeaders: Enhanced to accept all contact types (SoldTo, ShipTo etc) address fields as well
  2014/07/01  TK      pr_Imports_OrderHeaders: Included new field ShipToStore as per the latest interface document.
  2014/06/03  NB      pr_Imports_OrderHeaders: Modified to update PreprocessFlag
  2014/05/08  PK      pr_Imports_OrderHeaders: Status updation changes.
  2014/04/16  PV      pr_Imports_OrderHeaders: Fixed issue with default date for CancelDate
  2013/09/16  PK      pr_Imports_PreprocessOrder, pr_Imports_OrderHeaders: Changes related to the change of Order Status Code.
  2013/02/17  YA      pr_Imports_OrderHeaders: Modified procedure to handle as signature changes in pr_LPNs_Unallocate.
  2012/12/27  PK      pr_Imports_OrderHeaders: Unallocate. LPNs, Pallets if the order is deleted while importing.
  2012/11/19  NY/VM   pr_Imports_OrderHeaders:update pickbatch counts when we delete Order from a batch
  2012/10/26  VM      pr_Imports_OrderHeaders: Seems like somewhere UnitsAssigned became null (mostly after Unallocate LPNs),
  2012/10/19  VM      pr_Imports_OrderDetails, pr_Imports_OrderHeaders:
  2012/10/01  VM      pr_Imports_OrderHeaders: Corrected to have initial status of downloaded orders
  2012/09/26  AY      pr_Imports_OrderHeaders: Allow Batched orders to be deleted.
  2012/07/15  AY      pr_Imports_OrderHeaders: Added TotalDiscount
  2012/07/11  AY      pr_Imports_OrderHeaders: Added CancelDate, TotalSalesAmount, MarkForAddress, Comments
  2012/07/06  YA      pr_Imports_SKUs, pr_Imports_OrderHeaders: fixed on owner validation as we are validting it without asignments.
  2012/05/19  AY      pr_Imports_OrderHeaders: Added Warehouse
  2012/02/16  VM      pr_Imports_OrderHeaders: Sometimes Shipvia coming with spaces suffixed, hence trimmed
  2011/10/12  AY      pr_Imports_OrderHeaders: New fields TotalTax, TotalShippingCost
  2011/10/10  VM      pr_Imports_OrderHeaders: Added i/p Warehouse and made changes to insert/update and validating
              AY      pr_Imports_OrderHeaders: On Delete, Mark order as canceled.
  2011/07/30  YA      pr_Imports_OrderHeaders, pr_Imports_OrderDetails
                      pr_Imports_OrderHeaders: Added to insert Status to table
                      pr_Imports_OrderHeaders and pr_Imports_OrderDetails Procedures
                      pr_Imports_OrderHeaders,pr_Imports_OrderDetails,pr_Imports_ValidateReceiptHeader
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderHeaders') is not null
  drop Procedure pr_Imports_OrderHeaders;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderHeaders

  UDFs change by client, we don't need to document them here, they have to be
  documented in init_Fields and Layouts
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderHeaders
  (@xmlData           Xml             = null,
   @documentHandle    TInteger        = null,
   @InterfaceLogId    TRecordId       = null,
   @BusinessUnit      TBusinessUnit   = null,
   @IsDESameServer    TFlag           = null,
   @UserId            TUserId         = null,
   @RecordId          TRecordId       = null)
as
  declare @vBusinessUnit           TBusinessUnit,
          @vDefaultWarehouse       TWarehouse,
          @ttDeletedOrders         TEntityKeysTable;

  /* Table vars for OrderHeaders, OrderHeaderValidations and AuditTrail  */
  declare @ttOrderHeaderImport       TOrderHeaderImportType,
          @ttOrderHeaderValidations  TImportValidationType,
          @ttAuditInfo               TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  /* Create an #Errors temp table if it does not exist */
  if object_id('tempdb..#Errors') is null
    create table #Errors(Error varchar(max));

  /* Create #ImportOHAuditInfo temp table if it does not exist */
  if object_id('tempdb..#AuditInfo') is null
    select * into #AuditInfo from @ttAuditInfo;
  else
    delete from #AuditInfo;

  /* create #ImportValidations table with the @ttImportValidations temp table structure
     This is used in pr_InterfaceLog_AddDetails proc */
  if object_id('tempdb..#ImportValidations') is null
    select * into #ImportValidations from @ttOrderHeaderValidations;

  /* In some cases hash table may have been created by caller, if not create it as
     all data is inserted into hash table and then processed */
  if object_id('tempdb..#OrderHeadersImport') is null select * into #OrderHeadersImport from @ttOrderHeaderImport;

  if (@xmldata is not null) and (@InterfaceLogId is null)
    select @InterfaceLogId = Record.Col.value('ParentLogId[1]','TRecordId')
    from @xmlData.nodes('//msg/msgHeader') as Record(Col);

  /* If there is no data in #ImportSKUs, then load it from ##ImportSKUs or XML */
  if not exists (select * from #OrderHeadersImport)
    exec pr_Imports_OrderHeaders_LoadData @xmlData, @documentHandle, @IsDESameServer = @IsDESameServer, @RecordId = @RecordId;

  /* Update OrderId and Status from OrderHeaders as we can't get this from the I/P xml. When inserting
     Orders, we don't find the PT and hence Status setup, up above remains and is not overwritten */
  update OHI
  set OHI.OrderId = OH.OrderId,
      OHI.Status  = OH.Status
  from #OrderHeadersImport OHI
    join OrderHeaders OH on (OHI.PickTicket   = OH.PickTicket  ) and
                            (OHI.BusinessUnit = OH.BusinessUnit);
/*
  HPI is going to generate unique PTs, so we don't need to do this
  from @ttOrderHeaderImport OHI
       cross apply dbo.fn_Imports_GetPickTicket(OHI.PickTicket, OHI.SalesOrder, OHI.BusinessUnit) PT;
*/

  /* Update Sold To Address to be Ship To Address, if not present */
  update #OrderHeadersImport
  set   SoldToId            = ShipToId,
        SoldToName          = ShipToName,
        SoldToAddressLine1  = ShipToAddressLine1,
        SoldToAddressLine2  = ShipToAddressLine2,
        SoldToCity          = ShipToCity,
        SoldToState         = ShipToState,
        SoldToCountry       = ShipToCountry,
        SoldToZip           = ShipToZip,
        SoldToPhoneNo       = ShipToPhoneNo,
        SoldToEmail         = ShipToEmail,
        SoldToAddressReference1  = ShipToAddressReference1,
        SoldToAddressReference2  = ShipToAddressReference2
  where ((SoldToId is null) and (SoldToName is null));

  /* TODO TODO TODO
     Need to introduce a condition to determine if the source system is EDI
     As of now, there is no defined way of knowing the source system to be EDI
     */

  /* Update Ownership, Warehouse, OrderType and ShipFrom from Mapping */
  select Top 1
         @BusinessUnit = BusinessUnit
  from #OrderHeadersImport;

  /* if there are no mappings setup, then the source value will be returned for Target value */
  update OHI
  set OHI.Ownership    = coalesce(MO.TargetValue,  OHI.Ownership),
      OHI.Warehouse    = coalesce(MW.TargetValue,  OHI.Warehouse),
      OHI.OrderType    = coalesce(MOT.TargetValue, OHI.OrderType),
      OHI.ShipFrom     = coalesce(MSF.TargetValue, OHI.ShipFrom),
      OHI.SourceSystem = coalesce(nullif(OHI.SourceSystem, ''), 'HOST')
  from #OrderHeadersImport OHI
    left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'Ownership', 'Import' /* Operation */,  @BusinessUnit) MO on (MO.SourceValue   = OHI.Ownership)
    left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'Warehouse', 'Import' /* Operation */,  @BusinessUnit) MW on (MW.SourceValue   = coalesce(OHI.Warehouse, OHI.Ownership))
    left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'OrderType', 'Import' /* Operation */,  @BusinessUnit) MOT on (MOT.SourceValue = OHI.OrderType)
    left outer join dbo.fn_GetMappedSet('HOST', 'CIMS', 'ShipFrom',  'Import' /* Operation */,  @BusinessUnit) MSF on (MSF.SourceValue = OHI.ShipFrom);

  /* Update DefaultWarehouse mapped to the Owner, when there is no Warehouse information from Host */
  /* Read the default Warehouse applicable for all Owners */
  select @vDefaultWarehouse = LookUpDescription
  from LookUps
  where (LookUpCategory = 'OwnerDefaultWarehouse') and
        (LookUpCode     = '*') and
        (Status         = 'A');

  /* Identify all the records which do not have valid Warehouse codes, and update them with
    mapping of Owner Warehouse from Look ups */
  update OHI
  set OHI.Warehouse = coalesce(DW.LookUpCode, @vDefaultWarehouse, OHI.Warehouse)
  from #OrderHeadersImport OHI
    left outer join Lookups DW on (DW.LookUpCategory = 'OwnerDefaultWarehouse') and
                                  (DW.Status         = 'A'               ) and
                                  (DW.LookUpCode     = OHI.Ownership     )
  where (OHI.Warehouse not in (select LookUpCode
                               from LookUps
                               where (LookUpCategory = 'Warehouse'    ) and
                                     (Status         = 'A'/* Active */)
                              )
        );

  /* Update Address Id's for address fields when not given */
  update OHI
  set SoldToId       = case when coalesce(SoldToId,'')       = '' then Left('C' + PickTicket, 50)
                       else SoldToId
                       end,
      ShipToId       = case when coalesce(ShipToId,'')       = '' then Left('S' + PickTicket, 50)
                       else ShipToId
                       end,
      ReturnAddrId   = case when coalesce(ReturnAddrId,'')   = '' then Left('R' + ShipFrom, 50)
                       else ReturnAddrId
                       end,
      MarkForAddress = case when coalesce(MarkForAddress,'') = '' then Left('M' + PickTicket, 50)
                       else MarkForAddress
                       end,
      BillToAddress  = case when coalesce(BillToAddress,'')  = '' then Left('B' + PickTicket, 50)
                       else BillToAddress
                       end
  from #OrderHeadersImport OHI;

  /* pr_Imports_OrderHeaders_Validate will return the result set of validation, captured in OrderHeaderValidations Table */
  exec pr_Imports_OrderHeaders_Validate @BusinessUnit, @UserId;

  /* Set RecordAction for OrderHeader Records  */
  update #OrderHeadersImport
  set RecordAction = OHV.RecordAction
  from #OrderHeadersImport OHI
    join #ImportValidations OHV on (OHV.RecordId = OHI.RecordId);

  /* Add or Update the contacts */
  exec pr_Imports_OrderHeaders_Addresses @BusinessUnit, @UserId;

  /* Note: Status of Address Imports doesn't affect Order Headers Imports
           i.e., If import of some of the records's Address fields fail,
           right now the order header insertion or update
           would continue as normal */

  /* Insert update or Delete based on Action */
  if (exists (select * from #OrderHeadersImport where (RecordAction = 'I' /* Insert */)))
    exec pr_Imports_OrderHeaders_Insert @BusinessUnit, @UserId;

  if (exists (select * from #OrderHeadersImport where (RecordAction = 'U' /* Update */)))
    exec pr_Imports_OrderHeaders_Update @BusinessUnit, @UserId;

  if (exists (select * from #OrderHeadersImport where (RecordAction = 'D' /* Delete */)))
    exec pr_Imports_OrderHeaders_Delete @BusinessUnit, @UserId;

  /* Verify if Audit Trail should be updated  */
  if (exists (select * from #AuditInfo))
    begin
      /* update comment. The comment will be used later to handle updating audit id values */
      insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId, Comment)
        select EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId,
               dbo.fn_Messages_BuildDescription(ActivityType, 'PickTicket', EntityKey /* PickTicket */, null, null , null, null , null, null, null, null, null, null)
        from #AuditInfo AI

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, default;

  /* Drop the data for each import Batch */
  if (@IsDESameServer = 'Y') and (coalesce(@RecordId,'') = '')
    drop table ##ImportOrderHeaders;

end /* pr_Imports_OrderHeaders */

Go
