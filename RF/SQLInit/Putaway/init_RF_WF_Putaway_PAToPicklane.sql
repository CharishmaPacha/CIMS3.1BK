/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/24  RIA     Changes to form method for PausePutaway (CIMSV3-656)
  2019/10/24  RIA     Renamed form methods (CIMSV3-631)
  2019/08/28  RIA     Added Workflows for Pause and Skip (CID-995)
  2019/08/14  RIA     Initial Revision(CID-910)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Putaway_PAToPicklane';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                               FormMethod,                                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Putaway_PAToPL_ScanPalletOrCart',      'pr_AMF_Putaway_PAToPL_Validate',            BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~PalletInfo_Pallet~ <> ''''',             'Putaway_PAToPickLane',                 'pr_AMF_Putaway_PAToPL_Confirm',             BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~RFFormAction~ = ''PAUSEPUTAWAY''',       'Putaway_PAToPickLane',                 'pr_AMF_Putaway_PAToPL_Pause',               BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~RFFormAction~ = ''SKIPCURRENTSKU''',     'Putaway_PAToPickLane',                 'pr_AMF_Putaway_PAToPL_SkipSKU',             BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '~PalletInfo_Pallet~ = ''''',              'Putaway_PAToPL_ScanPalletOrCart',      'pr_AMF_Putaway_PAToPL_Validate',            BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

