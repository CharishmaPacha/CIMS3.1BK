/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_ConfirmPicksValidate') is not null
  drop Procedure pr_AMF_Picking_ConfirmPicksValidate;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_ConfirmPicksValidate:

  Processes the requests for Validate Carton for Confirm picks work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_ConfirmPicksValidate
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vInputXML             xml,
          @vrfcProcInputxml      xml,
          @vrfcProcOutputxml     xml,
          @vPalletDetails        xml,
          @vTaskInfoxml          xml,
          @vOutstandingPicksxml  xml,
          @vPalletId             TRecordId,
          @vPallet               TPallet,
          @vBusinessUnit         TBusinessUnit,
          @vTaskId               TRecordid,
          @vTransactionFailed    TBoolean;
begin /* pr_AMF_Picking_ConfirmPicksValidate */
  select @vInputXML = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Build the input for V2 procedure */
  select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/LPN)[1]',                        'TLPN'         ) as ToLPN,
                                     Record.Col.value('(Data/Operation)[1]',                  'TOperation'   ) as Operation
                              from @vInputXML.nodes('/Root') as Record(Col)
                              for xml raw('TaskPickHeaderInfo'), elements XSINIL, Root('TaskPickHeaderInfoDto'));

  /* Build the xml in the format expected by the ValidatePallet procedure */
  select @vrfcProcInputxml = convert(xml, dbo.fn_XMLNode('ConfirmTaskPickInfo', convert(varchar(max), @vrfcProcInputxml)));

  /* Execute V2 procedure */
  exec pr_RFC_Picking_ValidateTaskPicks @vrfcProcInputxml, @vrfcProcOutputxml output;

  exec pr_AMF_EvaluateExecResult @vrfcProcOutputxml, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If the transaction was successful, transform V2 format response into AMF Format Data element */
  if (@vTransactionFailed <= 0)
    begin
      select @DataXML = '';
      with ResponseDetails as
      (
        select dbo.fn_XMLNode('ConfirmPicks' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
        from @vrfcProcOutputxml.nodes('/ConfirmTaskPickInfo/TaskPickHeaderInfoDto/BusinessUnits/*') as t(c)
      )
      select @DataXML = @DataXML + ResponseDetail from ResponseDetails;

      set @vOutstandingPicksxml = (select Record.Col.value('PickFrom[1]',     'TLocation')    Location,
                                          Record.Col.value('SKU[1]',          'TSKU')         SKU,
                                          Record.Col.value('Quantity[1]',     'TQuantity')    Quantity,
                                          Record.Col.value('Description[1]',  'TDescription') Description,
                                          Record.Col.value('TaskDetailId[1]', 'TRecordId')    TaskDetailId
                                   from @vrfcProcOutputxml.nodes('ConfirmTaskPickInfo/TaskPickDetailsInfoDto/*') as Record(Col)
                                   FOR XML RAW('TASKDETAIL'), ELEMENTS XSINIL, ROOT('TASKPICKDETAILS'));

      select @DataXml = dbo.fn_XmlNode('Data', @DataXML + coalesce(convert(varchar(max), @vOutstandingPicksxml), ''));
    end
end /* pr_AMF_Picking_ConfirmPicksValidate */

Go

