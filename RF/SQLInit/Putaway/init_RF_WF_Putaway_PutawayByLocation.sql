/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/12  RIA     Initial Revision(CIMSV3-647)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Putaway_PutawayByLocation';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                      FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'Putaway_PutawayByLocation',   'pr_AMF_Putaway_PAByLoc_Validate',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~LocationInfo_Location~ <> ''''',       'Putaway_PutawayByLocation',   'pr_AMF_Putaway_PAByLoc_ConfirmLPN',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~RFFormAction~ = ''Completed''',        'Putaway_PutawayByLocation',   'pr_AMF_Putaway_PAByLoc_ConfirmLPN',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~LocationInfo_Location~ = ''''',        'Putaway_PutawayByLocation',   'pr_AMF_Putaway_PAByLoc_Validate',       BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

