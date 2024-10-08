/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/29  PK/YJ   pr_Exports_OpenOrdersSummary: ported changes from prod onsite (HA-2729)
  2021/03/13  VM      pr_Exports_OpenOrdersSummary: Send AppointmentDateTime, LoadDesiredShipDate (HA-2275)
  2020/08/12  SK      pr_Exports_OpenOrdersSummary: New procedure called from job to export open order summary (HA-1267)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_OpenOrdersSummary') is not null
  drop Procedure pr_Exports_OpenOrdersSummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_OpenOrdersSummary:
    This procedure will send out all the open orders summary to CIMSDE DB
      for client to process their report.

    This has two modes to operate.
      (I)nsert - Will flush the complete Order summary, marking all the older records as archived
      (U)pdate - Will try to insert if no record found or Update the record with the summary if found
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_OpenOrdersSummary
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @Mode            TFlags = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vRecordId          TRecordId,
          @vMode              TFlags,
          @vDateToday         TDate,
          @vSourceReference   TDescription,
          @vLogId             TRecordId,
          @vRecordTypes       TRecordTypes,
          @vRulesInputXML     TXML,
          @vxmlExportData     TXML;

  declare @ttOpenOrdersSummary TOpenOrdersSummary;
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vRecordId         = 0,
         @vMode             = coalesce(@Mode, 'I' /* Insert */),
         @vDateToday        = getdate(),
         @vSourceReference  = Object_Name(@@ProcId);

  /* Add entry into interfacelog */
  exec pr_InterfaceLog_AddUpdate 'CIMS' /* SourceSystem */, 'CIMSDE' /* TargetSystem */,
                                 @vSourceReference /* SourceReference */, 'Export' /* TransferType */,
                                 'DB' /* RecordType */, @BusinessUnit, null /* xmlData */, null /* xmlDocHandle */,
                                 0 /* RecordsProcessed */, @vLogId output, @vRecordTypes output;

  /* temporary table */
  select * into #ExportOpenOrders from @ttOpenOrdersSummary;

  /* Get the data set */
  insert into #ExportOpenOrders (OrderId, PickTicket,  SalesOrder, OrderType, CancelDate,
                                 SoldToId, ShipToId, ShipFrom, ShipVia, ShipViaDescription,
                                 CustPO,  Ownership, Warehouse, Account, AccountName,
                                 LoadNumber, LoadStatus, RoutingStatus,
                                 NumSKUs, NumLines, NumUnitsToShip, TotalSalePrice, TotalShipmentValue,
                                 DesiredShipDate, LoadDesiredShipDate, AppointmentDateTime, OrderStatus, OrderStatusDesc,
                                 BusinessUnit, CreatedDate, ModifiedDate)
    select OrderId, PickTicket,  SalesOrder, OrderType,  CancelDate,
           SoldToId, ShipToId, ShipFrom, ShipVia, ShipViaDescription,
           CustPO,  Ownership, Warehouse, Account,  AccountName,
           LoadNumber, LoadStatus, coalesce(RoutingStatus, ''''),
           NumSKUs, NumLines, NumUnits, TotalSalePrice, TotalShipmentValue,
           DesiredShipDate, LoadDesiredShipDate, AppointmentDateTime, coalesce(LoadStatus, OrderStatus), coalesce(LoadStatusDesc, OrderStatusDesc),
           BusinessUnit, CreatedDate, ModifiedDate
    from vwOpenOrdersSummary with (nolock)
    where (BusinessUnit = @BusinessUnit);

  /* try..catch block */
  begin try
    /* Prepare the xml data set */
    set @vxmlExportData = cast((select *,
                                       @vMode as Mode
                                from #ExportOpenOrders
                                for xml path('OrderInfo'), root('ExportOpenOrdersSummary')) as varchar(max));

    /* Process the records on CIMSDE DB */
    exec CIMSDE_pr_PushExportOpenOrdersSummary @vxmlExportData, @BusinessUnit, @UserId;

    /* Mark Interface records as succeeded */
    exec pr_InterfaceLog_UpdateCounts @vLogId /* IntefaceLogId */, 0 /* FailedCount */;

  end try
  begin catch
    /* log into Interface table with the failure message for tracking/Research */
    select @vMessage = Error_Message();

    /* Save the exceptions to InterfaceLog tables so that users can be alerted of the failure */
    exec pr_InterfaceLog_SaveExceptions 'CIMS' /* Source System */, 'CIMSDE' /* Target System */,
                                        @vSourceReference, 'Export' /* Transfer Type */,
                                        'End' /* Process Type */, 'DB' /* RecordTypes */,
                                        @BusinessUnit, @vMessage;

    /* raise an exception if there is any */
    exec pr_ReRaiseError;
  end catch

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_OpenOrdersSummary */

Go
