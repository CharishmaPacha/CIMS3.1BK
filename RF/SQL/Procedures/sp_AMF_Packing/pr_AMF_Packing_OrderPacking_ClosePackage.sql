/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Packing_OrderPacking_ClosePackage') is not null
  drop Procedure pr_AMF_Packing_OrderPacking_ClosePackage;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Packing_OrderPacking_ClosePackage:

  After user scans the LPN, CartonType and Weight and closes the package, this
  proc will be called where we'll call the pr_Packing_CloseLPN proc to close the
  package
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Packing_OrderPacking_ClosePackage
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
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vOrderId                  TRecordId,
          @vPickTicket               TPickTicket,
          @vCartonType               TCartonType,
          @vWeight                   TFloat,
          @vAction                   TAction,
          @vScannedEntity            TEntity,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPackInfoXML              TXML,
          @vPackDetailsXML           TXML,
          @vxmlPackDetails           xml,
          @vLocationId               TRecordId,
          @vLocationType             TLocationType,
          @vLocationStatus           TStatus,
          @vCustomer                 TName,
          @vLPNToPrintId             TRecordId,
          @vLPNToPrint               TLPN,
          @vShipTo                   TShipToId,
          @vShipVia                  TShipVia,
          @vSKUsPacked               TInteger,
          @vPackedQty                TWeight,
          @vXmlDocHandle             TInteger,
          @vMessage                  TMessage,
          @vTaskId                   TRecordId,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Packing_OrderPacking_ClosePackage */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',     'TBusinessUnit'),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',         'TUserId'      ),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',         'TDeviceId'    ),
         @vAction           = Record.Col.value('(Data/Action)[1]',                  'TAction'      ),
         @vOrderId          = Record.Col.value('(Data/m_OrderId)[1]',               'TRecordId'    ),
         @vLPN              = nullif(Record.Col.value('(Data/ToLPN)[1]',            'TLPN'         ), '' ),
         @vCartonType       = Record.Col.value('(Data/CartonType)[1]',              'TCartonType'  ),
         @vWeight           = Record.Col.value('(Data/Weight)[1]',                  'TFloat'       ),
         @vOperation        = Record.Col.value('(Data/Operation)[1]',               'TOperation'   )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Validations */

  /* Fetch the Packed Details */
  select @vxmlPackDetails = @vxmlInput.query('Root/Data/m_PackingCarton/*');
  select @vPackDetailsXML = coalesce(convert(varchar(max), @vxmlPackDetails), '');
  select @vPackDetailsXML = dbo.fn_XMLNode('PackingCarton', @vPackDetailsXML)

  /* Call the V2 proc */
  exec pr_Packing_CloseLPN @vCartonType, null /* PalletId */, null /* FromLPNId */, @vOrderId,
                           @vWeight, null /* Volume */, @vPackDetailsXML, @vLPN, null /* ReturnTrackingNo */,
                           null /* PackStation */, @vAction, @vBusinessUnit, @vUserId, @vrfcProcOutputxml output;

  select @vxmlRFCProcOutput = cast(@vrfcProcOutputxml as xml);

  /* read the success message */
  select @vSuccessMessage = Record.Col.value('(Message/ResultMessage)[1]',   'TMessage'),
         @vLPNToPrint     = Record.Col.value('(LPNInfo/LPN)[1]',             'TLPN'    )
  from @vxmlRFCProcOutput.nodes('/PackingCloseLPNInfo') as Record(Col);

  /* Build Success Message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);

  /* Print the label */
  exec pr_Printing_EntityPrintRequest 'Packing', @vOperation, 'LPN', null /* LPNId */, @vLPNToPrint,
                                      @vBusinessUnit, @vUserId, @vDeviceId, 'IMMEDIATE', default /* PrinterName */;

  /* Call the proc to build response */
  exec pr_AMF_Packing_BuildPackInfo @vOrderId, @vPickTicket, @vBusinessUnit, @vUserId, @DataXML output;

end /* pr_AMF_Packing_OrderPacking_ClosePackage */

Go

