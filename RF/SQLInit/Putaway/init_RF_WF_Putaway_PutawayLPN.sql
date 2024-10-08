/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/24  RIA     Renamed form methods (CIMSV3-631)
  2019/07/16  RIA     Initial Revision(CID-726)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Putaway_PutawayLPN';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                      FormMethod,                            BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Putaway_PutawayLPN',          'pr_AMF_Putaway_ValidatePutawayLPN',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~PutawayMode~ = ''U'' and ~LPNInfo_Quantity~ > ''0''',
                                                                                      'Putaway_PutawayToPickLane',   'pr_AMF_Putaway_ConfirmPutawayLPN',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~PutawayMode~ <> ''U'' and ~LPNInfo_Quantity~ > ''0''',
                                                                                      'Putaway_PutawayLPN',          'pr_AMF_Putaway_ConfirmPutawayLPN',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~LPNInfo_LPN~ = ''''',                    'Putaway_PutawayLPN',          'pr_AMF_Putaway_ValidatePutawayLPN',   BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

