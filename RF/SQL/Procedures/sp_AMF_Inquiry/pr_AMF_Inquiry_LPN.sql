/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/21  RIA     pr_AMF_Inquiry_LPN: Changed options to include details (OB2-1768)
  2021/04/15  RIA     pr_AMF_Inquiry_LPN: Changes to build information in V3 (OB2-1768)
  2020/11/04  MS      pr_AMF_Inquiry_LPN, pr_AMF_Inquiry_Pallet: Made changes to show values in UDF on RF Screen (JL-289)
  2020/05/18  RIA     pr_AMF_Inquiry_Location, pr_AMF_Inquiry_LPN: Used LPNs table instead of vwLPNs (HA-527)
  pr_AMF_Inquiry_LPN: Added InvClass1 (HA-527)
  2019/05/30  AY      pr_AMF_Inquiry_LPN: Corrections
  2019/05/15  RIA     Added pr_AMF_Inquiry_LPN (CIMSV3-464)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inquiry_LPN') is not null
  drop Procedure pr_AMF_Inquiry_LPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inquiry_LPN:@vLPNInfo

  Processes the requests for LPN Inquiry for LPN Inquiry work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inquiry_LPN
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
          @vRFFormAction             TMessageName,
          @LPN                       TLPN,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vRecordId                 TRecordId,
          @vLocationId               TRecordId,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNType                  TTypecode,
          @vNumSKUs                  TCount,
          @vIncludeLPNDetails        TFlags,
          @vxmlLPNDetails            xml,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML;
begin /* pr_AMF_Inquiry_LPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs from InputXML */
  select @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @LPN           = Record.Col.value('(Data/LPN)[1]',                 'TLPN'         )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get scanned LPN info */
  select @vLPNId      = LPNId,
         @vLPN        = LPN,
         @vLPNType    = LPNType,
         @vLocationId = LocationId
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@LPN, @vBusinessUnit, 'LTU'));

  /* if logical LPN, then check if it is a multi-SKU picklane, LPN Inquiry
     would not work for multi SKU picklane, so suggest user to use Location Inquiry */
  if (@vLPNType = 'L')
    select @vNumSKUs = count(*)
    from LPNs
    where (LPN = @vLPN) and (BusinessUnit = @vBusinessUnit) and (Status <> 'I');

  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vNumSKUs > 1)
    set @vMessageName = 'AMF_LPNInquiry_MultiSKUPicklane';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* get the LPN Info */
  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, 'SKUOnhand', @vOperation, @vLPNInfoXML output,
                                 @vLPNDetailsXML output;

  select @DataXml = dbo.fn_XmlNode('Data', @vLPNInfoXML + @vLPNDetailsXML);

end /* pr_AMF_Inquiry_LPN */

Go

