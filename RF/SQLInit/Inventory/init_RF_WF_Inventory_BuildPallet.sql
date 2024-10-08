/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/20  RIA     Corrected workflow for Build Pallet to work in all cases (CID-947)
  2019/08/19  RIA     Added workflow for Build Pallet to pause or complete build (CID-967)
  2019/08/16  RIA     Initial Revision(CID-947)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_BuildPallet';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                             FormMethod,                             BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inventory_BuildPallet',              'pr_AMF_Inventory_ValidatePallet',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~Operation~ = ''MovePallet''',            'Inventory_MovePallet',               'pr_AMF_Inventory_MovePallet',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~PalletInfo_Pallet~ <> ''''',             'Inventory_BuildPallet',              'pr_AMF_Inventory_BuildPallet_AddLPN',  BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~RFFormAction~ = ''CompleteBuild''',      'Inventory_BuildPallet',              'pr_AMF_Inventory_BuildPallet_PauseOrComplete',
                                                                                                                                                                    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '~PalletInfo_Pallet~ = ''''',              'Inventory_BuildPallet',              'pr_AMF_Inventory_ValidatePallet',      BusinessUnit from vwBusinessUnits

Go



 -- Remove BusinessUnits from here..
 
 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

