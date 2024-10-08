/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/29  PK/YJ   pr_Exports_OpenOrdersSummary: ported changes from prod onsite (HA-2729)
  2021/03/13  VM      pr_Exports_OpenOrdersSummary: Send AppointmentDateTime, LoadDesiredShipDate (HA-2275)
  2020/08/12  SK      pr_Exports_OpenOrdersSummary: New procedure called from job to export open order summary (HA-1267)
  2014/12/31  AK      pr_Exports_ExportDataToHost, pr_Exports_OnhandInventoryToHostDB and some part of pr_Exports_OpenOrders:
  2014/04/23  TK      Changes to pr_Exports_OpenOrders to export data to host DB.
  2014/02/05  PK      Added pr_Exports_OpenOrders, pr_Exports_OpenReceipts,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_OpenOrders') is not null
  drop Procedure pr_Exports_OpenOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_OpenOrders:

  This procedure will return the Open Orders
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_OpenOrders
  (@TransType    TTypeCode     = null,
   @PickTicket   TPickTicket   = null,
   @BusinessUnit TBusinessUnit = null,
   @UserId       TUserId       = null,
   @XmlData      XML           = null,
   @ResultXml    XML           = null output)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,

          @vRecordType      TTypeCode,
          @vIntegrationType TControlValue;

begin
  set NOCOUNT ON;

  select @ReturnCode    = 0,
         @MessageName   = null,
         @vRecordType   = 'OO' /* Open Orders */;

  /* Fetch the parameter values from the xmlData */
  if (@XmlData is not null)
    select @TransType    = Record.Col.value('TransType[1]',    'TTypeCode'),
           @PickTicket   = Record.Col.value('PickTicket[1]',   'TPickTicket'),
           @BusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
           @UserId       = Record.Col.value('UserId[1]',       'TUserId')
    from @xmlData.nodes('//msg/msgBody/Record') as Record(Col);

  /* Make null if empty strings are passed */
  select @TransType    = nullif(@TransType,    ''),
         @PickTicket   = nullif(@PickTicket,   ''),
         @BusinessUnit = nullif(@BusinessUnit, ''),
         @UserId       = nullif(@UserId,       '');

  select @vIntegrationType = dbo.fn_Controls_GetAsString ('Exports', 'IntegrationType',  'DB',
                                                          @BusinessUnit, @UserId);

  /* If the Integration type is Database */
  If (@vIntegrationType = 'DB')
    begin
    /*
      / * As per GNC request, Update the processed records * /
      update HostExportOpenOrders
      set processed_flg = 1
      where coalesce(processed_flg, 0) = 0;

      insert into HostExportOpenOrders
         (RecordType, PickTicket, SalesOrder, OrderType, Status, CancelDate, DesiredShipDate, SoldToId, ShipToId,
          ShipFrom, ShipVia, CustPO, Ownership, Warehouse, Account, HostOrderLine, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
          Lot, UnitsOrdered, UnitsAuthorizedToShip, UnitsReserved, UnitsNeeded, UnitsShipped, UnitsRemainToShip,
          OH_UDF1, OH_UDF2, OH_UDF3, OH_UDF4, OH_UDF5, OH_UDF6, OH_UDF7, OH_UDF8, OH_UDF9, OH_UDF10,
          OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
          UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10) */

      /* The above code is ignored as it is GNC Specfied */

      select @vRecordType as RecordType, O.PickTicket, O.SalesOrder, O.OrderType, O.Status, O.DesiredShipDate, O.CancelDate, O.SoldToId, O.ShipToId,
             O.ShipFrom, O.ShipVia, O.CustPO, O.Ownership, O.Warehouse, O.Account, O.HostOrderLine, O.SKU, O.SKU1, O.SKU2, O.SKU3, O.SKU4, O.SKU5,
             O.Lot, O.UnitsOrdered, O.UnitsAuthorizedToShip, O.UnitsReserved, O.UnitsNeeded, O.UnitsShipped, O.UnitsRemainToShip,
             O.OH_UDF1, O.OH_UDF2, O.OH_UDF3, O.OH_UDF4, O.OH_UDF5, O.OH_UDF6, O.OH_UDF7, O.OH_UDF8, O.OH_UDF9, O.OH_UDF10,
             O.OD_UDF1, O.OD_UDF2, O.OD_UDF3, O.OD_UDF4, O.OD_UDF5, O.OD_UDF6, O.OD_UDF7, O.OD_UDF8, O.OD_UDF9, O.OD_UDF10,
             O.vwOOE_UDF1, O.vwOOE_UDF2, O.vwOOE_UDF3, O.vwOOE_UDF4, O.vwOOE_UDF5, O.vwOOE_UDF6, O.vwOOE_UDF7, O.vwOOE_UDF8, O.vwOOE_UDF9, O.vwOOE_UDF10
      from vwOpenOrders O
      where (PickTicket   = coalesce(@PickTicket, PickTicket)) and
            (BusinessUnit = @BusinessUnit);
    end
  else
    begin
      /* Get the Shipped Load Info into XML */
      select @ResultXml = (select distinct @vRecordType as RecordType, PickTicket, SalesOrder, OrderTypeDescription as OrderType,
                                  StatusDescription as Status, CancelDate, DesiredShipDate, SoldToId, ShipToId, ShipFrom, ShipVia,
                                  CustPO, Ownership, Warehouse, Account, HostOrderLine, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
                                  Lot, UnitsOrdered, UnitsAuthorizedToShip, UnitsReserved, UnitsNeeded, UnitsShipped,
                                  UnitsRemainToShip, OH_UDF1, OH_UDF2, OH_UDF3, OH_UDF4, OH_UDF5, OH_UDF6, OH_UDF7, OH_UDF8, OH_UDF9,
                                  OH_UDF10, OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
                                  vwOOE_UDF1, vwOOE_UDF2, vwOOE_UDF3, vwOOE_UDF4, vwOOE_UDF5, vwOOE_UDF6, vwOOE_UDF7, vwOOE_UDF8, vwOOE_UDF9, vwOOE_UDF10
                          from vwOpenOrders
                          where (PickTicket   = coalesce(@PickTicket, PickTicket)) and
                                (BusinessUnit = @BusinessUnit)
                          FOR XML PATH('OrderInfo'), ROOT('ExportOpenOrders'));
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_OpenOrders */

Go
