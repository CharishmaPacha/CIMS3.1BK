/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/16  RIA     Initial Revision(CIMSV3-754)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Receiving_ReceiveToLPN';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                                  FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'Receiving_ReceiveToLPN_StartReceiving',   'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~ReceiptInfo_ReceiptNumber~, '''') <> ''''',
                                                                                    'Receiving_ReceiveToLPN',                  'pr_AMF_Receiving_ReceiveToLPNOrLOC',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~QtyToReceive~ = ''0''',                'Receiving_ReceiveToLPN_StartReceiving',   'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~RFFormAction~ = ''Pause''',            'Receiving_ReceiveToLPN',                  'pr_AMF_Receiving_PauseReceiving',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '~Resolution~ = ''Pause''',              'Receiving_ReceiveToLPN_StartReceiving',   'pr_AMF_Receiving_StartReceiving',       BusinessUnit from vwBusinessUnits

Go
