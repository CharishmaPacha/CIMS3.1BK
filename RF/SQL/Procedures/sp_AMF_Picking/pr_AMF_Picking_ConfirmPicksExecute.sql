/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/02  TK      pr_AMF_Picking_ConfirmPicksExecute: Bug fix in extracting task details from xml (BK-UpgradeGoLive)
  2019/06/12  RIA     pr_AMF_Picking_ConfirmPicksExecute: Changes to return appropriate response (CID-518)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_ConfirmPicksExecute') is not null
  drop Procedure pr_AMF_Picking_ConfirmPicksExecute;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_ConfirmPicksExecute:

  Processes the requests for Confirm picks work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_ConfirmPicksExecute
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vInputXML               xml,
          @vrfcProcInputxml        xml,
          @vrfcProcOutputxml       xml,
          @vPalletDetails          xml,
          @vTaskInfoxml            xml,
          @vOutstandingPicksxml    xml,
          @vTaskPickHeaderInfoxml  xml,
          @vTaskPickDetailInfoxml  xml,
          @vSuccessMessage         TMessage,
          @vPalletId               TRecordId,
          @vPallet                 TPallet,
          @vBusinessUnit           TBusinessUnit,
          @vTaskId                 TRecordId,
          @vActivityLogId          TRecordId,
          @vTransactionFailed      TBoolean;
begin /* pr_AMF_Picking_ConfirmPicksExecute */

  /* Clean up Input XML */
  select @InputXML = replace (@InputXML, '&lt;', '<');
  select @InputXML = replace (@InputXML, '&gt;', '>');
  select @vInputXML = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Build V2 Procedure input */
  select @vTaskPickHeaderInfoxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                           Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                           Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                           Record.Col.value('(Data/m_ConfirmPicksToLPN)[1]',        'TLPN'         ) as ToLPN,
                                           Record.Col.value('(Data/m_ConfirmPicksTaskId)[1]',       'TRecordId'    ) as TaskId,
                                           Record.Col.value('(Data/m_ConfirmPicksPickTicket)[1]',   'TPickTicket'  ) as PickTicket,
                                           Record.Col.value('(Data/m_ConfirmPicksWaveType)[1]',     'TTypeCode'    ) as PickType,
                                           Record.Col.value('(Data/Operation)[1]',                  'TOperation'   ) as Operation
                                    from @vInputXML.nodes('/Root') as Record(Col)
                                    for xml raw('TaskPickHeaderInfo'), elements XSINIL, Root('TaskPickHeaderInfoDto'));

  select @vTaskPickDetailInfoxml = (select Record.Col.value('(TaskDetailId)[1]', 'TRecordId') as TaskDetailId,
                                           Record.Col.value('(SKU)[1]',          'TSKU'     ) as SKU,
                                           Record.Col.value('(Quantity)[1]',     'TQuantity') as Quantity
                                    from @vInputXML.nodes('/Root/Data/m_TASKPICKDETAILS/TASKDETAIL') as Record(Col)
                                    for xml raw('TaskPickDetailInfo'), elements XSINIL, Root('TaskPickDetailsInfoDto'));

  /* Build the xml in the format expected by the ConfirmTaskPicks procedure */
  select @vrfcProcInputxml = convert(xml, dbo.fn_XMLNode('ConfirmTaskPickInfo',
                                            convert(varchar(max), @vTaskPickHeaderInfoxml) +
                                            convert(varchar(max), @vTaskPickDetailInfoxml)));

  /* Execute V2 procedure */
  exec pr_RFC_Picking_ConfirmTaskPicks @vrfcProcInputxml, @vrfcProcOutputxml output;

  exec pr_AMF_EvaluateExecResult @vrfcProcOutputxml, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  if (@vTransactionFailed <= 0)
    begin
      select @DataXML = '';
      with ResponseDetails as
      (
        select dbo.fn_XMLNode('ConfirmPicks' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
        from @vrfcProcOutputxml.nodes('/SUCCESSDETAILS/SUCCESSINFO') as t(c)
      )
      select @DataXML = @DataXML + ResponseDetail from ResponseDetails;

      select @DataXml = dbo.fn_XmlNode('Data', @DataXML);

      /* Verify whether the task pick is completed, and there are no more picks left */
      select @vSuccessMessage  = Record.Col.value('Message[1]',     'TMessage')
      from @vrfcProcOutputxml.nodes('/SUCCESSDETAILS/SUCCESSINFO')  as Record(Col)
      OPTION (OPTIMIZE FOR (@vrfcProcOutputxml = null));

      select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);
    end

end /* pr_AMF_Picking_ConfirmPicksExecute */

Go

