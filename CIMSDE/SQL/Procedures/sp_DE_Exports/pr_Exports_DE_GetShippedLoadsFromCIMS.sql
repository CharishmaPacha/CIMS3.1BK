/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/01  PK      Migrated from onsite DB: pr_Exports_DE_GetShippedLoadsFromCIMS, pr_Exports_DE_ParseXMLData (S2G-785)
  2018/01/30  OK      pr_Exports_DE_GetOpenReceiptsFromCIMS, pr_Exports_DE_GetShippedLoadsFromCIMS: Changed the xml schema while reading the data
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_DE_GetShippedLoadsFromCIMS') is not null
  drop Procedure pr_Exports_DE_GetShippedLoadsFromCIMS;
Go
/*------------------------------------------------------------------------------
  pr_Exports_DE_GetShippedLoadsFromCIMS: This procedure will returns the xml which contains
    all shipped loads from CIMS
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_DE_GetShippedLoadsFromCIMS
  (@xmlShippedLoads  TXML,
   @UserId           TUserId       = null,
   @BusinessUnit     TBusinessUnit = null)
as
  declare @vReturnCode          TInteger,
          @vxmlShippedLoadsData xml;
begin
  SET NOCOUNT ON;

  if (@xmlShippedLoads is null)
    return;

  /* convert txml data into xml data */
  set @vxmlShippedLoadsData = convert(xml, @xmlShippedLoads);

  /* load data into DE table export inventory from the given XML from CIMS */
  insert into ExportShippedLoads (
    LoadNumber,
    PickTicket,
    SalesOrder,
    SoldToId,
    ShipToId,
    LPN,
    Pallet,
    SKU,
    SKU1,
    SKU2,
    SKU3,
    SKU4,
    SKU5,
    LPNId,
    LPNDetailId,
    Lot,
    UnitsShipped,
    UDF1,
    UDF2,
    UDF3,
    UDF4,
    UDF5,
    UDF6,
    UDF7,
    UDF8,
    UDF9,
    UDF10,
    BusinessUnit,
    CreatedDate,
    ModifiedDate,
    CreatedBy,
    ModifiedBy,

    ExchangeStatus)
  select
    convert(nvarchar(max), Record.Col.query('.')),
    Record.Col.value('LoadNumber[1]', 'TLoadNumber'),
    Record.Col.value('PickTicket[1]', 'TPickTicket'),
    nullif(Record.Col.value('SalesOrder[1]', 'TSalesOrder'), ''),
    nullif(Record.Col.value('SoldToId[1]', 'TCustomerId'), ''),
    nullif(Record.Col.value('ShipToId[1]', 'TShipToId'), ''),
    nullif(Record.Col.value('LPN[1]', 'TLPN'), ''),
    nullif(Record.Col.value('Pallet[1]', 'TPallet'), ''),
    nullif(Record.Col.value('SKU[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU1[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU2[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU3[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU4[1]', 'TSKU'), ''),
    nullif(Record.Col.value('SKU5[1]', 'TSKU'), ''),
    nullif(Record.Col.value('LPNId[1]', 'TRecordId'), ''),
    nullif(Record.Col.value('LPNDetailId[1]', 'TRecordId'), ''),
    nullif(Record.Col.value('Lot[1]', 'TLot'), ''),
    nullif(Record.Col.value('UDF1[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF2[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF3[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF4[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF5[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF6[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF7[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF8[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF9[1]', 'TUDF'), ''),
    nullif(Record.Col.value('UDF10[1]','TUDF'), ''),
    nullif(Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'), ''),
    nullif(Record.Col.value('CreatedDate[1]',  'TDateTime'), ''),
    nullif(Record.Col.value('ModifiedDate[1]', 'TDateTime'), ''),
    Record.Col.value('CreatedBy[1]',  'TUserId'),
    Record.Col.value('ModifiedBy[1]', 'TUserId'),

    'N'
  from @vxmlShippedLoadsData.nodes('//ExportShippedLoads/LoadInfo') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlShippedLoadsData = null ) );

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_DE_GetShippedLoadsFromCIMS */

Go
