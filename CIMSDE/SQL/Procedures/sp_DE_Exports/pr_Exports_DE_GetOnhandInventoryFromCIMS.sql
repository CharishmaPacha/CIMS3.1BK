/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/29  MS      pr_Exports_DE_GetOnhandInventoryFromCIMS: Changes to send InventoyClasses in Exports (HA-323)
  2019/06/29  VS      pr_Exports_DE_GetOnhandInventoryFromCIMS: To Populate the UPC in OnhandInvExports (CID-659)
  2018/03/29  SV      pr_Exports_DE_GetOnhandInventoryFromCIMS: Added SourceSystem (HPI-1845)
  2018/03/16  SV      pr_Exports_DE_GetOnhandInventoryFromCIMS: Added Warehouse (S2G-437)
  2018/01/05  TD      pr_Exports_DE_GetOnhandInventoryFromCIMS:Changes to avoid missmatch count error(CIMSDE-35)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_DE_GetOnhandInventoryFromCIMS') is not null
  drop Procedure pr_Exports_DE_GetOnhandInventoryFromCIMS;
Go
/*------------------------------------------------------------------------------
  pr_Exports_DE_GetOnhandInventoryFromCIMS: This procedure will import data into ExportOnhandInventory
    table(which is in CIMSDE database) from the given XML. CIMS' jobs will prepare the
    xml for all available inventory in CIMS and then invoke this procedures to insert
    the data into the CIMSDE ExportOnhandInventory table.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_DE_GetOnhandInventoryFromCIMS
  (@xmlOHInvData   TXML,
   @UserId         TUserId       = null,
   @BusinessUnit   TBusinessUnit = null)
as
  declare @vReturnCode TInteger,
          @vxmlOHData  xml;
begin
  SET NOCOUNT ON;

  if (@xmlOHInvData is null)
    return;

  /* convert txml data into xml data */
  set @vxmlOHData = convert(xml, @xmlOHInvData);

  /* load data into DE table export inventory from the given XML from CIMS */
  insert into ExportOnhandInventory (
    RecordType,
    RecordAction,
    SKU,
    SKU1,
    SKU2,
    SKU3,
    SKU4,
    SKU5,
    UPC,
    LPN,
    Location,
    Lot,
    InventoryClass1,
    InventoryClass2,
    InventoryClass3,
    LPNType,
    LPNTypeDescription,

    AvailableQty,
    ReservedQty,
    OnhandQty,
    ReceivedQty,

    TransDateTime,

    SourceSystem,
    BusinessUnit,
    Ownership,
    Warehouse,
    CreatedDate,
    ModifiedDate,
    CreatedBy,
    ModifiedBy,

    ExchangeStatus)
  select
  --  convert(nvarchar(max), Record.Col.query('.')),
    Record.Col.value('RecordType[1]',   'TRecordType'),
    Record.Col.value('RecordAction[1]', 'TAction'),
    nullif(Record.Col.value('SKU[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU1[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU2[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU3[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU4[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU5[1]', 'TSKU'), ''),
    nullif(Record.Col.value('UPC[1]',  'TUPC'), ''),
    nullif(Record.Col.value('LPN[1]', 'TLPN'), ''),
    nullif(Record.Col.value('Location[1]', 'TLocation'), ''),
    Record.Col.value('Lot[1]', 'TLot'),
    nullif(Record.Col.value('InventoryClass1[1]', 'TInventoryClass'), ''),
    nullif(Record.Col.value('InventoryClass2[1]', 'TInventoryClass'), ''),
    nullif(Record.Col.value('InventoryClass3[1]', 'TInventoryClass'), ''),
    nullif(Record.Col.value('LPNType[1]', 'TTypeCode'), ''),
    nullif(Record.Col.value('LPNTypeDescription[1]', 'TDescription'), ''),

    nullif(Record.Col.value('AvailableQty[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('ReservedQty[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('OnhandQty[1]', 'TQuantity'), ''),
    nullif(Record.Col.value('ReceivedQty[1]', 'TQuantity'), ''),

    nullif(Record.Col.value('TransDateTime[1]', 'TDateTime'), ''),

    nullif(Record.Col.value('SourceSystem[1]','TName'), ''),
    nullif(Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), ''),
    nullif(Record.Col.value('Ownership[1]', 'TOwnership'), ''),
    nullif(Record.Col.value('Warehouse[1]', 'TWarehouse'), ''),
    nullif(Record.Col.value('CreatedDate[1]', 'TDateTime'), ''),
    nullif(Record.Col.value('ModifiedDate[1]', 'TDateTime'), ''),
    Record.Col.value('CreatedBy[1]', 'TUserId'),
    Record.Col.value('ModifiedBy[1]', 'TUserId'),

    'N' /* No */
  from @vxmlOHData.nodes('//msg/msgBody/Record') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlOHData = null ) );

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_DE_GetOnhandInventoryFromCIMS */

Go
