/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/17  RIA     Initial Revision(CIMSV3-623)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Putaway_PutawayPallet';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                 FormName,                      FormMethod,                          BusinessUnit)
      select @vWorkFlowName, 1,            null,                                          'Putaway_PutawayPallet',       'pr_AMF_Putaway_PAPallet_Validate',  BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~PalletInfo_Pallet~, '''') <> ''''', 'Putaway_PutawayPallet',       'pr_AMF_Putaway_PAPallet_Confirm',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~PalletInfo_Pallet~ = ''''',                  'Putaway_PutawayPallet',       'pr_AMF_Putaway_PAPallet_Validate',  BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

