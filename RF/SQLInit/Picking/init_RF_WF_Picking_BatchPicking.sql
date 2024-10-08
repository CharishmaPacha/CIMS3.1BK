/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/30  RIA     Added Form conditions for drop cart and pallet (HA-649)
  2020/05/26  AY      Split DropPallet/Drop Cart forms (HA-649)
  2019/12/23  RIA     changes to workflow sequence and conditions (CID-1214)
  2019/12/13  RIA     changes to form condition for LPN PickType (CID-1214)
  2019/01/08  NB      changes for addressing renaming of tables for AMF and naming conventions (AMF-26)
  2018/11/14  NB      Initial Revision(CIMSV3-331)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'BatchPicking';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,   FormSequence, FormCondition,                                       FormName,                          BusinessUnit)
      select @vWorkFlowName,  1,            null,                                                'BatchPicking_GetPickTask',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  2,            '~BATCHPICKINFOTaskDetailPickType~ = ''L''',         'BatchPicking_ConfirmLPNPick',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  3,            '~BATCHPICKINFOPickType~ = ''U''',                   'BatchPicking_ConfirmUnitPick',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  4,            '~BATCHPICKINFOPickType~ = ''CS''',                  'BatchPicking_ConfirmUnitPick',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  5,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (~TaskInfo_PalletType~ like ''C%''))',
                                                                                                 'DropPickingCart_Confirm',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  6,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (~TaskInfo_PalletType~ not like ''C%''))',
                                                                                                 'DropPickingPallet_Confirm',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  7,            '~DROPPEDPALLETINFOErrorNumber~ = ''0''',            'BatchPicking_GetPickTask',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName,  8,            '~BATCHPAUSEINFOErrorNumber~ = ''0''',               'BatchPicking_GetPickTask',         BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data
