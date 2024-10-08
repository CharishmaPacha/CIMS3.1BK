/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/24  MS      pr_AMF_Receiving_ReceiveASN, pr_AMF_Receiving_ReceiveASNLPN: Changes to display Pallet in successmsg (JL-306)
  2020/11/05  RIA     Added pr_AMF_Receiving_ReceiveASNLPN (JL-283)
  2020/11/05  RIA     Renamed pr_AMF_Receiving_ReceiveASNLPN to pr_AMF_Receiving_ReceiveASN (JL-296)
  2020/11/02  MS      pr_AMF_Receiving_ReceiveASNLPN, pr_AMF_Receiving_ValidateASNLPN: Made changes to show ReceiverNumber (JL-291)
  2020/10/27  RIA     pr_AMF_Receiving_ReceiveASNLPN: Changes to send the Location scanned (JL-211)
  2020/10/24  MS      pr_AMF_Receiving_ReceiveASNLPN: Made changes to pass Location info (JL-210)
  2020/10/22  AJM     pr_AMF_Receiving_ReceiveASNLPN: Correction to messagename to display proper description (JL-208)
  2020/03/17  RIA     pr_AMF_Receiving_ReceiveASNLPN, pr_AMF_Receiving_ValidateEntity: Changes
  2020/03/05  RIA     pr_AMF_Receiving_ReceiveASNLPN, pr_AMF_Receiving_ValidateEntity: Changes
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Receiving_ReceiveASNLPN') is not null
  drop Procedure pr_AMF_Receiving_ReceiveASNLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Receiving_ReceiveASNLPN: ReceiveASNLPN allows for the receipt
    of an multiple ASNLPNs which could be for different ASNs. User scans Location,
    Pallet and LPN to receive the LPN onto the Pallet and/or Location.
    If LPN is associated with any Receipt we will receive the LPN or raise an error
    and also added necessary validations.
    User may be prompted to scan Pallet for each LPN or could have ability to
    receive multiple LPNs onto one Pallet based on controls.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Receiving_ReceiveASNLPN
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
          @vScannedLPN               TLPN,
          @vScannedLocation          TLocation,
          @vScannedPallet            TPallet,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vReceiptInfoXML           TXML,
          @vReceiptDetailsXML        TXML,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @xmlRulesData              TXML,
          @vxmlRFCProcInput1         xml,
          @vxmlRFCProcOutput1        xml,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vLocationWarehouse        TWarehouse,
          @vLocationType             TLocationType,
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vPalletStatus             TStatus,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNStatus                TStatus,
          @vLPNReceiptId             TRecordId,
          @vLPNSKUId                 TRecordId,
          @vReceiptType              TReceiptType,
          @vReceiptStatus            TStatus,
          @vReceiptWarehouse         TStatus,
          @vLPNSKU                   TSKU,
          @vLPNQty                   TQuantity,
          @vScanOrPromptPallet       TControlValue;
begin /* pr_AMF_Receiving_ReceiveASNLPN */

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
         @vReceiverNumber    = nullif(Record.Col.value('(Data/m_ReceiverNumber)[1]',       'TReceiverNumber'), ''),
         @vScannedLocation   = nullif(Record.Col.value('(Data/Location)[1]',               'TLocation'      ), ''),
         @vScannedPallet     = nullif(Record.Col.value('(Data/Pallet)[1]',                 'TPallet'        ), ''),
         @vScannedLPN        = Record.Col.value('(Data/LPN)[1]',                           'TLPN'           ),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                     'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Fetch Location Details */
  select @vLocationId        = LocationId,
         @vLocation          = Location,
         @vLocationType      = LocationType,
         @vLocationWarehouse = Warehouse
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation(null, @vScannedLocation, @vDeviceId, @vUserId, @vBusinessUnit));

  /* Fetch Pallet details */
  select @vPalletId     = PalletId,
         @vPallet       = Pallet,
         @vPalletStatus = Status
  from Pallets
  where (PalletId = dbo.fn_Pallets_GetPalletId(@vScannedPallet, @vBusinessUnit));

  /* Fetch LPN details */
  select @vLPNId        = LPNId,
         @vLPN          = LPN,
         @vLPNStatus    = Status,
         @vLPNReceiptId = ReceiptId,
         @vLPNSKUId     = SKUId,
         @vLPNSKU       = SKU,
         @vLPNQty       = Quantity
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vScannedLPN, @vBusinessUnit, 'LA' /* Options */));

  /* Fetch Receipt details */
  select @vReceiptId        = ReceiptId,
         @vReceiptNumber    = ReceiptNumber,
         @vReceiptType      = ReceiptType,
         @vReceiptStatus    = Status,
         @vReceiptWarehouse = Warehouse
  from ReceiptHeaders
  where (ReceiptId = @vLPNReceiptId);

  /* Build the XML for custom validations */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',    @vOperation) +
                           dbo.fn_XMLNode('ReceiptId',    @vReceiptId) +
                           dbo.fn_XMLNode('ROWarehouse',  @vReceiptWarehouse) +
                           dbo.fn_XMLNode('LocWarehouse', @vLocationWarehouse));

  /* Validations */
  if (@vScannedLocation is not null) and (@vLocationId is null)
    set @vMessageName = 'InvalidLocation';
  else
  if (@vScannedPallet is not null) and (@vPalletId is null)
    set @vMessageName = 'PalletDoesNotExist';
  else
  if (@vLPNReceiptId is null)
    set @vMessageName = 'LPNIsNotAssociatedWithReceipt';
  else
  if (@vReceiptNumber is null)
    set @vMessageName = 'ReceiptIsInvalid';
  else
  if ((@vReceiptType = 'A' /* ASN */) and (@vLocationId is not null) and (@vLocationType not in ('D', 'S'  /* Dock, Staging */)))
    set @vMessageName = 'NotAnASNReceivingLocation';
  else
  if (@vReceiptStatus = 'C' /* Closed */)
    set @vMessageName = 'CannotReceiveClosedRO';
  else
    /* Custom validations */
    exec pr_RuleSets_Evaluate 'Receiving_Validations', @xmlRulesData, @vMessageName output;

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Build the input for Validating LPN */
  select @vxmlRFCProcInput1 = (select Record.Col.value('(SessionInfo/DeviceId)[1]',               'TDeviceId'      ) as DeviceId,
                                      Record.Col.value('(SessionInfo/UserName)[1]',               'TUserId'        ) as UserId,
                                      Record.Col.value('(SessionInfo/BusinessUnit)[1]',           'TBusinessUnit'  ) as BusinessUnit,
                                      Record.Col.value('(Data/m_ReceiverNumber)[1]',              'TReceiverNumber') as ReceiverNumber,
                                      @vReceiptNumber                                                                as ReceiptNumber,
                                      @vLPN                                                                          as LPN,
                                      Record.Col.value('(Data/Operation)[1]',                     'TOperation'     ) as Operation
                               from @vxmlInput.nodes('/Root') as Record(Col)
                               for xml raw('ValidateASNLPNInput'), elements);

  /* call the ValidateASNLPN proc */
  exec pr_RFC_ValidateASNLPN @vxmlRFCProcInput1, @vxmlRFCProcOutput1 output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput1, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* Build the input for Receiving LPN */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',               'TDeviceId'      ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',               'TUserId'        ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',           'TBusinessUnit'  ) as BusinessUnit,
                                     Record.Col.value('(Data/m_ReceiverNumber)[1]',              'TReceiverNumber') as ReceiverNumber,
                                     @vReceiptNumber                                                                as ReceiptNumber,
                                     @vLocation                                                                     as Location,
                                     @vPallet                                                                       as Pallet,
                                     @vLPN                                                                          as LPN,
                                     @vLPNSKU                                                                       as SKU,
                                     @vLPNQty                                                                       as ConfirmQuantity,
                                     Record.Col.value('(Data/Operation)[1]',                     'TOperation'     ) as Operation,
                                     'Y'                                                                            as QtyConfirmed
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ReceiveASNLPNInput'), elements);

  /* call the ReceiveASNLPN proc */
  exec pr_RFC_ReceiveASNLPN @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is an error, return */
  if (@vTransactionFailed > 0) return (@vTransactionFailed);

  /* If user did not give a Receiver, a new Receiver may have been created, need
     to show the same to the user, so retrieve it from OutputXML */
  select @vReceiverNumber = Record.Col.value('(ReceiverNumber)[1]', 'TReceiverNumber'),
         @vPallet         = Record.Col.value('(Pallet)[1]',         'TPallet'),
         @vMessage        = Record.Col.value('(Message)[1]',        'TMessage')
  from @vxmlRFCProcOutput.nodes('/ReceiveASNLPNResult') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  /* Build success message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* Get the Receipt Info */
  exec pr_AMF_Info_GetROInfoXML @vReceiptId, 'N' /* Receipt Details */, @vOperation,
                                @vReceiptInfoXML output, @vReceiptDetailsXML output;

  /* Get the LPN Info */
  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, 'LPNDetails' /* LPNDetails */, null /* Operation */,
                                 @vLPNInfoXML output, @vLPNDetailsXML output;

  /* Get the control value to scan pallet */
  select @vScanOrPromptPallet = dbo.fn_Controls_GetAsString('ReceiveASN_PromptToScan', 'PromptForPallet', 'Y', @vBusinessUnit, @vUserId);

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', @vReceiptInfoXML + @vReceiptDetailsXML +
                                           @vLPNInfoXML + @vLPNDetailsXML +
                                           dbo.fn_XmlNode('ScanPallet',        @vScanOrPromptPallet) +
                                           dbo.fn_XmlNode('ReceiverNumber',    @vReceiverNumber) +
                                           dbo.fn_XmlNode('ReceivingLocation', @vLocation) +
                                           dbo.fn_XmlNode('ReceivingPallet',   @vPallet));

end /* pr_AMF_Receiving_ReceiveASNLPN */

Go

