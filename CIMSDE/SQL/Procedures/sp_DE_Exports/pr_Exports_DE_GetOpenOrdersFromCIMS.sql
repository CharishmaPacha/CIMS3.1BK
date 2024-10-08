/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/21  SV      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData, pr_Exports_DE_GetOpenOrdersFromCIMS, pr_Exports_DE_GetOpenReceiptsFromCIMS:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_DE_GetOpenOrdersFromCIMS') is not null
  drop Procedure pr_Exports_DE_GetOpenOrdersFromCIMS;
Go
/*------------------------------------------------------------------------------
  pr_Exports_DE_GetOpenOrdersFromCIMS: This procedure will import data into ExportOpenOrders
    table(which is in CIMSDE database) from the given XML. CIMS' jobs will prepare the
    xml for all available open orders in CIMS and then invoke this procedures to insert
    the data into the CIMSDE ExportOpenOrders table.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_DE_GetOpenOrdersFromCIMS
  (@xmlOpenOrders   TXML,
   @UserId          TUserId       = null,
   @BusinessUnit    TBusinessUnit = null)
as
  declare @vReturnCode        TInteger,
          @vxmlOpenOrdersData xml;
begin
  SET NOCOUNT ON;

  if (@xmlOpenOrders is null)
    return;

  /* convert txml data into xml data */
  set @vxmlOpenOrdersData = convert(xml, @xmlOpenOrders);

  /* load data into DE table export inventory from the given XML from CIMS */
  insert into ExportOpenOrders (
    RecordType,
    PickTicket,
    SalesOrder,
    OrderType,
    Status,
    CancelDate,
    DesiredShipDate,
    SoldToId,
    ShipToId,
    ShipFrom,
    ShipVia,
    CustPO,
    Ownership,
    Warehouse,
    Account,
    HostOrderLine,
    SKU,
    SKU1,
    SKU2,
    SKU3,
    SKU4,
    SKU5,
    Lot,
    UnitsOrdered,
    UnitsAuthorizedToShip,
    UnitsReserved,
    UnitsNeeded,
    UnitsShipped,
    UnitsRemainToShip,
    OH_UDF1,
    OH_UDF2,
    OH_UDF3,
    OH_UDF4,
    OH_UDF5,
    OH_UDF6,
    OH_UDF7,
    OH_UDF8,
    OH_UDF9,
    OH_UDF10,
    OD_UDF1,
    OD_UDF2,
    OD_UDF3,
    OD_UDF4,
    OD_UDF5,
    OD_UDF6,
    OD_UDF7,
    OD_UDF8,
    OD_UDF9,
    OD_UDF10,
    vwOOE_UDF1,
    vwOOE_UDF2,
    vwOOE_UDF3,
    vwOOE_UDF4,
    vwOOE_UDF5,
    vwOOE_UDF6,
    vwOOE_UDF7,
    vwOOE_UDF8,
    vwOOE_UDF9,
    vwOOE_UDF10,
    SourceSystem,
    BusinessUnit,
    CreatedDate,
    ModifiedDate,
    CreatedBy,
    ModifiedBy,

    ExchangeStatus)
  select
    --convert(nvarchar(max), Record.Col.query('.')),
    Record.Col.value('RecordType[1]', 'TRecordType'),
    Record.Col.value('PickTicket[1]', 'TPickTicket'),
    Record.Col.value('SalesOrder[1]', 'TSalesOrder'),
    nullif(Record.Col.value('OrderType[1]', 'TOrderType'), ''),
    nullif(Record.Col.value('Status[1]', 'TStatus'), ''),
    nullif(Record.Col.value('CancelDate[1]', 'TDateTime'), ''),
    nullif(Record.Col.value('DesiredShipDate[1]', 'TDateTime'), ''),
    nullif(Record.Col.value('SoldToId[1]', 'TCustomerId'), ''),
    nullif(Record.Col.value('ShipToId[1]', 'TCustomerId'), ''),
    Record.Col.value('ShipFrom[1]',   'TShipFrom'),
    Record.Col.value('ShipVia[1]', 'TShipVia'),
    Record.Col.value('CustPO[1]', 'TCustPO'),
    nullif(Record.Col.value('Ownership[1]', 'TOwnership'), ''),
    nullif(Record.Col.value('Warehouse[1]', 'TWarehouse'), ''),
    nullif(Record.Col.value('Account[1]', 'TAccount'), ''),
    nullif(Record.Col.value('HostOrderLine[1]', 'THostOrderLine'), ''),
    nullif(Record.Col.value('SKU[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU1[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU2[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU3[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU4[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU5[1]', 'TSKU'), ''),
    nullif(Record.Col.value('Lot[1]', 'TLot'), ''),
    nullif(Record.Col.value('UnitsOrdered[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('UnitsAuthorizedToShip[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('UnitsReserved[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('UnitsNeeded[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('UnitsShipped[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('UnitsRemainToShip[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('OH_UDF1[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF2[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF3[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF4[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF5[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF6[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF7[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF8[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF9[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OH_UDF10[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF1[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF2[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF3[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF4[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF5[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF6[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF7[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF8[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF9[1]', 'TUDF'), ''),
    nullif(Record.Col.value('OD_UDF10[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF1[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF2[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF3[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF4[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF5[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF6[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF7[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF8[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF9[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwOOE_UDF10[1]','TUDF'), ''),
    nullif(Record.Col.value('SourceSystem[1]','TName'), ''),
    nullif(Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), ''),
    nullif(Record.Col.value('CreatedDate[1]',  'TDateTime'), ''),
    nullif(Record.Col.value('ModifiedDate[1]', 'TDateTime'), ''),
    Record.Col.value('CreatedBy[1]',  'TUserId'),
    Record.Col.value('ModifiedBy[1]', 'TUserId'),

    'N' /* No */
  from @vxmlOpenOrdersData.nodes('//ExportOpenOrders/OrderInfo') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlOpenOrdersData = null ) );

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_DE_GetOpenOrdersFromCIMS */

Go
