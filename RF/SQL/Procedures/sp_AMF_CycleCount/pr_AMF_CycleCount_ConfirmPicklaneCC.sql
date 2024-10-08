/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/08  RIA     pr_AMF_CycleCount_ValidateUnknownSKU: Added and made changes to pr_AMF_CycleCount_ConfirmPicklaneCC (HA-2199)
  2020/09/10  RIA     pr_AMF_CycleCount_ConfirmPicklaneCC: Changes to consider batchno, taskid, taskdetailid (HA-1405)
  pr_AMF_CycleCount_ConfirmPicklaneCC, pr_AMF_CycleCount_StartLocationCount (HA-1079)
  2020/07/07  RIA     Added pr_AMF_CycleCount_ConfirmPicklaneCC (CIMSV3-773)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_CycleCount_ConfirmPicklaneCC') is not null
  drop Procedure pr_AMF_CycleCount_ConfirmPicklaneCC;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_CycleCount_ConfirmPicklaneCC: Calls the V2 proc and do necessary
    updates for Picklane CC
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_CycleCount_ConfirmPicklaneCC
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
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vSKU                      TSKU,
          @vNewUnits                 TQuantity,
          @vNewInnerPacks            TInnerPacks,
          @vTaskSubType              TFlag,
          @vTaskId                   TRecordId,
          @vTaskDetailId             TRecordId,
          @vBatchNo                  TTaskBatchNo,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vDeviceName               TName,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vLocNumLPNs               TQuantity,
          @vRFFormAction             TDescription,
          @vxmlData                  xml,
          @vLocCCInfoXML             TXML,
          @vTempXML                  TXML;

  declare @ttSKUList                 TCycleCountTable;
begin /* pr_AMF_CycleCount_ConfirmPicklaneCC */

  /* Convert input into xml var */
  select @vxmlInput = convert(xml, @InputXML);

  /* Build temporary table */
  select * into #CCSKUList from @ttSKUList;

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs from InputXML */
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vTaskId         = Record.Col.value('(Data/m_TaskId)[1]',                   'TRecordId'    ),
         @vTaskDetailId   = Record.Col.value('(Data/m_TaskDetailId)[1]',             'TRecordId'    ),
         @vBatchNo        = Record.Col.value('(Data/m_BatchNo)[1]',                  'TTaskBatchNo' ),
         @vLocationId     = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'    ),
         @vLocation       = Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'    ),
         @vOperation      = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   ),
         @vTaskSubType    = Record.Col.value('(Data/m_TaskSubType)[1]',              'TFlag'        ),
         @vRFFormAction   = Record.Col.value('(Data/RFFormAction)[1]',               'TDescription' )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Build the Location Header Info */
  select @vLocCCInfoXML = dbo.fn_XMLNode('CONFIRMCYCLECOUNTDETAILS',
                              dbo.fn_XMLNode('Location',      @vLocation) +
                              dbo.fn_XMLNode('TaskId',        @vTaskId) +
                              dbo.fn_XMLNode('TaskDetailId',  @vTaskDetailId) +
                              dbo.fn_XMLNode('BatchNo',       @vBatchNo) +
                              dbo.fn_XMLNode('SubTaskType',   @vTaskSubType) +
                              dbo.fn_XMLNode('BusinessUnit',  @vBusinessUnit) +
                              dbo.fn_XMLNode('UserId',        @vUserId) +
                              dbo.fn_XMLNode('DeviceId',      @vDeviceId));

  /* Build the Location Details */
  insert into #CCSKUList(EntityType, SKU, NewInnerPacks, NewQuantity)
    select 'SKU',
           Record.Col.value('(SKU)[1]',           'TSKU'),
           Record.Col.value('(NewInnerPacks)[1]', 'TInnerPacks'),
           Record.Col.value('(NewUnits)[1]',      'TQuantity')
    from @vxmlInput.nodes('/Root/Data/CCData/CCTable') as Record(Col);

  select @vTempXML = (select SKU          as SKU,
                             @vLocNumLPNs as NumLPNs,
                             NewQuantity  as Quantity
                      from #CCSKUList
                      for xml path('LOCATIONINFO'), root('CCLOCDETAILS'));

  select @vxmlRFCProcInput = convert(xml, dbo.fn_XMLAddNode(@vLocCCInfoXML, 'CONFIRMCYCLECOUNTDETAILS', @vTempXML));

  /* Delete the below nodes as it is causing issues in data binding when there is an error */
  /* Future: Removing m_ nodes will be removed in future version where a flag will be set in the form to not to send these in the first place */
  select @vxmlData = convert(xml, @DataXML);
  set @vxmlData.modify('delete /Data/SKU');
  set @vxmlData.modify('delete /Data/RFFormAction');
  set @vxmlData.modify('delete /Data/m_SKU');
  set @vxmlData.modify('delete /Data/m_CCData');
  select @DataXML = convert(varchar(max), @vxmlData);

  /* The list of SKUs scanned so far are in the DataXML and we want to save it to
     devices so that even in the event of an error, those SKUs will be returned back
     to RF for display to user */
  update Devices
  set DataXML = @DataXML
  where (DeviceId = @vDeviceName);

  /* Complete CC for Picklane Location */
  exec pr_RFC_CC_CompleteLocationCC @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* Evaluate the result returned */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output, @InfoXML output;

  /* If an error occurs while completing cc, exit */
  if (coalesce(@vTransactionFailed, 0) <> 0) return @vTransactionFailed;

  /* CC is completed on Location, now prepare the response: If directed, suggest the
     next location or else it is done */
  exec pr_CycleCount_CompleteResponse @vxmlRFCProcOutput, @vLocation, @DataXml output, @InfoXML output;

end /* pr_AMF_CycleCount_ConfirmPicklaneCC */

Go

