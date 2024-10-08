/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/26  RIA     Added pr_AMF_Shipping_CancelShipCartons_Confirm, pr_AMF_Shipping_CancelShipCartons_Validate (HA-2087)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_CancelShipCartons_Validate') is not null
  drop Procedure pr_AMF_Shipping_CancelShipCartons_Validate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_CancelShipCartons_Validate: Validates the scanned lpn
    and gives the response to show the information required

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_CancelShipCartons_Validate
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
          @vScannedLPN               TLPN,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNType                  TTypeCode,
          @vStatus                   TStatus,
          @vValidLPNStatuses         TControlValue,
          @vOrderId                  TRecordId,
          @vWaveId                   TRecordId,
          @vWaveType                 TTypeCode,
          @vAutoConfirmWavetypes     TControlValue,

          @vLoggedInWarehouse        TWarehouse,
          @vLPNDestWarehouse         TWarehouse,

          @vxmlLPNInfo               xml,
          @vxmlLPNDetails            xml,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vOrderInfoXML             TXML;
begin /* pr_AMF_Shipping_CancelShipCartons_Validate */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vScannedLPN   = Record.Col.value('(Data/LPN)[1]',                        'TLPN'         ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the LPN info */
  select @vLPNId            = LPNId,
         @vLPN              = LPN,
         @vLPNType          = LPNType,
         @vStatus           = Status,
         @vOrderId          = OrderId,
         @vWaveId           = PickBatchId,
         @vLPNDestWarehouse = DestWarehouse
  from LPNs
  where  (LPNId = dbo.fn_LPNs_GetScannedLPN (@vScannedLPN, @vBusinessUnit, 'LTU'));

  /* Fetch Wave details */
  select @vWaveType = WaveType
  from Waves
  where (WaveId = @vWaveId);

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@vDeviceId, @vUserId, @vBusinessUnit);

  /*Get control values*/
  select @vValidLPNStatuses       = dbo.fn_Controls_GetAsString('LPNShipCartonCancel', 'ValidLPNStatus', 'F,K,D,E' /* New Temp, Picked, Packed & Staged */,
                                                                @vBusinessUnit, @vUserId),
         @vAutoConfirmWavetypes   = dbo.fn_Controls_GetAsString('LPNShipCartonCancel', 'AutoConfirmWaves', 'CP,BCP' /* default: CasePick/BulkCasePick */,
                                                                @vBusinessUnit, @vUserId);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vLPNType <> 'S' /* ShipCarton */)
    set @vMessageName = 'InvalidLPNType';
  else
  if (charindex(@vStatus , @vValidLPNStatuses) = 0)
    set @vMessageName = 'InvalidLPNStatus';
  else
  if (@vLoggedInWarehouse <> @vLPNDestWarehouse)
    set @vMessageName = 'LPNWarehouseMismatch';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Flag to proceed to confirm skipping user interaction */
  if (dbo.fn_IsInList(@vWaveType, @vAutoConfirmWavetypes) > 0)
    begin
      exec pr_AMF_Shipping_CancelShipCartons_Confirm @InputXML, @DataXML output, @UIInfoXML output,
                                                     @InfoXML output, @ErrorXML output;
      return;
    end

  /* As the validations are passed, call the LPNInfo proc to build needed info */
  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, 'LPNDetails' /* LPNDetails */, @vOperation,
                                 @vLPNInfoXML output, @vLPNDetailsXML output;

  /* Get the order related information */
  exec pr_AMF_Info_GetOrderInfoXML @vOrderId, 'N' /* No Details */, @vOperation, @vOrderInfoXML output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLPNInfoXML + @vLPNDetailsXML +
                                           coalesce(@vOrderInfoXML,  ''));

end /* pr_AMF_Shipping_CancelShipCartons_Validate */

Go

