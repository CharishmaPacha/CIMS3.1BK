/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/17  RKC     Included new steps to redirect to drop pallet screen (HA-2115)
  2020/05/31  RIA     Condition for LPN Unallocate (HA-727)
  2020/05/29  RIA     Included step to get available lpns based on SKU selected(HA-521)
  2020/05/27  RIA     Changes to form conditions to consider Order/PickTicket (HA-521)
  2020/05/25  RIA     Included step to validate scanned LPN (HA-521)
  2020/05/21  TK      WIP Changes (HA-521)
  2020/02/02  RIA     Initial Revision(CIMSV3-677)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Picking_LPNReservation';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;

insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                         FormName,                           FormMethod,                                       BusinessUnit)
      select @vWorkFlowName, 1,            null,                                                  'Picking_LPNReservation',           'pr_AMF_Picking_LPNReservation_Validate',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '(coalesce(~OrderInfo_PickTicket~, '''') <> '''') or (coalesce(~WaveInfo_WaveNo~, '''') <> '''')',
                                                                                                  'Picking_LPNReservation',           'pr_AMF_Picking_LPNReservation_Confirm',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~RFFormAction~ = ''UnallocateLPN''',                  'Picking_LPNReservation',           'pr_AMF_Picking_LPNReservation_Confirm',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~RFFormAction~ = ''ValidateLPN''',                    'Picking_LPNReservation',           'pr_AMF_Picking_LPNReservation_ValidateLPN',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '~RFFormAction~ = ''GetAvailableLPNs''',               'Picking_LPNReservation',           'pr_AMF_Picking_LPNReservation_GetAvailableLPNs', BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 6,            '~RFFormAction~ = ''CompleteReservation''',            'Picking_LPNReservation',           'pr_AMF_Picking_InitiatePalletDrop',              BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 21,           '(coalesce(~DROPPALLETRESPONSEPallet~,'''') <> '''')', 'DropReservedPallet_Confirm',       'pr_AMF_Picking_DropPickedPallet',                BusinessUnit from vwBusinessUnits
/* Return to the first screen */
union select @vWorkFlowName, 22,           '~DROPPEDPALLETINFOErrorNumber~ = ''0''',              'Picking_LPNReservation',           'pr_AMF_Picking_LPNReservation_Validate',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 31,           '(~Resolution~ in (''Pause'', ''Done''))',             'Picking_LPNReservation',           'pr_AMF_Picking_LPNReservation_Validate',         BusinessUnit from vwBusinessUnits
Go
