/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/10  AY      pr_AMF_Picking_BuildCart_AddCartonToCart: WIP (CID-547)
  2019/02/22  NB      Initial Revision(CIMSV3-370)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Picking_BuildCart';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                                 FormName,                            FormMethod,                                 BusinessUnit)
      select @vWorkFlowName, 1,            null,                                                          'Picking_BuildCart_StartAndConfirm',  'pr_AMF_Picking_BuildCart_ValidateTask',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~TASKDETAILSTaskId~,'''') <> ''''',                  'Picking_BuildCart_StartAndConfirm',  'pr_AMF_Picking_BuildCart_StartBuildCart',  BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~!BUILDCARTBatch~ > 0 and ~BUILDCARTAutoAssignLPNs~ = ''N''', 'Picking_BuildCart_AddCartonToCart',  'pr_AMF_Picking_BuildCart_AddCartonToCart', BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~!BUILDCARTBatch~ > 0 and ~BUILDCARTAutoAssignLPNs~ = ''Y''', 'Picking_BuildCart_StartAndConfirm',  'pr_AMF_Picking_BuildCart_ValidateTask',    BusinessUnit from vwBusinessUnits

Go



 -- Remove BusinessUnits from here..
 
 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data
 