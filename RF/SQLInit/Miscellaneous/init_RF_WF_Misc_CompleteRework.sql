/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/22  RIA     Changed form and Workflow names (HA-832)
  2020/06/17  RIA     Initial Revision(HA-832)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Misc_CompleteRework';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;

insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                           FormMethod,                                       BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'Misc_CompleteRework_ScanOrder',    'pr_AMF_Misc_ReworkOrder_Validate',               BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '(coalesce(~OrderInfo_PickTicket~, '''') <> '''')',
                                                                                    'Misc_CompleteRework_Execute',      'pr_AMF_Misc_ReworkOrder_CompleteProduction',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~RFFormAction~ = ''Pause''',            'Misc_CompleteRework_Execute',      'pr_AMF_Misc_ReworkOrder_Pause',                  BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~Resolution~ = ''Pause''',              'Misc_CompleteRework_ScanOrder',    'pr_AMF_Misc_ReworkOrder_Validate',               BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data
