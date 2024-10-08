/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/28  RIA     pr_AMF_Inquiry_ReceiptOrder: Clean up and changes to fetch SKU Details (CIMSV3-828)
  2020/05/14  RIA     pr_AMF_Inquiry_ReceiptOrder: Changes to get ReceiptId and ReceiptNumber (CIMSV3-828)
  2020/04/22  YJ      Added: pr_AMF_Inquiry_ReceiptOrder (CIMSV3-828)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inquiry_ReceiptOrder') is not null
  drop Procedure pr_AMF_Inquiry_ReceiptOrder;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inquiry_ReceiptOrder:@vReceiptInfo

  This proc checks for valid ReceiptNumber and throws an error if invalid else will
  return the info releated to Receipt.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inquiry_ReceiptOrder
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vInputXML                 xml,
          @ReceiptNumber             TReceiptNumber,

          @vReceiptInfoXML           TXML,
          @vReceiptDetailsXML        TXML,
          @vxmlReceiptInfo           xml,
          @vxmlReceiptDetails        xml,

          @vReceiptId                TRecordId,
          @vReceiptNumber            TReceiptNumber,
          @vOperation                TOperation,

          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vReturnCode               TInteger,
          @vMessageName              TMessageName;

begin /* pr_AMF_Inquiry_ReceiptOrder */

  select @vInputXML = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs from InputXML */
  select @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @ReceiptNumber = Record.Col.value('(Data/ReceiptNumber)[1]',       'TReceiptNumber')
  from @vInputXML.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* Fetch the Receipt Information */
  select @vReceiptNumber  = ReceiptNumber,
         @vReceiptId      = ReceiptId
  from ReceiptHeaders
  where (ReceiptNumber = @ReceiptNumber) and
        (BusinessUnit  = @vBusinessUnit);

  /* Validate ReceiptId */
  if (@vReceiptId is null)
    set @vMessageName = 'ReceiptDoesNotExist';

  /* This will raise an exception, and the caller ExecuteAction procedure would
     capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* get the Receipt Info */
  exec pr_AMF_Info_GetROInfoXML @vReceiptId, 'Y', @vOperation, @vReceiptInfoXML output,
                                @vReceiptDetailsXML output;

  select @DataXml = dbo.fn_XmlNode('Data', @vReceiptInfoXML + @vReceiptDetailsXML);

end /* pr_AMF_Inquiry_ReceiptOrder */

Go

