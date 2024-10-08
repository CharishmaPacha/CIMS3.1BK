/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/10  RIA     pr_AMF_Receiving_StartReceiving, pr_AMF_Receiving_ReceiveToLPNOrLOC: Get SKU info
  2020/04/30  MS      pr_AMF_Receiving_ReceiveToLPNOrLOC, pr_AMF_Receiving_StartReceiving: Changes to send ReceiverNumber (HA-228)
  2020/04/20  RIA     pr_AMF_Receiving_StartReceiving, pr_AMF_Receiving_ReceiveToLPNOrLOC: Changes to send ReceiverNumber (HA-191)
  2020/04/17  RIA     pr_AMF_Receiving_ReceiveToLPNOrLOC: Changes to ReceiveToLoc caller (HA-200)
  2020/04/15  MS      pr_AMF_Receiving_StartReceiving, pr_AMF_Receiving_ReceiveToLPNOrLOC: Changes to send Location as Input Param (HA-187)
  2020/03/30  RIA     pr_AMF_Receiving_ReceiveToLPNOrLOC: Changes (CIMSV3-754)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Receiving_ReceiveToLPNOrLOC') is not null
  drop Procedure pr_AMF_Receiving_ReceiveToLPNOrLOC;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Receiving_ReceiveToLPNOrLOC:
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Receiving_ReceiveToLPNOrLOC
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
          @vReceiptId                TRecordId,
          @vReceiptNumber            TReceiptNumber,
          @vReceiverNumber           TReceiverNumber,
          @vScannedSKU               TSKU,
          @vInnerPacks               TInnerPacks,
          @vUnitsPerIP               TQuantity,
          @vUnits                    TQuantity,
          @vUnits1                   TQuantity,
          @vLPN                      TLPN,
          @vLocation                 TLocation,
          @vReceivingWH              TWarehouse,
          @vReceivingLocation        TLocation,
          @vReceivingPallet          TPallet,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vReceiptInfoXML           TXML,
          @vReceiptDetailsXML        TXML,
          @vxmlResultData            xml,
          @vLPNId                    TRecordId,
          @vLPNDetailId              TRecordId,
          @vQuantity                 TQuantity,
          @vQtyToReceive             TQuantity,
          @vTotalLPNs                TCount,
          @vTotalUnits               TCount,
          @vLPNsReceived             TCount,
          @vQtyReceived              TCount,
          @vLPNsInTransit            TCount,
          @vSKU                      TSKU,
          @vSuggestedSKU             TSKU,
          @vSKUQty                   TQuantity,
          @vCurrSortOrder            TDescription,
          @vMode                     TControlCode;
begin /* pr_AMF_Receiving_ReceiveToLPNOrLOC */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',           'TBusinessUnit'  ),
         @vUserId            = Record.Col.value('(SessionInfo/UserName)[1]',               'TUserId'        ),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',               'TDeviceId'      ),
         @vReceiptId         = Record.Col.value('(Data/m_ReceiptInfo_ReceiptId)[1]',       'TRecordId'      ),
         @vReceiptNumber     = Record.Col.value('(Data/m_ReceiptInfo_ReceiptNumber)[1]',   'TReceiptNumber' ),
         @vReceiverNumber    = Record.Col.value('(Data/m_ReceiverNumber)[1]',              'TReceiverNumber'),
         @vScannedSKU        = Record.Col.value('(Data/SKU)[1]',                           'TSKU'           ),
         @vInnerPacks        = nullif(Record.Col.value('(Data/NewInnerPacks)[1]',          'TInnerPacks'    ), ''),
         @vUnitsPerIP        = nullif(Record.Col.value('(Data/NewUnitsPerInnerPack)[1]',   'TQuantity'      ), ''),
         @vUnits             = nullif(Record.Col.value('(Data/NewUnits)[1]',               'TQuantity'      ), ''),
         @vUnits1            = nullif(Record.Col.value('(Data/NewUnits1)[1]',              'TQuantity'      ), ''),
         @vLPN               = nullif(Record.Col.value('(Data/LPN)[1]',                    'TLPN'           ), ''),
         @vLocation          = Record.Col.value('(Data/Location)[1]',                      'TLocation'      ),
         @vReceivingWH       = Record.Col.value('(Data/m_ReceivingWH)[1]',                 'TWarehouse'     ),
         @vReceivingLocation = Record.Col.value('(Data/m_ReceivingLocation)[1]',           'TLocation'      ),
         @vReceivingPallet   = Record.Col.value('(Data/m_ReceivingPallet)[1]',             'TPallet'        ), -- future use
         @vCurrSortOrder     = Record.Col.value('(Data/SortOrder)[1]',                     'TSortOrder'     ),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                     'TOperation'     ),
         @vMode              = Record.Col.value('(Data/m_Mode)[1]',                        'TControlCode'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* set the quantity value */
  set @vQuantity = coalesce(@vUnits, @vUnits1); -- this should be done based upon receiving uom

  /* call the V2 proc */
  if (@vOperation = 'ReceiveToLPN')
    exec pr_RFC_ReceiveToLPN @vReceiptId, @vReceiptNumber, null /* ReceiptDetailId */, null /* ReceiptLine */,
                             null /* SKUId */, @vScannedSKU, @vInnerPacks, @vQuantity, null /* UoM */,
                             null /* LPNId */, @vLPN, null /* CustPO */, @vReceiverNumber output/* PackingSlip */,
                             @vReceivingWH, @vReceivingLocation, @vReceivingPallet,
                             @vBusinessUnit, @vUserId, @vDeviceId;
  else
    exec pr_RFC_ReceiveToLocation @vReceiptId, @vReceiptNumber, null /* ReceiptDetailId */, null /* ReceiptLine */,
                                  null /* SKUId */, @vScannedSKU, @vInnerPacks, @vQuantity, null /* CustPO */,
                                  @vReceiverNumber output/* PackingSlip */, null /* LocationId */, @vReceivingWH,
                                  @vLocation /* Location */, @vBusinessUnit, @vUserId, @vDeviceId;

  /* Get the result dataxml */
  select @vxmlResultData = convert(xml, CurrentResponse)
  from Devices
  where (DeviceId = (@vDeviceId + '@' + @vUserId));

  /*  Read inputs from InputXML */
  select @vLPNId        = Record.Col.value('LPNId[1]',           'TRecordId'),
         @vLPNDetailId  = Record.Col.value('LPNDetailId[1]',     'TRecordId')
  from @vxmlResultData.nodes('/LPNDetails') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlResultData = null));

  /* Build Success Message */
  select top 1 @vMessage = Comment
  from vwATEntity
  where (EntityId     = @vLPNId) and
        (ActivityType in ('ReceiveToLPN', 'ReceiveToLocation'))
  order by AuditId desc;

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* If there are no LPNs left to be received then return */
  if (@vQtyToReceive = 0)
    begin
      select @vMessage = dbo.fn_Messages_Build('AMF_AllUnitsReceivedAgainstTheReceipt', @vReceiptNumber, null, null, null, null);
      select @InfoXML  = dbo.fn_AMF_BuildSuccessXML(@vMessage);
      select @DataXML  = dbo.fn_XmlNode('Data', dbo.fn_XmlNode('QtyToReceive', @vQtyToReceive));
      return;
    end

  /* get the Receipt Info */
  exec pr_AMF_Info_GetROInfoXML @vReceiptId, 'Y', @vOperation, @vReceiptInfoXML output,
                                @vReceiptDetailsXML output;

  /* Get the SKU and Quantity to suggest to user while receiving */
  if (coalesce(@vCurrSortOrder, '') <> '')
  select top 1 @vSuggestedSKU  = SKU,
               @vSKUQty        = Quantity
  from #DataTableSKUDetails
  where (Quantity   > 0) and
        (SortOrder  >= @vCurrSortOrder)

  /* If SKU is not returned then considering it as 1st/initial scan */
  if (@vSuggestedSKU is null)
    select top 1 @vSuggestedSKU  = SKU,
                 @vSKUQty        = Quantity
    from #DataTableSKUDetails
    where Quantity > 0
    order by SortOrder;

  /* Build the DataXML */
  /* We need the initially scanned location to update it on the LPN */
  select @DataXML = dbo.fn_XmlNode('Data', @vReceiptInfoXML + @vReceiptDetailsXML +
                                           dbo.fn_XmlNode('ReceiverNumber',    @vReceiverNumber) +
                                           dbo.fn_XmlNode('ReceivingWH',       @vReceivingWH) +
                                           dbo.fn_XmlNode('ReceivingLocation', @vReceivingLocation) +
                                           dbo.fn_XmlNode('ReceivingPallet',   @vReceivingPallet) +
                                           dbo.fn_XmlNode('Mode',              @vMode) +
                                           dbo.fn_XMLNode('SuggestedSKU',      @vSuggestedSKU) +
                                           dbo.fn_XMLNode('Quantity',          @vSKUQty));

end /* pr_AMF_Receiving_ReceiveToLPNOrLOC */

Go

