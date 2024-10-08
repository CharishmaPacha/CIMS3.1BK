/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/05  RIA     Added Form conditions for drop pallet (HA-649)
  2019/11/11  RIA     Renamed form methods (CIMSV3-650)
  2019/11/04  RIA     Made changes to workflow (CID-836)
  2019/07/21  RIA     Initial Revision(CID-836)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'ReplenishLPNPicking';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,   FormSequence, FormCondition,                                        FormName,                           FormMethod,                             BusinessUnit)
      select @vWorkFlowName,  1,            null,                                                 'Replenishment_LPNPick_GetPick',    'pr_AMF_Picking_LPNPick_GetPick',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  2,            '~LPNPIckInfo_PickType~ = ''L''',                     'Replenishment_LPNPick_Confirm',    'pr_AMF_Picking_LPNPick_Confirm',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  3,            '~RFFormAction~ = ''PAUSEPICKING''',                  'Replenishment_LPNPick_Confirm',    'pr_AMF_Picking_LPNPick_PausePick',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  4,            '~RFFormAction~ = ''SKIPCURRENTPICK''',               'Replenishment_LPNPick_Confirm',    'pr_AMF_Picking_LPNPick_SkipPick',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  5,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (~TaskInfo_PalletType~ not like ''C%''))',
                                                                                                  'DropPickingPallet_Confirm',        'pr_AMF_Picking_LPNPick_DropPallet',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  6,            '(~Resolution~ in (''Pause'', ''Done''))',            'Replenishment_LPNPick_GetPick',    'pr_AMF_Picking_LPNPick_GetPick',       BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

