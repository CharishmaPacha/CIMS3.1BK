/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/03  RIA     Initial Revision
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Receiving_ReceiveASNLPN';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                                  FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'Receiving_ReceiveASNLPN',                 'pr_AMF_Receiving_ReceiveASNLPN',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~ReceiptInfo_ReceiptNumber~, '''') <> ''''',
                                                                                    'Receiving_ReceiveASNLPN',                 'pr_AMF_Receiving_ReceiveASNLPN',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~RFFormAction~ = ''Pause''',            'Receiving_ReceiveASNLPN',                 'pr_AMF_Common_StopOrPause',             BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~Resolution~ = ''Done''',               'Receiving_ReceiveASNLPN',                 'pr_AMF_Receiving_ReceiveASNLPN',        BusinessUnit from vwBusinessUnits

Go
