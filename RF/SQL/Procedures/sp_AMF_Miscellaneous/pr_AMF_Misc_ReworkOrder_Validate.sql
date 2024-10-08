/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/17  RIA     Added: pr_AMF_Misc_ReworkOrder_Validate, pr_AMF_Misc_ReworkOrder_Pause and
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Misc_ReworkOrder_Validate') is not null
  drop Procedure pr_AMF_Misc_ReworkOrder_Validate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Misc_ReworkOrder_Validate: Validates the PickTicket scanned
    and returns the order details.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Misc_ReworkOrder_Validate
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
          @vPickTicket                TPickTicket,
          @vOperation                 TOperation;
          /* Functional variables */
  declare @vOrderInfoXML              TXML,
          @vOrderDetailsXML           TXML,
          @vOrderId                   TRecordId,
          @vValidPickTicket           TPickTicket,
          @vOrderStatus               TStatus,
          @vOrderType                 TOrderType,
          @vOrderWH                   TWarehouse,
          @vSuggestedSKU              TSKU,
          @vSuggestedQty              TQuantity,
          @vMode                      TControlCode;
begin /* pr_AMF_Misc_ReworkOrder_Validate */

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
         @vPickTicket    = Record.Col.value('(Data/PickTicket)[1]',                    'TPickTicket'     ),
         @vOperation     = Record.Col.value('(Data/Operation)[1]',                     'TOperation'      )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlInput = null ) );

  /* Get the OrderId and Status */
  select @vOrderId         = OrderId,
         @vValidPickTicket = PickTicket,
         @vOrderStatus     = Status,
         @vOrderType       = OrderType,
         @vOrderWH         = Warehouse
  from OrderHeaders
  where (PickTicket   = @vPickTicket) and
        (BusinessUnit = @vBusinessUnit);

  /* Validations */
  if (coalesce(@vPickTicket, '') = '')
    set @vMessageName = 'PickTicketIsRequired';
  else
  if (@vOrderId is null)
    set @vMessageName = 'PickTicketDoesNotExist';
  else
  if (@vOrderType <> 'RW' /* Rework */)
    set @vMessageName = 'NotReworkOrder'
  else
  if (@vOrderStatus = 'S' /* Shipped */)
    set @vMessageName = 'OrderAlreadyShipped';
  else
  if (@vOrderStatus = 'X' /* Canceled */)
    set @vMessageName = 'OrderAlreadyCanceled';
  else
  if (@vOrderStatus = 'D' /* Completed */)
    set @vMessageName = 'OrderAlreadyCompleted';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* We will have different modes while processing rework , so fetch the mode from controls */
  /* Currently we have two modes, one is scan mode and the other is suggested. where
     in scan mode user has to scan the entity and proceed, in suggested mode system will
     suggest the entity to user and they need not scan/enter */
  select @vMode =  dbo.fn_Controls_GetAsString(@vOperation, 'Mode', 'ScanMode' /* default */, @vBusinessUnit, @vUserId);

  /* Get the necessary info to show in the screen */
  exec pr_AMF_Info_GetOrderInfoXML @vOrderId, 'OD' /* Order Details */, @vOperation,
                                   @vOrderInfoXML output, @vOrderDetailsXML output;

  /* If Mode is suggested, then find the SKU and Qty to suggest to user */
  if (@vMode = 'Suggested')
    select top 1 @vSuggestedSKU = SKU,
                 @vSuggestedQty = Quantity
    from #DataTableSKUDetails
    where Quantity2 > 0
    order by SortOrder;

  /* Build the data xml */
  select @DataXml = dbo.fn_XMLNode('Data', @vOrderInfoXML + @vOrderDetailsXML +
                                           dbo.fn_XmlNode('Mode',              @vMode) +
                                           dbo.fn_XMLNode('SuggestedSKU',      @vSuggestedSKU) +
                                           dbo.fn_XMLNode('SuggestedQuantity', @vSuggestedQty));

end /* pr_AMF_Misc_ReworkOrder_Validate */

Go

