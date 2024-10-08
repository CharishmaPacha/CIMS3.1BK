/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/20  RIA     Made changes to form methods and form condition (CIMSV3-1071)
  2020/07/01  RIA     Added condition for palletized LPN Reservation (HA-790)
  2020/05/30  RIA     Added conditions for drop pallet and cart (HA-649)
  2020/05/26  AY      Split DropPallet/Drop Cart forms (HA-649)
  2019/01/08  NB      changes for addressing renaming of tables for AMF and naming conventions (AMF-26)
  2018/11/14  NB      Initial Revision(CIMSV3-331)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'DropPickingPallet';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                          FormName,                               FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 1,            null,                                                   'DropPickingCart_Confirm',              'pr_AMF_Picking_InitiatePalletDrop',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (nullif(~DROPPALLETRESPONSETaskId~,'''') is null))',
                                                                                                   'DropReservedPallet_Confirm',           'pr_AMF_Picking_DropPickedPallet',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (~TaskInfo_PalletType~ like ''C%''))',
                                                                                                   'DropPickingCart_Confirm',              'pr_AMF_Picking_DropPickedPallet',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '((coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''') and (~TaskInfo_PalletType~ not like ''C%''))',
                                                                                                   'DropPickingPallet_Confirm',            'pr_AMF_Picking_DropPickedPallet',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '~Resolution~ = ''Done''',                              'DropPickingCart_Confirm',              'pr_AMF_Picking_InitiatePalletDrop',     BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

