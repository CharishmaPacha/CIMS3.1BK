/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/22  AY      pr_Exports_OnhandInventory: Performance optimizations (HA-3105)
  2020/04/29  MS      pr_Exports_OnhandInventory, pr_Exports_LPNData, pr_Exports_LPNReceiptConfirmation: Changes to send InventoryClasses in Exports (HA-323)
  2019/06/28  VS      pr_Exports_OnhandInventory: Made changes to Export UPC in Onhnadinventory Export (CID-659)
  2018/08/01  DK      pr_Exports_OnhandInventory: Bug fix to get the zero qty SKUs in case if any of SKU1, SKU2 etc are null
  2018/06/01  DK      pr_Exports_OnhandInventory: Enchanced to send UPC and OnhandAvailableQty (FB-1150)
                         in pr_Exports_OnhandInventory (S2G-470)
  2018/05/03  SV      pr_Exports_CIMSDE_ExportOpenOrders, pr_Exports_CIMSDE_ExportOpenReceipts, pr_Exports_OnhandInventory:
  2018/03/30  SV      pr_Exports_OnhandInventory: Added SourceSystem
  2018/03/15  DK      pr_Exports_OnhandInventory: Enhanced to process exports file by validating SourceSystem (FB-1113)
  2018/05/02  OK      pr_Exports_OnhandInventory: Enhanced to send the BusinessUnit along with export Data (S2G-185)
  2016/06/25  AY      pr_Exports_OnhandInventory: Bug fix which is preventing zero qty SKUs being exported when all SKU attributes are not used.
  2016/05/16  AY      pr_Exports_OnhandInventory: Do not summarize by OHStatus (will yield duplicate lines)
  2016/06/05  DK      pr_Exports_OnhandInventory: Modified to accept parameters Businessunit and xmlinput (HPI-89)
  2016/03/11  RV      pr_Exports_OnhandInventoryByOwner: Return data as xml instead of data set and Calling procedure signature changed (CIMS-809)
  2016/03/10  RV      pr_Exports_OnhandInventory: Return data as xml instead of data set (CIMS-809)
  2016/02/19  TK      pr_Exports_OnhandInventory: Changed signature to accept Ownership as well (NBD-132)
                      pr_Exports_OnhandInventoryByOwner: Initial revision
  2016/02/15  TK      pr_Exports_OnhandInventory: OnHand Inventory should be exported by Owner (NBD-132)
  2015/05/29  YJ      pr_Exports_OnhandInventory: Added LotNumber Field.
  2014/12/31  AK      pr_Exports_ExportDataToHost, pr_Exports_OnhandInventoryToHostDB and some part of pr_Exports_OpenOrders:
  2014/08/12  PK      pr_Exports_OnhandInventoryToHostDB: Update the processed records before we
  2013/05/14  AY      pr_Exports_OnhandInventory: Bug fixed - reporting zero qty skus when requested not to
  2013/05/01  AY      pr_Exports_OnhandInventory: RH needs all SKUs but not by Locations
  2012/10/04  VM      pr_Exports_OnhandInventory: TD customization - LPN does not required to send
  2012/08/13  YA      pr_Exports_OnhandInventory: Made empty strings to null.
  2012/08/10  YA      pr_Exports_OnhandInventory: Included Ownnership,and TransDateTime.
  2011/07/21  PK      pr_Exports_OnhandInventory : Added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_OnhandInventory') is not null
  drop Procedure pr_Exports_OnhandInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_OnhandInventory:
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_OnhandInventory
  (@Warehouse         TWarehouse    = null,
   @Ownership         TOwnership    = null,
   @SourceSystem      TName         = null,
   @SKU               TSKU          = null,
   @SKU1              TSKU          = null,
   @SKU2              TSKU          = null,
   @SKU3              TSKU          = null,
   @SKU4              TSKU          = null,
   @SKU5              TSKU          = null,
   @UPC               TUPC          = null,
   @OutputZeroQtySKUs TBoolean      = 0 /* No */,
   @BusinessUnit      TBusinessUnit = null,
   @XmlData           xml           = null,
   @XmlResult         xml           = null output
)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @Message              TDescription,

          @vSKUCount            TCount,
          @vBusinessUnit        TBusinessUnit,
          @xmlExportsMsgHeader  TVarchar,
          @vAddExportsMsgHeader TFlag;

  declare @ttOnhandInventory    TOnhandInventory;

  declare @ttOrderedQty table (SKUId                 TRecordId,
                               Ownership             TOwnership,
                               Warehouse             TWarehouse,
                               UnitsToAllocate       TQuantity);

begin /* pr_Exports_OnhandInventory */

  if (@XmlData is not null)
    select @Warehouse    = nullif(Record.Col.value('Warehouse[1]', 'TWarehouse'), ''),
           @Ownership    = nullif(Record.Col.value('Ownership[1]', 'TOwnership'), ''),
           @SourceSystem = Record.Col.value('SourceSystem[1]', 'TName'),
           @SKU          = nullif(Record.Col.value('SKU[1]', 'TSKU'), ''),
           @SKU1         = nullif(Record.Col.value('SKU1[1]', 'TSKU'), ''),
           @SKU2         = nullif(Record.Col.value('SKU2[1]', 'TSKU'), ''),
           @SKU3         = nullif(Record.Col.value('SKU3[1]', 'TSKU'), ''),
           @SKU4         = nullif(Record.Col.value('SKU4[1]', 'TSKU'), ''),
           @SKU5         = nullif(Record.Col.value('SKU5[1]', 'TSKU'), '')
    from @xmlData.nodes('//msg/msgBody/Record') as Record(Col);
  else
    /* Make null if empty strings are passed */
    select @Warehouse     = nullif(@Warehouse,   ''),
           @Ownership     = nullif(@Ownership,   ''),
           @SourceSystem  = nullif(coalesce(@SourceSystem, 'HOST'), ''),
           @SKU           = nullif(@SKU,         ''),
           @SKU1          = nullif(@SKU1,        ''),
           @SKU2          = nullif(@SKU2,        ''),
           @SKU3          = nullif(@SKU3,        ''),
           @SKU4          = nullif(@SKU4,        ''),
           @SKU5          = nullif(@SKU5,        '');

  if (@BusinessUnit is not null)
    select @vBusinessUnit = @BusinessUnit;
  else
    select @vBusinessUnit = BusinessUnit from vwBusinessUnits;

  /* Get the control value whether to add OnhandInventory MsgHeader node in result or not */
  select @vAddExportsMsgHeader = dbo.fn_Controls_GetAsBoolean('ExportOnHandInv', 'AddMsgHeaderNode', 'Y' /* No */, @vBusinessUnit, 'CIMSAgent');

  /* Inserting data into temp table from vwExportOnhandInventory based on Inputparamters */
  insert into @ttOnhandInventory (SKUId,
                                  SKU,
                                  SKU1,
                                  SKU2,
                                  SKU3,
                                  SKU4,
                                  SKU5,
                                  UPC,
                                  SourceSystem,
                                  --LPN,
                                  Location,
                                  Ownership,
                                  Lot,
                                  InventoryClass1,
                                  InventoryClass2,
                                  InventoryClass3,
                                  Warehouse,
                                  --LPNType,
                                  --LPNTypeDescription,
                                  OnhandStatus,
                                  Quantity,
                                  AvailableQty,
                                  ReservedQty,
                                  ReceivedQty,
                                  BusinessUnit,
                                  RecordId
                                  )
                           select SKUId,
                                  SKU,
                                  SKU1,
                                  SKU2,
                                  SKU3,
                                  SKU4,
                                  SKU5,
                                  UPC,
                                  SourceSystem, /* From SKU */
                                  --LPN,
                                  '',
                                  Ownership,
                                  Lot,
                                  InventoryClass1,
                                  InventoryClass2,
                                  InventoryClass3,
                                  DestWarehouse /* Both Warehouse, DestWarehouse in vwExportsOnhandInventory are being assigned with DestWarehouse from LPNs */,
                                  --LPNType,
                                  --LPNTypeDescription,
                                  OHStatus,
                                  sum(Quantity),
                                  sum(AvailableQty),
                                  sum(ReservedQty),
                                  sum(ReceivedQty),
                                  BusinessUnit,
                                  row_number() over (order by SKU)
                           from vwExportsOnhandInventory
                           where (coalesce(DestWarehouse, '') = coalesce(@Warehouse, DestWarehouse, '')) and
                                 (coalesce(SKU, '')           = coalesce(@SKU, SKU, '')) and
                                 (coalesce(SKU1, '')          = coalesce(@SKU1, SKU1, '')) and
                                 (coalesce(SKU2, '')          = coalesce(@SKU2, SKU2, '')) and
                                 (coalesce(SKU3, '')          = coalesce(@SKU3, SKU3, '')) and
                                 (coalesce(SKU4, '')          = coalesce(@SKU4, SKU4, '')) and
                                 (coalesce(SKU5, '')          = coalesce(@SKU5, SKU5, '')) and
                                 (coalesce(SourceSystem, 'HOST')
                                                              = coalesce(@SourceSystem, 'HOST')) and
                                 (coalesce(Ownership, '')     = coalesce(@Ownership, Ownership, ''))
                           group by SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, UPC, SourceSystem, /* LPN , Location, */ Ownership, Lot, InventoryClass1, InventoryClass2, InventoryClass3, DestWarehouse , /* LPNType, LPNTypeDescription, */ OHStatus, BusinessUnit
                           having sum(Quantity) > 0;

  select @vSKUCount = @@rowcount;

  /* Insert data related to 'New' and 'Waved' status orders into temp table */
  insert into @ttOrderedQty (SKUId,
                             Ownership,
                             Warehouse,
                             UnitsToAllocate)
                      select OD.SKUId,
                             OH.Ownership,
                             OH.Warehouse,
                             sum(OD.UnitsToAllocate)
                      from OrderHeaders OH with (nolock)
                        join OrderDetails OD with (nolock) on (OD.OrderId = OH.OrderId)
                      where (OH.Archived = 'N') and
                            (OH.Status not in ('S', 'D', 'X' /* Shipped, Completed, Canceled */)) and
                            (OH.OrderType not in ('R', 'RP', 'RU', 'B'  /* Regular/Partial, Replenish Cases, Replenish Units, Bulk Pull */))
                      group by OD.SKUId, OH.Ownership, OH.Warehouse;

  /* Update @ttOnhandInventory temp table with UnitsOrdered qty*/
  update OHI
  set OHI.UnitsToFulfill = OQ.UnitsToAllocate
  from @ttOnhandInventory OHI
     join @ttOrderedQty OQ on (OHI.SKUId     = OQ.SKUId) and
                              (OHI.Ownership = OQ.Ownership) and
                              (OHI.Warehouse = OQ.Warehouse);

  if (@OutputZeroQtySKUs = 1 /* Yes */)
    begin
      /* If any of SKU components are given, then return only data for those */
      insert into @ttOnhandInventory (SKU,
                                      SKU1,
                                      SKU2,
                                      SKU3,
                                      SKU4,
                                      SKU5,
                                      UPC,
                                      Location,
                                      Ownership,
                                      Lot,
                                      InventoryClass1,
                                      InventoryClass2,
                                      InventoryClass3,
                                      Warehouse,
                                      Quantity,
                                      BusinessUnit,
                                      RecordId)
                               select S.SKU,
                                      S.SKU1,
                                      S.SKU2,
                                      S.SKU3,
                                      S.SKU4,
                                      S.SKU5,
                                      S.UPC,
                                      '',
                                      '',
                                      OHI.Lot,
                                      OHI.InventoryClass1,
                                      OHI.InventoryClass2,
                                      OHI.InventoryClass3,
                                      '',
                                      '0',
                                      S.BusinessUnit,
                                      @vSKUCount + row_number() over (order by S.SKU)
                               from SKUs S
                                  left outer join @ttOnhandInventory OHI on (S.SKU = OHI.SKU)
                               where (OHI.SKU is null) and (S.Status = 'A') and
                                     (coalesce(S.SKU,  '')          = coalesce(@SKU,  S.SKU,  '')) and
                                     (coalesce(S.SKU1, '')          = coalesce(@SKU1, S.SKU1, '')) and
                                     (coalesce(S.SKU2, '')          = coalesce(@SKU2, S.SKU2, '')) and
                                     (coalesce(S.SKU3, '')          = coalesce(@SKU3, S.SKU3, '')) and
                                     (coalesce(S.SKU4, '')          = coalesce(@SKU4, S.SKU4, '')) and
                                     (coalesce(S.SKU5, '')          = coalesce(@SKU5, S.SKU5, '')) and
                                     (coalesce(S.Ownership, '')     = coalesce(@Ownership, S.Ownership, ''));
    end

  /* Returning the dataset from temp table by formating the OnhandStatus and quantity */

  /* Note: For all intents and purposes what we consider to have 'OnhandQty'
           whatever is in the DC and in inventory. 'Received' is not yet
           acknowledged as in DC as it is not yet located. 'Reserved' is also
           technically considered 'OnhandQty' until is shipped out (at which time
           it becomes unavailable anyhow) */
  set @XmlResult = (select coalesce(SKU,  '') as SKU,
                           coalesce(SKU1, '') as SKU1,
                           coalesce(SKU2, '') as SKU2,
                           coalesce(SKU3, '') as SKU3,
                           coalesce(SKU4, '') as SKU4,
                           coalesce(SKU5, '') as SKU5,
                           coalesce(UPC, '')  as UPC,
                           coalesce(SourceSystem, '') as SourceSystem,
                           coalesce(LPN,  '') as LPN,
                           coalesce(Location,  '') as Location,
                           coalesce(Ownership, '') as Ownership,
                           coalesce(Lot,       '') as LotNumber,
                           coalesce(InventoryClass1, '') as InventoryClass1,
                           coalesce(InventoryClass2, '') as InventoryClass2,
                           coalesce(InventoryClass3, '') as InventoryClass3,
                           coalesce(Warehouse, '') as Warehouse,
                           coalesce(ExpiryDate, '') as ExpiryDate,
                           '' as LPNType,
                           '' as LPNTypeDescription,
                           coalesce(AvailableQty,  0) as AvailableQty,
                           coalesce(ReservedQty,   0) as ReservedQty,
                           coalesce(OnhandQty,     0) as OnhandQty,
                           coalesce(ReceivedQty,   0) as ReceivedQty,
                           coalesce(AvailableQty, 0) - coalesce(UnitsToFulfill, 0) as OnhandAvailableQty,
                           coalesce(BusinessUnit, '') as BusinessUnit,
                           current_timestamp as TransDateTime
                    from @ttOnhandInventory
                    for XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  /* Build the exports result set based on control of client choice */
  if (@vAddExportsMsgHeader = 'Y')
    begin
      /* Build MsgHeader node for exports */
      select @xmlExportsMsgHeader = dbo.fn_XMLNode('msgHeader', dbo.fn_XMLNode('SchemaName', 'RFCL_DataExport') +
                                                                dbo.fn_XMLNode('SchemaVersion', '1.0') +
                                                                dbo.fn_XMLNode('msgSubject', 'ExportOnhandInv') +
                                                                dbo.fn_XMLNode('msgAttribute', 'OnhandInvExp') +
                                                                dbo.fn_XMLNode('msgType', 'InventOnHandXML') +
                                                                dbo.fn_XMLNode('msgFrom', 'CIMS') +
                                                                dbo.fn_XMLNode('CompanyId', @vBusinessUnit) +
                                                                dbo.fn_XMLNode('msgGuid', @vBusinessUnit + 'Export') +
                                                                dbo.fn_XMLNode('Ownership', @Ownership) +
                                                                dbo.fn_XMLNode('EDIVersion', '') +
                                                                dbo.fn_XMLNode('EDISequenceNumber', '') +
                                                                dbo.fn_XMLNode('DataUsage', 'T') +
                                                                dbo.fn_XMLNode('EDIFunctionalCode', '') +
                                                                dbo.fn_XMLNode('TimeStamp', (select convert(varchar, (select current_timestamp), 126)))
                                                  );

      select @XmlResult = '<msg>' + convert(varchar(max), @xmlExportsMsgHeader) + convert(varchar(max), @xmlResult) + '</msg>';
    end
  else
    begin
      select @XmlResult = '<msg>' + convert(varchar(max), @XmlResult)  + '</msg>';
    end

ErrorHandler:
  exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_OnhandInventory */

Go
