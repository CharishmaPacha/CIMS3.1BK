/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/22  RIA     Changes to form condition to handle pause/drop pallet (CIMSV3-1093)
  2020/06/05  RIA     Added Form conditions for drop cart and pallet (HA-649)
  2019/11/22  RIA     Initial Revision(CIMSV3-650)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'LPNPicking';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,   FormSequence, FormCondition,                                        FormName,                           FormMethod,                             BusinessUnit)
      select @vWorkFlowName,  1,            null,                                                 'Picking_LPNPick_GetPick',          'pr_AMF_Picking_LPNPick_GetPick',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  2,            '~LPNPIckInfo_PickType~ = ''L''',                     'Picking_LPNPick_Confirm',          'pr_AMF_Picking_LPNPick_Confirm',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  3,            '~RFFormAction~ = ''PAUSEPICKING''',                  'Picking_LPNPick_Confirm',          'pr_AMF_Picking_LPNPick_PausePick',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  4,            '~RFFormAction~ = ''SKIPCURRENTPICK''',               'Picking_LPNPick_Confirm',          'pr_AMF_Picking_LPNPick_SkipPick',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  5,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (~TaskInfo_PalletType~ not like ''C%''))',
                                                                                                  'DropPickingPallet_Confirm',        'pr_AMF_Picking_LPNPick_DropPallet',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  6,            '(~Resolution~ in (''Pause'', ''Done''))',            'Picking_LPNPick_GetPick',          'pr_AMF_Picking_LPNPick_GetPick',       BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

