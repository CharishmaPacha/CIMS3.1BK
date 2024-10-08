/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/09  RIA     Added a step for stop CC (HA-1405)
  2020/09/03  RIA     Added a step to show a different screen to scan the location (HA-1079)
  2020/08/22  RIA     Initial Revision(HA-1079)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'DirectedCycleCount';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;

/* Directed CC shares a similar work flow as the non-directed CC and so we copy the workflow
   from non-directed CC and then make alterations to it */
insert into AMF_WorkFlowDetails (WorkFlowName, FormSequence, FormCondition, FormName, FormMethod, BusinessUnit)
  select @vWorkFlowName, FormSequence, FormCondition, FormName, FormMethod, BusinessUnit
  from AMF_WorkFlowDetails
  where (WorkFlowName = 'LocationCycleCount');

/* first step of the Directed CC workflow is to request a Location to CC */
update AMF_WorkFlowDetails set FormName = 'CycleCount_DirectedCC_Start'
where (FormName = 'CycleCount_StartLocationCC') and (WorkFlowName = 'DirectedCycleCount')

/* Once the location is suggested, we would prompt the user to scan and confirm the right location
   and hence the below step */
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                                  FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 51,           'coalesce(~SuggestedLocation~, '''') <> ''''',
                                                                                   'CycleCount_ScanSuggestedLoc',              'pr_AMF_CycleCount_StartLocationCount',  BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 52,           '(~RFFormAction~ in (''StopDirectedCount''))',
                                                                                   'CycleCount_ScanSuggestedLoc',              'pr_AMF_CycleCount_StopCount',           BusinessUnit from vwBusinessUnits

/* Once user has confirmed the Location, the rest of the workflow is the same */

Go
