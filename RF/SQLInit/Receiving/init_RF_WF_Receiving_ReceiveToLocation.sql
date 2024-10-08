/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/17  RIA     Initial Revision(CIMSV3-755)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Receiving_ReceiveToLocation';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                                  FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'Receiving_ReceiveToLoc_StartReceiving',   'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~ReceiptInfo_ReceiptNumber~, '''') <> ''''',
                                                                                    'Receiving_ReceiveToLoc',                  'pr_AMF_Receiving_ReceiveToLPNOrLOC',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~QtyToReceive~ = ''0''',                'Receiving_ReceiveToLoc_StartReceiving',   'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~RFFormAction~ = ''Pause''',            'Receiving_ReceiveToLoc',                  'pr_AMF_Receiving_PauseReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '~Resolution~ = ''Pause''',              'Receiving_ReceiveToLoc_StartReceiving',   'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits

Go
