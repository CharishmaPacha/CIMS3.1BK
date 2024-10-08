/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_BuildCart_StartBuildCart') is not null
  drop Procedure pr_AMF_Picking_BuildCart_StartBuildCart;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_BuildCart_StartBuildCart:

  Processes the requests for Start Build Cart for Build Picking Cart work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_BuildCart_StartBuildCart
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vInputXML            xml,
          @vrfcProcInputxml     xml,
          @vrfcProcOutputxml    xml,
          @vTransactionFailed   TBoolean,
          @vUserName            TName,
          @vBusinessUnit        TBusinessUnit,
          @vDeviceId            TDeviceId,
          @vMessage             TMessage,
          /* Start Build Cart Variables */
          @vInputTaskId         TRecordId,
          @vPickingCart         TPallet,
          @vTaskId              TRecordId,
          @vTaskInfoXML         TXML;

begin /* pr_AMF_Picking_BuildCart_StartBuildCart */
  /* Convert input into xml var */
  select @vInputXML = convert(xml, @InputXML);
  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Build the input for V2 procedure */
  select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/m_TASKDETAILSTaskId)[1]',        'TRecordId'    ) as Batch,
                                     Record.Col.value('(Data/PickingCart)[1]',                'TPallet'      ) as Cart
                              from @vInputXML.nodes('/Root') as Record(Col)
                              for xml raw('BuildCart'), elements);

  exec pr_RFC_Picking_StartBuildCart @vrfcProcInputxml, @vrfcProcOutputxml output;

  exec pr_AMF_EvaluateExecResult @vrfcProcOutputxml, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If the transaction was successful, transform V2 format response into AMF Format Data element */
  if (@vTransactionFailed <= 0)
    begin
      /* V2 does not return all the info needed, so build the response needed for V3
         without depending upon all fields returned by V2 */
      select @vTaskId = Record.Col.value('(Batch)[1]', 'TRecordId')
      from @vrfcProcOutputxml.nodes('/BuildCart') as Record(Col);

      /* Get Task info to fill the form */
      exec pr_AMF_Info_GetTaskInfoXML @vTaskId, 'StartBuildCart', @vTaskInfoXML output;

      select @DataXML = ''; /* Reset output variable to build dataxml from procecdure output */
      with ResponseDetails as
      (
        select dbo.fn_XMLNode('BUILDCART' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
        from @vrfcProcOutputxml.nodes('/BuildCart/*') as t(c)
      )
      select @DataXML = @DataXML + ResponseDetail from ResponseDetails;

      select @DataXML = dbo.fn_XMLNode('Data', @DataXML + @vTaskInfoXML);

      /* read the success message */
      select @vMessage = Record.Col.value('(Message)[1]', 'TMessage')
      from @vrfcProcOutputxml.nodes('/BuildCart') as Record(Col);

      select @InfoXML =  dbo.fn_XMLNode('Info', dbo.fn_XMLNode('Messages', dbo.fn_AMF_GetMessageXML(@vMessage)));
    end
end /* pr_AMF_Picking_BuildCart_StartBuildCart */

Go

