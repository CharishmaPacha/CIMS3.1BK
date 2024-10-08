/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/10  RIA     pr_AMF_Receiving_StartReceiving, pr_AMF_Receiving_ReceiveToLPNOrLOC: Get SKU info
  2020/05/13  RIA     pr_AMF_Receiving_StartReceiving: Get ReceiverNumber by using joins instead of views (HA-395)
  2020/04/30  MS      pr_AMF_Receiving_ReceiveToLPNOrLOC, pr_AMF_Receiving_StartReceiving: Changes to send ReceiverNumber (HA-228)
  2020/04/20  RIA     pr_AMF_Receiving_StartReceiving, pr_AMF_Receiving_ReceiveToLPNOrLOC: Changes to send ReceiverNumber (HA-191)
  2020/04/15  MS      pr_AMF_Receiving_StartReceiving, pr_AMF_Receiving_ReceiveToLPNOrLOC: Changes to send Location as Input Param (HA-187)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Receiving_StartReceiving') is not null
  drop Procedure pr_AMF_Receiving_StartReceiving;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Receiving_StartReceiving: This is the first step of the Receiving
    process, where in user gives the information of the Receipt they are trying to
    process and we validate and respond back with the details.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Receiving_StartReceiving
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vReceiptNumber            TReceiptNumber,
          @vReceiverNumber           TReceiverNumber,
          @vROHReceiverNumber        TReceiverNumber,
          @vOperation                TOperation,
          @vWarehouse                TWarehouse,
          @vLocation                 TLocation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vReceiptInfoXML           TXML,
          @vReceiptDetailsXML        TXML,
          @vReceiptId                TRecordId,
          @vQtyToReceive             TQuantity,
          @vTotalLPNs                TCount,
          @vTotalUnits               TCount,
          @vLPNsReceived             TCount,
          @vQtyReceived              TCount,
          @vLPNsInTransit            TCount,
          @vSuggestedSKU             TSKU,
          @vSKUQty                   TQuantity,
          @vMode                     TControlCode;
begin /* pr_AMF_Receiving_StartReceiving */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */-- This can be ignored
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ),
         @vReceiptNumber   = nullif(Record.Col.value('(Data/ReceiptNumber)[1]',       'TReceiptNumber' ), ''),
         @vReceiverNumber  = nullif(Record.Col.value('(Data/ReceiverNumber)[1]',      'TReceiverNumber'), ''),
         @vWarehouse       = Record.Col.value('(Data/Warehouse)[1]',                  'TWarehouse'     ),
         @vLocation        = Record.Col.value('(Data/ReceivingLocation)[1]',          'TLocation'      ),
         @vOperation       = Record.Col.value('(Data/Operation)[1]',                  'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Build the input for V2 procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ) as BusinessUnit,
                                     nullif(Record.Col.value('(Data/ReceiverNumber)[1]',      'TReceiverNumber'), '') as ReceiverNumber,
                                     nullif(Record.Col.value('(Data/ReceiptNumber)[1]',       'TReceiptNumber' ), '') as ReceiptNumber,
                                     nullif(Record.Col.value('(Data/CustPO)[1]',              'TCustPO'        ), '') as CustPO,
                                     nullif(Record.Col.value('(Data/Warehouse)[1]',           'TWarehouse'     ), '') as Warehouse,
                                     Record.Col.value('(Data/ReceivingLocation)[1]',          'TLocation'      ) as ReceiveToLocation,
                                     Record.Col.value('(Data/ValidateOption)[1]',             'TFlag'          ) as ValidateOption,
                                     Record.Col.value('(Data/Operation)[1]',                  'TOperation'     ) as Operation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ValidateReceiptInput'), elements);

  /* call the V2 proc */
  exec pr_RFC_ValidateReceipt @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* We will have different modes while receiving , so fetch the mode from controls */
  /* Currently we have two modes, one is scan mode and the other is suggested. where
     in scan mode user has to scan the entity and proceed, in suggested mode system will
     suggest the entity to user and they need not scan/enter */
  select @vMode =  dbo.fn_Controls_GetAsString(@vOperation, 'Mode', 'ScanMode' /* default */, @vBusinessUnit, @vUserId);

  /* Fetch the details */
  select @vReceiptNumber  = ReceiptNumber,
         @vReceiptId      = ReceiptId
  from ReceiptHeaders
  where (ReceiptNumber = @vReceiptNumber) and
        (BusinessUnit  = @vBusinessUnit);

  /* If we have Open receiver for the Receipt, then use it */
  select top 1 @vROHReceiverNumber = R.ReceiverNumber
  from ReceivedCounts RC
    join Receivers R on (RC.ReceiverId = R.ReceiverId)
  where (RC.ReceiptId  = @vReceiptId) and
        (R.Status      = 'O' /* Open */) and
        (convert(Date, R.CreatedDate) = cast(getdate() as Date));

  /* If user given receiver display it, else use Receiver exists for Receipt */
  select @vReceiverNumber = coalesce(@vReceiverNumber, @vROHReceiverNumber);

  /* get the Receipt Info */
  exec pr_AMF_Info_GetROInfoXML @vReceiptId, 'Y', @vOperation,
                                @vReceiptInfoXML output, @vReceiptDetailsXML output;

  /* Fetch the SKU */
  select top 1 @vSuggestedSKU  = SKU,
               @vSKUQty        = Quantity
  from #DataTableSKUDetails
  where Quantity > 0
  order by SortOrder;

  /* Build the DataXML */
  /* We'll be using the scanned location as it is already validated */
  select @DataXML = dbo.fn_XmlNode('Data', @vReceiptInfoXML + @vReceiptDetailsXML +
                                           dbo.fn_XmlNode('ReceiverNumber',    @vReceiverNumber) +
                                           dbo.fn_XmlNode('ReceivingLocation', @vLocation) +
                                           dbo.fn_XmlNode('ReceivingWH',       @vWarehouse) +
                                           dbo.fn_XmlNode('Mode',              @vMode) +
                                           dbo.fn_XMLNode('SuggestedSKU',      @vSuggestedSKU) +
                                           dbo.fn_XMLNode('Quantity',          @vSKUQty));

end /* pr_AMF_Receiving_StartReceiving */

Go

