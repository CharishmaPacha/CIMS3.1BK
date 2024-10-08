/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/09  RIA     pr_CycleCount_CompleteResponse: Changes to build success message for each location CC in Directed count (HA-1405)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_CompleteResponse') is not null
  drop Procedure pr_CycleCount_CompleteResponse;
Go
/*------------------------------------------------------------------------------
  Procedure pr_CycleCount_CompleteResponse: When cycle count of a Location is completed
    we have to send a response back to the operator. The output fetched from V2 proc
    is then passed to this proc as input to determine the response to the user.
    If it is a non-directed cycle count, then the we are done.
    If it is a directed cycle count, then we issue the next location to cycle count
    along with the success message of the location just completed.
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_CompleteResponse
  (@xmlInput  xml,
   @Location  TLocation = null,
   @DataXML   TXML      = null output,
   @InfoXML   TXML      = null output)
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vNextCCLocationId         TRecordId,
          @vTaskId                   TRecordId,
          @vTaskDetailId             TRecordId,
          @vSuggestedLocation        TLocation,
          @vBatchNo                  TTaskBatchNo,
          @vPickZone                 TZone;
          /* Functional variables */
  declare @vLocationId               TRecordId,
          @vxmlInfo                  xml,
          @vDirectedCCInfoXML        TXML,
          @vSuccessMessage           TDescription;
begin /* pr_CycleCount_CompleteResponse */

  /*  Read values from inputxml as it is needed for dispalying data for Directed CC
      and also to build xml in the way to show suggested location form where user can scan location */
  select @vNextCCLocationId  = Record.Col.value('(LOCATIONINFO/LocationId)[1]',       'TRecordId'    ),
         @vSuggestedLocation = Record.Col.value('(LOCATIONINFO/Location)[1]',         'TLocation'    ),
         @vBatchNo           = Record.Col.value('(LOCATIONINFO/BatchNo)[1]',          'TTaskBatchNo' ),
         @vPickZone          = Record.Col.value('(LOCATIONINFO/PickZone)[1]',         'TZone'        ),
         @vTaskId            = Record.Col.value('(LOCATIONINFO/TaskId)[1]',           'TRecordId'    ),
         @vTaskDetailId      = Record.Col.value('(LOCATIONINFO/TaskDetailId)[1]',     'TRecordId'    )
  from @xmlInput.nodes('/CYCLECOUNTDETAILS') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* if there is not another location to CC, then prepare response that we are done */
  if (@vNextCCLocationId is null)
    begin
      /* If successfully completed and no locations left, do not return any info as it would revert to prior screen */
      select @DataXML = (select 'Done' as Resolution
                         for Xml Raw(''), elements, Root('Data'));

      return;
    end;

  /* If it is directed CC, then build the success message for the location just completed. */
  select @vMessageName = dbo.fn_Messages_Build('CCCompletedSuccessfully', @Location, null, null, null, null);
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessageName);

  /* Build the DirectedCC Info XML */
  select @vDirectedCCInfoXML = dbo.fn_XMLNode('PickZone',          @vPickZone) +
                               dbo.fn_XMLNode('BatchNo',           @vBatchNo) +
                               dbo.fn_XMLNode('SuggestedLocation', @vSuggestedLocation) +
                               dbo.fn_XMLNode('TaskId',            @vTaskId) +
                               dbo.fn_XMLNode('TaskDetailId',      @vTaskDetailId);

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vDirectedCCInfoXML);

end /* pr_CycleCount_CompleteResponse */

Go

