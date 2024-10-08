/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/02  RIA     Changes in form condition (CID-518)
  2019/06/07  RIA     Initial Revision(CID-518)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'ConfirmPickTasks';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                 FormName,                        FormMethod,                                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                          'BatchPicking_ConfirmPicks',     'pr_AMF_Picking_ConfirmPicksValidate',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~ConfirmPicksToLPN~,'''') <> ''''',  'BatchPicking_ConfirmPicks',     'pr_AMF_Picking_ConfirmPicksExecute',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~ConfirmPicksReturnCode~  = 0',               'BatchPicking_ConfirmPicks',     'pr_AMF_Picking_ConfirmPicksValidate',       BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data
 
