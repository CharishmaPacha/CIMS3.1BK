/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/08  RIA     pr_AMF_Picking_BuildCart_ValidateTask: Added Validation for SLB(CID-GoLive)
  2019/06/11  AY      pr_AMF_Picking_BuildCart_ValidateTask: Show the NumOrders, TempLabels (CID-UAT)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_BuildCart_ValidateTask') is not null
  drop Procedure pr_AMF_Picking_BuildCart_ValidateTask;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_BuildCart_ValidateTask:

  Processes the requests for Validate Task for Build Picking Cart work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_BuildCart_ValidateTask
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
          @vMessageName         TMessageName,
          /* Validate Task Variables*/
          @vInputTaskId        TRecordId,
          @vValidTaskId        TRecordId,
          @vPickBatchNo        TPickBatchNo,
          @vBatchType          TTypeCode,
          @vxmlTaskDetails     xml;
begin /* pr_AMF_Picking_BuildCart_ValidateTask */
  /* Convert input into xml var */
  select @vInputXML = convert(xml, @InputXML);
  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs needed for the V2 procedure */
  select @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vUserName     = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vInputTaskId  = Record.Col.value('(Data/TaskId)[1]',                     'TRecordId'    )
  from @vInputXML.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vInputXML = null ) );

  exec pr_Picking_ValidateTaskId null /* @UserTaskId */, @vInputTaskId /* @SelectedTaskId */, null /* @PickGroup */,
                                 null /* @PickPallet */, null /* @PickTicket */,
                                 @vValidTaskId  output, @vPickBatchNo  output;

  /* The above procedure is returning null for valid tasks
     TODO Need to enhance the above V2 Procedure to send the Valid Task Id */
  select @vValidTaskId = coalesce(@vValidTaskId, @vInputTaskId);

  /* Get Batch Type */
  select @vBatchType from vwTasks
  where TaskId = @vValidTaskId;

  /* Validate TaskId and allow only for PTC and PTS waves
     In future will fetch based on controls and will allow user to continue further */
  if (@vBatchType in ('SLB'))
    set @vMessageName = 'AMF_SingleLineDoesnotNeedBuildCart';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    begin
      exec pr_AMF_RaiseErrorAndReset @vMessageName, @DataXML = @DataXML output, @ErrorXML = @ErrorXML output;
      return;
    end

  /* Capture Task Information */
  select @vxmlTaskDetails = (select TaskId, TaskType, TaskTypeDescription, TaskSubType, TaskSubTypeDescription,
                                    WaveNo, WaveTypeDesc, NumOrders, TotalUnits, NumLPNs, NumTempLabels,
                                    CartType as CartType,
                                    BatchNo, BatchTypeDesc -- need to drop after UAT
                             from vwTasks
                             where TaskId = @vValidTaskId
                             for xml raw('TaskDetails'), Elements);

  select @DataXML = '';
  with ResponseDetails as
  (  select dbo.fn_XMLNode('TASKDETAILS' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
        from @vxmlTaskDetails.nodes('/TaskDetails/*') as t(c)
  )
  select @DataXML = @DataXML + ResponseDetail from ResponseDetails;

  select @DataXML = dbo.fn_XMLNode('Data', @DataXML);

end /* pr_AMF_Picking_BuildCart_ValidateTask */

Go

