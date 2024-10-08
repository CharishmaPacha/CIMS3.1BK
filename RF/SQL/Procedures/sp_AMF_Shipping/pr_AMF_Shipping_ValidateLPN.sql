/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/28  RIA     pr_AMF_Shipping_ValidateLPN: Changes to get ShipVia and Carrier (CIMSV3-691)
  2020/01/23  RIA     Added pr_AMF_Shipping_CaptureTrackingNo, pr_AMF_Shipping_ValidateLPN (CIMSV3-691)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_ValidateLPN') is not null
  drop Procedure pr_AMF_Shipping_ValidateLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_ValidateLPN: Validates the scanned lpn and gives the
  response to show the information required

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_ValidateLPN
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
          @vLPN                      TLPN,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNId                    TRecordId,
          @vStatus                   TStatus,
          @vStatusDesc               TDescription,
          @vMsgEntity                TDescription,
          @vOrderId                  TRecordId,
          @vShipVia                  TShipVia,
          @vShipviaDesc              TDescription,
          @vCarrier                  TCarrier,

          @vLoggedInWarehouse        TWarehouse,
          @vLPNDestWarehouse         TWarehouse,

          @vxmlLPNInfo               xml,
          @vxmlLPNDetails            xml,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML;
begin /* pr_AMF_Shipping_ValidateLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */-- This can be ignored
  select @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vLPN          = Record.Col.value('(Data/ScannedLPN)[1]',                 'TLPN'         ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the LPN info */
  select @vLPNId            = L.LPNId,
         @vStatus           = L.Status,
         @vStatusDesc       = ST.StatusDescription,
         @vOrderId          = L.OrderId,
         @vLPNDestWarehouse = L.DestWarehouse
  from LPNs L
    join Statuses  ST on (ST.StatusCode    = L.Status) and
                         (ST.Entity        = 'LPN'   )
  where  (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLPN, @vBusinessUnit, 'LTU'));

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@vDeviceId,@vUserId,@vBusinessUnit);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vOperation = 'UpdateTrackingNoInfo') and (charindex(@vStatus , 'OCVTNJRPU') <> 0)
      select @vMessageName = 'CaptureTrackingNo_InvalidStatus',
             @vMsgEntity  = @vStatusDesc;
  else
  if (@vLoggedInWarehouse <> @vLPNDestWarehouse)
    set @vMessageName = 'LPNWarehouseMismatch';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vMsgEntity;

  /* Get the ShipVia from OrderHeaders */
  select @vShipVia = ShipVia
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Based on ShipVia get Carrier from ShipVias */
  select @vCarrier     = Carrier,
         @vShipviaDesc = Description
  from vwShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @vBusinessUnit);

  /* As the validations are passed, call the LPNInfo proc to build needed info */
  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, null /* LPNDetails */, @vOperation, @vLPNInfoXML output, @vLPNDetailsXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLPNInfoXML + @vLPNDetailsXML +
                                           dbo.fn_XMLNode('ShipViaDesc', @vShipviaDesc) +
                                           dbo.fn_XMLNode('Carrier', @vCarrier));

end /* pr_AMF_Shipping_ValidateLPN */

Go

