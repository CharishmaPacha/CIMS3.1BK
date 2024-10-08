/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/15  RIA     Initial Revision(CIMSV3-631)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'ReplenishLPNPutaway';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,   FormSequence, FormCondition,                                        FormName,                           FormMethod,                             BusinessUnit)
      select @vWorkFlowName,  1,            null,                                                 'Replenishment_PutawayLPN',         'pr_AMF_Putaway_ValidatePutawayLPN',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  2,            '~PutawayMode~ = ''U''',                              'Replenishment_PutawayLPN',         'pr_AMF_Putaway_ConfirmPutawayLPN',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  3,            '~LPNInfo_LPN~ = ''''',                               'Replenishment_PutawayLPN',         'pr_AMF_Putaway_ValidatePutawayLPN',    BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

