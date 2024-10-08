/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/13  VM      pr_Exports_DE_InsertOpenOrdersSummary: Send AppointmentDateTime, LoadDesiredShipDate (HA-2275)
  2020/08/12  SK      pr_Exports_DE_InsertOpenOrdersSummary: New procedure to insert into ExportOpenOrdersSummary table (HA-1267)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_DE_InsertOpenOrdersSummary') is not null
  drop Procedure pr_Exports_DE_InsertOpenOrdersSummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_DE_InsertOpenOrdersSummary:
    This procedure is called from Prod DB to export summarized open orders
    for client reporting purposes
    The procedure would update if the record exists or insert if the record
    is not found
    This export for every new day is always an insert
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_DE_InsertOpenOrdersSummary
  (@xmlExportData    TXML,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  /* Declare local variables */
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          @vMode                  TFlags,
          @vDateTimeToday         TDateTime,
          @vDateToday             TDate,
          @vxmlOHData             xml;

  declare @ttOpenOrdersSummary    TOpenOrdersSummary;
begin
begin try
  begin transaction
  SET NOCOUNT ON;

  if (@xmlExportData is null) return;

  /* convert txml data into xml data */
  set @vxmlOHData = convert(xml, @xmlExportData);

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vDateTimeToday  = getdate(),
         @vDateToday      = cast(@vDateTimeToday as date);

  /* temporary table */
  select * into #ExportOHSummary from @ttOpenOrdersSummary;

  /* Add index on the temporary table for the joins below */
  create index ix_ttEOHS on #ExportOHSummary (PickTicket, BusinessUnit);

  /* Determine the mode */
  select top 1 @vMode = Record.Col.value('Mode[1]', 'TFlags')
  from @vxmlOHData.nodes('//ExportOpenOrdersSummary/OrderInfo') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlOHData = null ) );

  /* For an export on a new day, it is going to be an Insert mode */
  if (not exists(select top 1 * from ExportOpenOrdersSummary where CreatedOn = @vDateToday))
    select @vMode = 'I' /* Insert */;

  /* Get xml data into the table */
  insert into #ExportOHSummary (
    PickTicket,
    SalesOrder,
    OrderType,
    CancelDate,
    SoldToId,
    ShipToId,
    ShipFrom,
    ShipVia,
    ShipViaDescription,
    CustPO,
    Ownership,
    Warehouse,
    Account,
    AccountName,
    NumSKUs,
    NumLines,
    NumUnitsToShip,
    TotalSalePrice,
    TotalShipmentValue,
    LoadNumber,
    LoadStatus,
    RoutingStatus,
    DesiredShipDate,
    LoadDesiredShipDate,
    AppointmentDateTime,
    OrderStatus,
    OrderStatusDesc,
    BusinessUnit)
  select
    Record.Col.value('PickTicket[1]',           'TPickTicket'),
    Record.Col.value('SalesOrder[1]',           'TSalesOrder'),
    Record.Col.value('OrderType[1]',            'TOrderType'),
    Record.Col.value('CancelDate[1]',           'TDateTime'),
    Record.Col.value('SoldToId[1]',             'TCustomerId'),
    Record.Col.value('ShipToId[1]',             'TShipToId'),
    Record.Col.value('ShipFrom[1]',             'TShipFrom'),
    Record.Col.value('ShipVia[1]',              'TShipVia'),
    Record.Col.value('ShipViaDescription[1]',   'TDescription'),
    Record.Col.value('CustPO[1]',               'TCustPO'),
    Record.Col.value('Ownership[1]',            'TOwnership'),
    Record.Col.value('Warehouse[1]',            'TWarehouse'),
    Record.Col.value('Account[1]',              'TCustomerId'),
    Record.Col.value('AccountName[1]',          'TName'),
    Record.Col.value('NumSKUs[1]',              'TQuantity'),
    Record.Col.value('NumLines[1]',             'TQuantity'),
    Record.Col.value('NumUnitsToShip[1]',       'TQuantity'),
    Record.Col.value('TotalSalePrice[1]',       'TMoney'),
    Record.Col.value('TotalShipmentValue[1]',   'TMoney'),
    Record.Col.value('LoadNumber[1]',           'TLoadNumber'),
    Record.Col.value('LoadStatus[1]',           'TStatus'),
    Record.Col.value('RoutingStatus[1]',        'TStatus'),
    Record.Col.value('DesiredShipDate[1]',      'TDateTime'),
    Record.Col.value('LoadDesiredShipDate[1]',  'TDateTime'),
    Record.Col.value('AppointmentDateTime[1]',  'TDateTime'),
    Record.Col.value('OrderStatus[1]',          'TStatus'),
    Record.Col.value('OrderStatusDesc[1]',      'TDescription'),
    Record.Col.value('BusinessUnit[1]',         'TBusinessUnit')
  from @vxmlOHData.nodes('//ExportOpenOrdersSummary/OrderInfo') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlOHData = null ) );

  /***************************** Mode: Insert *********************************/
  /* Archive all previous records before proceeding further for Insert mode */
  if (@vMode = 'I' /* Insert */)
    update EOO
    set EOO.Archived     = 'Y' /* yes */,
        EOO.ModifiedDate = @vDateTimeToday,
        EOO.ModifiedBy   = @UserId
    from ExportOpenOrdersSummary EOO
    where (Archived = 'N' /* No */);

  /*************************** Modes: Insert/Update ***************************/
  /* Insert new records */
  insert into ExportOpenOrdersSummary (PickTicket, SalesOrder, OrderType, OrderStatus, OrderStatusDesc,
                                       CancelDate, DesiredShipDate, LoadDesiredShipDate, AppointmentDateTime, SoldToId, ShipToId, ShipFrom, ShipVia, ShipViaDescription,
                                       CustPO, Ownership, Warehouse, Account, AccountName,
                                       NumSKUs, NumLines, NumUnitsToShip, TotalSalePrice, TotalShipmentValue,
                                       LoadNumber, LoadStatus, RoutingStatus, ExchangeStatus, Archived, BusinessUnit,
                                       CreatedDate, CreatedBy)
    select TEOO.PickTicket, TEOO.SalesOrder, TEOO.OrderType, TEOO.OrderStatus, TEOO.OrderStatusDesc,
           TEOO.CancelDate, TEOO.DesiredShipDate, TEOO.LoadDesiredShipDate, TEOO.AppointmentDateTime, TEOO.SoldToId, TEOO.ShipToId, TEOO.ShipFrom, TEOO.ShipVia, TEOO.ShipViaDescription,
           TEOO.CustPO, TEOO.Ownership, TEOO.Warehouse, TEOO.Account, TEOO.AccountName,
           TEOO.NumSKUs, TEOO.NumLines, TEOO.NumUnitsToShip, TEOO.TotalSalePrice, TEOO.TotalShipmentValue,
           TEOO.LoadNumber, TEOO.LoadStatus, TEOO.RoutingStatus, 'N' /* Not Processed */, 'N' /* No */, TEOO.BusinessUnit,
           @vDateTimeToday, @UserId
    from #ExportOHSummary TEOO
      left outer join ExportOpenOrdersSummary EOO on (EOO.PickTicket   = TEOO.PickTicket) and
                                                     (EOO.BusinessUnit = TEOO.BusinessUnit) and
                                                     (EOO.Archived     = 'N' /* No */)
    where (EOO.PickTicket is null);

  /******************************* Mode: Update *******************************/
  /* Update old records with new values - many of the OH info would not change
     over period of time */
  if (@vMode = 'U' /* Update */)
    begin
      update EOO
      set EOO.OrderStatus           = TEOO.OrderStatus,
          EOO.OrderStatusDesc       = TEOO.OrderStatusDesc,
          EOO.CancelDate            = TEOO.CancelDate,
          EOO.DesiredShipDate       = TEOO.DesiredShipDate,
          EOO.LoadDesiredShipDate   = TEOO.LoadDesiredShipDate,
          EOO.AppointmentDateTime   = TEOO.AppointmentDateTime,
          EOO.ShipFrom              = TEOO.ShipFrom,
          EOO.ShipVia               = TEOO.ShipVia,
          EOO.ShipViaDescription    = TEOO.ShipViaDescription,
          EOO.NumUnitsToShip        = TEOO.NumUnitsToShip,
          EOO.TotalSalePrice        = TEOO.TotalSalePrice,
          EOO.TotalShipmentValue    = TEOO.TotalShipmentValue,
          EOO.LoadNumber            = TEOO.LoadNumber,
          EOO.LoadStatus            = TEOO.LoadStatus,
          EOO.RoutingStatus         = TEOO.RoutingStatus,
          EOO.ExchangeStatus        = 'N' /* Not processed */,
          EOO.ModifiedDate          = @vDateTimeToday,
          EOO.ModifiedBy            = @UserId
      from #ExportOHSummary TEOO
        join ExportOpenOrdersSummary EOO on (EOO.PickTicket   = TEOO.PickTicket) and
                                            (EOO.BusinessUnit = TEOO.BusinessUnit) and
                                            (EOO.Archived     = 'N' /* No */);
    end

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_DE_InsertOpenOrdersSummary */

Go
