/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/21  SV      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData, pr_Exports_DE_GetOpenOrdersFromCIMS, pr_Exports_DE_GetOpenReceiptsFromCIMS:
  2018/01/30  OK      pr_Exports_DE_GetOpenReceiptsFromCIMS, pr_Exports_DE_GetShippedLoadsFromCIMS: Changed the xml schema while reading the data
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_DE_GetOpenReceiptsFromCIMS') is not null
  drop Procedure pr_Exports_DE_GetOpenReceiptsFromCIMS;
Go
/*------------------------------------------------------------------------------
  pr_Exports_DE_GetOpenReceiptsFromCIMS: This procedure will returns the xml which contains
    all open receipts from CIMS
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_DE_GetOpenReceiptsFromCIMS
  (@xmlOpenReceipts   TXML,
   @UserId            TUserId       = null,
   @BusinessUnit      TBusinessUnit = null)
as
  declare @vReturnCode          TInteger,
          @vxmlOpenReceiptsData xml;
begin
  SET NOCOUNT ON;

  if (@xmlOpenReceipts is null)
    return;

  /* convert txml data into xml data */
  set @vxmlOpenReceiptsData = convert(xml, @xmlOpenReceipts);

  /* load data into DE table export inventory from the given XML from CIMS */
  insert into ExportOpenReceipts (
    RecordType,
    ReceiptNumber,
    ReceiptType,
    VendorId,
    Vessel,
    Warehouse,
    Ownership,
    ContainerNo,
    RH_UDF1,
    RH_UDF2,
    RH_UDF3,
    RH_UDF4,
    RH_UDF5,
    HostReceiptLine,
    CustPO,
    SKU,
    SKU1,
    SKU2,
    SKU3,
    SKU4,
    SKU5,
    CoO,
    UnitCost,
    QtyOrdered,
    QtyIntransit,
    QtyReceived,
    QtyOpen,
    RD_UDF1,
    RD_UDF2,
    RD_UDF3,
    RD_UDF4,
    RD_UDF5,
    RD_UDF6,
    RD_UDF7,
    RD_UDF8,
    RD_UDF9,
    RD_UDF10,
    vwORE_UDF1,
    vwORE_UDF2,
    vwORE_UDF3,
    vwORE_UDF4,
    vwORE_UDF5,
    vwORE_UDF6,
    vwORE_UDF7,
    vwORE_UDF8,
    vwORE_UDF9,
    vwORE_UDF10,
    SourceSystem,
    BusinessUnit,
    CreatedDate,
    ModifiedDate,
    CreatedBy,
    ModifiedBy,

    ExchangeStatus)
  select
    Record.Col.value('RecordType[1]',   'TRecordType'),
    Record.Col.value('ReceiptNumber[1]', 'TReceiptNumber'),
    Record.Col.value('ReceiptType[1]', 'TReceiptType'),
    nullif(Record.Col.value('VendorId[1]', 'TVendorId'), ''),
    nullif(Record.Col.value('Vessel[1]', 'TVessel'), ''),
    nullif(Record.Col.value('Warehouse[1]', 'TWarehouse'), ''),
    nullif(Record.Col.value('Ownership[1]', 'TOwnership'), ''),
    nullif(Record.Col.value('ContainerNo[1]', 'TContainer'), ''),
    nullif(Record.Col.value('RH_UDF1[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RH_UDF2[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RH_UDF3[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RH_UDF4[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RH_UDF5[1]', 'TUDF'), ''),
    nullif(Record.Col.value('HostReceiptLine[1]', 'THostReceiptLine'), ''),
    nullif(Record.Col.value('CustPO[1]', 'TCustPO'), ''),
    nullif(Record.Col.value('SKU[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU1[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU2[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU3[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU4[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU5[1]', 'TSKU'), ''),
    nullif(Record.Col.value('CoO[1]', 'TCoO'), ''),
    nullif(Record.Col.value('UnitCost[1]', 'TCost'), ''),
    nullif(Record.Col.value('QtyOrdered[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('QtyIntransit[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('QtyReceived[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('QtyOpen[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('RD_UDF1[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF2[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF3[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF4[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF5[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF6[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF7[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF8[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF9[1]', 'TUDF'), ''),
    nullif(Record.Col.value('RD_UDF10[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF1[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF2[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF3[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF4[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF5[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF6[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF7[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF8[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF9[1]', 'TUDF'), ''),
    nullif(Record.Col.value('vwORE_UDF10[1]','TUDF'), ''),
    nullif(Record.Col.value('SourceSystem[1]','TName'), ''),
    nullif(Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), ''),
    nullif(Record.Col.value('CreatedDate[1]',  'TDateTime'), ''),
    nullif(Record.Col.value('ModifiedDate[1]', 'TDateTime'), ''),
    Record.Col.value('CreatedBy[1]',  'TUserId'),
    Record.Col.value('ModifiedBy[1]', 'TUserId'),

    'N' /* No */
  from @vxmlOpenReceiptsData.nodes('//ExportOpenReceipts/ReceiptInfo') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlOpenReceiptsData = null ) );

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_DE_GetOpenReceiptsFromCIMS */

Go
