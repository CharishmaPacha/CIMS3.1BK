/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/04  SK      Initial Revision (HA-1398)
------------------------------------------------------------------------------*/

/* There exists a different workflow for Replenish LPN picking and the following
   workflow only handles Replenish Case/Unit Picking */

declare @vWorkFlowName TName;

select @vWorkFlowName = 'ReplenishBatchPicking';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,   FormSequence, FormCondition,                                       FormName,                          BusinessUnit)
      select @vWorkFlowName,  1,            null,                                                'Replenishment_GetPickTask',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  3,            '~BATCHPICKINFOPickType~ = ''U''',                   'Replenishment_ConfirmUnitPick',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  4,            '~BATCHPICKINFOPickType~ = ''CS''',                  'Replenishment_ConfirmUnitPick',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  5,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (~TaskInfo_PalletType~ like ''C%''))',
                                                                                                 'DropPickingCart_Confirm',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  6,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (~TaskInfo_PalletType~ not like ''C%''))',
                                                                                                 'DropPickingPallet_Confirm',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  7,            '~DROPPEDPALLETINFOErrorNumber~ = ''0''',            'Replenishment_GetPickTask',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  8,            '~BATCHPAUSEINFOErrorNumber~ = ''0''',               'Replenishment_GetPickTask',       BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data