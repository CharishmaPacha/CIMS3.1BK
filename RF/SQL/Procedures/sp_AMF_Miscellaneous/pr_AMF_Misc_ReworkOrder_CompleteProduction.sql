/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_AMF_Misc_ReworkOrder_CompleteProduction (HA-832)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Misc_ReworkOrder_CompleteProduction') is not null
  drop Procedure pr_AMF_Misc_ReworkOrder_CompleteProduction;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Misc_ReworkOrder_CompleteProduction: Transfers Inv from work in progress
    warehoue to contractor Warehouse and changes the SKU.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Misc_ReworkOrder_CompleteProduction
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit              TBusinessUnit,
          @vUserId                    TUserId,
          @vDeviceId                  TDeviceId,
          @vOrderId                   TRecordId,
          @vPickTicket                TPickTicket,
          @vScannedQty                TQuantity,
          @vScannedSKUId              TRecordId,
          @vScannedSKU                TSKU,
          @vOperation                 TOperation;
          /* Functional variables */
  declare @vxmlOrderDetails           xml,
          @vxmlOrderInfo              xml,
          @vOrderDetailsXML           TXML,
          @vOrderInfoXML              TXML,
          @vSuggestedSKU              TSKU,
          @vSuggestedQty              TQuantity,
          @vCurrSortOrder             TDescription,
          @vMode                      TControlCode,
          @vSuccessMessage            TMessage,

          @vUnitsToAllocate           TQuantity,

          @vWaveId                    TRecordId,
          @vWaveNo                    TWaveNo,
          @vWarehouse                 TWarehouse,

          @vToLocationId              TRecordId,
          @vToLocation                TLocation,
          @vToLocWarehouse            TWarehouse;

  declare @ttOrderDetailsToAllocate   TOrderDetailsToAllocateTable;

begin /* pr_AMF_Misc_ReworkOrder_CompleteProduction */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Fetch the input values */
  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]',           'TBusinessUnit'   ),
         @vUserId        = Record.Col.value('(SessionInfo/UserName)[1]',               'TUserId'         ),
         @vDeviceId      = Record.Col.value('(SessionInfo/DeviceId)[1]',               'TDeviceId'       ),
         @vOrderId       = Record.Col.value('(Data/m_OrderInfo_OrderId)[1]',           'TRecordId'       ),
         @vPickTicket    = Record.Col.value('(Data/m_OrderInfo_PickTicket)[1]',        'TPickTicket'     ),
         @vScannedQty    = Record.Col.value('(Data/NewUnits1)[1]',                     'TQuantity'       ),
         @vScannedSKUId  = Record.Col.value('(Data/SKUId)[1]',                         'TRecordId'       ),
         @vScannedSKU    = Record.Col.value('(Data/SKU)[1]',                           'TSKU'            ),
         @vCurrSortOrder = Record.Col.value('(Data/SortOrder)[1]',                     'TSortOrder'      ),
         @vMode          = Record.Col.value('(Data/m_Mode)[1]',                        'TControlCode'    ),
         @vOperation     = Record.Col.value('(Data/Operation)[1]',                     'TOperation'      )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlInput = null ) );

  /* Get the UnitsToAllocate from OrderDetails */
  select @vUnitsToAllocate = UnitsToAllocate
  from OrderDetails
  where (OrderId = @vOrderId) and
        (SKUId   = @vScannedSKUId);

  /* Validate whether user given more than ToAllocateqty */
  if (@vScannedQty > @vUnitsToAllocate)
    set @vMessageName = 'AMF_QtyCannotbeGreaterThanQtyToAllocate';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Fetch the Warehouse and WaveId from the Order */
  select @vWaveId      = PickBatchId,
         @vWaveNo      = PickBatchNo,
         @vWarehouse   = Warehouse
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Get the available picklane Location in Order Warehouse, this is needed to transfer inventory
     from Re-Work In-Progress Warehouse to order Warehouse */
  select top 1 @vToLocationId   = LocationId,
               @vToLocation     = Location,
               @vToLocWarehouse = Warehouse
  from Locations
  where (Warehouse = @vWarehouse) and
        (LocationType = 'K' /* Picklane */);

  /* Create hash table if it does not exist */
  if object_id('tempdb..#OrderDetailsToAllocate') is null
    begin
      select * into #OrderDetailsToAllocate  from @ttOrderDetailsToAllocate;
      alter table #OrderDetailsToAllocate drop column KeyValue;
      alter table #OrderDetailsToAllocate add KeyValue       as cast(SKUId as varchar) + '-' + Ownership + '-' + Warehouse + '-' +
                                                              coalesce(Lot, '') + '-' + coalesce(InventoryClass1, '');
    end

  /* To Do: Process the transaction */
  insert into #OrderDetailsToAllocate (WaveId, WaveNo, OrderId, OrderType, OrderDetailId, HostOrderLine, UnitsToAllocate,
                                       SKUId, SKU, SKUABCClass, DestZone, DestLocationId, DestLocation, Ownership, Lot, Account,
                                       Warehouse, InventoryClass1, InventoryClass2, InventoryClass3,
                                       NewSKUId, NewSKU, NewInventoryClass1, NewInventoryClass2, NewInventoryClass3, SourceSystem,
                                       UDF1, UDF2, UDF3, UDF4, UDF5)
    select WaveId, WaveNo, OrderId, OrderType, OrderDetailId, HostOrderLine, coalesce(@vScannedQty, UnitsToAllocate),
           SKUId, SKU, ABCClass, DestZone, DestLocationId, DestLocation, Ownership, Lot, null /* Account */,
           Warehouse, InventoryClass1, InventoryClass2, InventoryClass3,
           NewSKUId, NewSKU, NewInventoryClass1, NewInventoryClass2, NewInventoryClass3, SourceSystem,
           ODUDF1, ODUDF2, ODUDF3, ODUDF4, ODUDF5 /* UDFs */
    from vwWaveDetailsToAllocate WD
    where (WaveId  = @vWaveId) and
          (SKUId   = @vScannedSKUId);

  /* Invoke proc that transfers the inventory that is required for the order from
     work in progress Warehouse to the order Warehouse */
  exec pr_OrderHeaders_ReworkCompleted @vToLocationId, @vOperation, @vBusinessUnit, @vUserId;

  /* Get the success message, AT to be shown to user as success message */
  select top 1 @vSuccessMessage = Comment
  from vwATEntity
  where (EntityId   = @vOrderId) and
        (ActivityType in ('CompleteRework'))
  order by AuditId desc;

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);

  /* Get the necessary info to show in the screen */
  exec pr_AMF_Info_GetOrderInfoXML @vOrderId, 'OD' /* Order Details */, null /* Operation */ ,
                                   @vOrderInfoXML output, @vOrderDetailsXML output;

  /* Get the SKU and Quantity to suggest to user */
  if (coalesce(@vCurrSortOrder, '') <> '')
    select top 1 @vSuggestedSKU = SKU,
                 @vSuggestedQty = Quantity
    from #DataTableSKUDetails
    where (SortOrder  > @vCurrSortOrder)

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', @vOrderInfoXML + @vOrderDetailsXML +
                                           dbo.fn_XmlNode('Mode',              @vMode) +
                                           dbo.fn_XMLNode('SuggestedSKU',      @vSuggestedSKU) +
                                           dbo.fn_XMLNode('SuggestedQuantity', @vSuggestedQty));

end /* pr_AMF_Misc_ReworkOrder_CompleteProduction */

Go

