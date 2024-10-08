/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/09  RIA     Initial Revision(CID-1211)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Putaway_CompleteVAS';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                      FormMethod,                            BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Putaway_CompleteVAS',         'pr_AMF_Putaway_CompleteVAS_Validate', BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~LocationInfo_Location~ <> ''''',         'Putaway_CompleteVAS',         'pr_AMF_Putaway_CompleteVAS_Confirm',  BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

