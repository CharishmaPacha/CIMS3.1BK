/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/05  RIA     Renamed Workflow, Forms and procs (Jl-296)
  2020/03/16  RIA     Changes to workflow (CIMSV3-652)
  2020/02/03  RIA     Initial Revision(CIMSV3-652)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Receiving_ReceiveASN';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                                  FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'Receiving_ReceiveASN_StartReceiving',     'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~LPNInfo_LPN~, '''') <> ''''', 'Receiving_ReceiveASN',                    'pr_AMF_Receiving_ReceiveASN',           BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            'coalesce(~ReceiptInfo_ReceiptNumber~, '''') <> ''''',
                                                                                    'Receiving_ReceiveASN',                    'pr_AMF_Receiving_ValidateASNLPN',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~LPNsInTransit~ = ''0''',               'Receiving_ReceiveASN_StartReceiving',     'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '~RFFormAction~ = ''Pause''',            'Receiving_ReceiveASN',                    'pr_AMF_Receiving_PauseReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 6,            '~Resolution~ = ''Pause''',              'Receiving_ReceiveASN_StartReceiving',     'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits

Go
