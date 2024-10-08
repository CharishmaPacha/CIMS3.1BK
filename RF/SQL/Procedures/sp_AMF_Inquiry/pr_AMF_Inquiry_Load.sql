/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/19  RIA     Added: pr_AMF_Inquiry_Load (HA-2347)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inquiry_Load') is not null
  drop Procedure pr_AMF_Inquiry_Load;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inquiry_Load:@vLoadInfo

  This proc checks for valid LoadNumber and throws an error if invalid else will
  return the info related to Load.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inquiry_Load
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
          @LoadNumber                TLoadNumber,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLoadInfoXML              TXML,
          @vLoadDetailsXML           TXML,
          @vLoadId                   TRecordId,
          @vLoadNumber               TLoadNumber;
begin /* pr_AMF_Inquiry_Load */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs from InputXML */
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @LoadNumber      = Record.Col.value('(Data/LoadNumber)[1]',                 'TLoadNumber'  )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Fetch the Load Information */
  select @vLoadNumber  = LoadNumber,
         @vLoadId      = LoadId
  from Loads
  where (LoadNumber    = @LoadNumber) and
        (BusinessUnit  = @vBusinessUnit);

  /* Validate LoadId */
  if (@vLoadId is null)
    set @vMessageName = 'LoadNumberDoesNotExist';

  /* This will raise an exception, and the caller ExecuteAction procedure would
     capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* get the Receipt Info */
  exec pr_AMF_Info_GetLoadInfoXML @vLoadId, 'PL', @vOperation, @vLoadInfoXML output,
                                  @vLoadDetailsXML output;

  select @DataXml = dbo.fn_XmlNode('Data', @vLoadInfoXML + @vLoadDetailsXML);

end /* pr_AMF_Inquiry_Load */

Go

