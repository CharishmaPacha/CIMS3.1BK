/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/09  RIA     pr_AMF_CycleCount_StopCount: Changes to set TaskStatus (HA-1405)
  2020/07/13  RIA     Added pr_AMF_CycleCount_StopCount (CIMSV3-773)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_CycleCount_StopCount') is not null
  drop Procedure pr_AMF_CycleCount_StopCount;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_CycleCount_StopCount: While performing CC user might want
    to stop the process and start with another Location or something else, they
    would use the Pause/Stop button which takes them back to the previous screen.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_CycleCount_StopCount
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
          @vTaskId                   TRecordId,
          @vTaskDetailId             TRecordId,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDataXML                  TXML;
begin /* pr_AMF_CycleCount_StopCount */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vTaskId         = Record.Col.value('(Data/m_TaskId)[1]',                   'TRecordId'    ),
         @vTaskDetailId   = Record.Col.value('(Data/m_TaskDetailId)[1]',             'TRecordId'    ),
         @vRFFormAction   = Record.Col.value('(Data/RFFormAction)[1]',               'TMessageName' )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Need to revert the taskdetail back to Ready to start */
  update TaskDetails
  set Status = 'N' /* Ready To Start */
  where (TaskDetailId = @vTaskDetailId) and (Status = 'I' /* In progress */);

  /* Set the Task Status as well */
  exec pr_Tasks_SetStatus @vTaskId, @vUserId;

  select @DataXML = (select 'Stop' as Resolution
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_CycleCount_StopCount */

Go

