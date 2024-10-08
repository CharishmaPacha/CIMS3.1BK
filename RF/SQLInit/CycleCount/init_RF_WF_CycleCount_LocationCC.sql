/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/08  RIA     Added workflow for Unknown SKU scan in Picklane (HA-2199)
  2020/10/11  SK      Added workflow for PD4 counts as well (HA-1567)
  2020/09/10  SK      Modifications for Location CC Pallet PD3 (HA-1077)
  2020/07/10  SK      Added step for Location CC Pallet depth PD3 (HA-1077)
  2020/07/07  RIA     Added steps for CC Picklane (CIMSV3-773)
  2020/04/01  SK      Modify workflow steps (CIMSV3-788)
  2020/03/29  RIA     Initial Revision(CIMSV3-773)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'LocationCycleCount';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                                  FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'CycleCount_StartLocationCC',              'pr_AMF_CycleCount_StartLocationCount',  BusinessUnit from vwBusinessUnits
/* Mutually exclusive workflow steps below */
union select @vWorkFlowName, 2,            '(coalesce(~LocationInfo_Location~, '''') <> '''') and (~LocationInfo_RequestedCCLevel~ = ''LD2'')',
                                                                                    'Cyclecount_ConfirmReserveLocLD2',         'pr_AMF_CC_ConfirmReserveLoc_LPND2',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '(coalesce(~LocationInfo_Location~, '''') <> '''') and  (~LocationInfo_RequestedCCLevel~ in (''PD3'',''PD4''))',
                                                                                    'Cyclecount_ConfirmReserveLocPD3',         'pr_AMF_CC_ConfirmReserveLoc_Pallet',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '(coalesce(~LocationInfo_Location~, '''') <> '''') and (~LocationInfo_LocationType~ in (''K''))',
                                                                                    'CycleCount_ConfirmPicklaneCount',         'pr_AMF_CycleCount_ConfirmPicklaneCC',   BusinessUnit from vwBusinessUnits
/* Database validations for specific forms  */
union select @vWorkFlowName, 11,           '(~RFFormAction~ in (''CCLocationUnknownLPN'')) and (~LocationInfo_RequestedCCLevel~ = ''LD2'')',
                                                                                    'Cyclecount_ConfirmReserveLocLD2',         'pr_AMF_CycleCount_ValidateUnknownLPN',  BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 12,           '(~RFFormAction~ in (''CCLocationUnknownPallet''))',
                                                                                    'Cyclecount_ConfirmReserveLocPD3',         'pr_AMF_CycleCount_ValidateUnknownPallet',
                                                                                                                                                                        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 13,           '(~RFFormAction~ in (''CCLocationUnknownLPN'')) and (~LocationInfo_RequestedCCLevel~ in (''PD3'',''PD4''))',
                                                                                    'Cyclecount_ConfirmReserveLocPD3',         'pr_AMF_CycleCount_ValidateUnknownLPN',  BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 14,           '(~RFFormAction~ in (''CCLocationUnknownSKU''))',
                                                                                    'CycleCount_ConfirmPicklaneCount',         'pr_AMF_CycleCount_ValidateUnknownSKU',  BusinessUnit from vwBusinessUnits
/* Completing CC in special case after DB validations mid way */
union select @vWorkFlowName, 21,           '(~RFFormAction~ in (''CompleteCC''))',  'Cyclecount_ConfirmReserveLocLD2',         'pr_AMF_CC_ConfirmReserveLoc_LPND2',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 22,           '(~RFFormAction~ in (''CompleteCC''))',  'Cyclecount_ConfirmReserveLocPD3',         'pr_AMF_CC_ConfirmReserveLoc_Pallet',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 23,           '(~RFFormAction~ in (''CompleteCC''))',  'CycleCount_ConfirmPicklaneCount',         'pr_AMF_CycleCount_ConfirmPicklaneCC',   BusinessUnit from vwBusinessUnits
/* Stop and restart */
union select @vWorkFlowName, 31,           '(~RFFormAction~ in (''STOP''))',        'Cyclecount_ConfirmReserveLocLD2',         'pr_AMF_CycleCount_StopCount',           BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 32,           '(~RFFormAction~ in (''STOP''))',        'CycleCount_ConfirmPicklaneCount',         'pr_AMF_CycleCount_StopCount',           BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 33,           '(~RFFormAction~ in (''STOP''))',        'Cyclecount_ConfirmReserveLocPD3',         'pr_AMF_CycleCount_StopCount',           BusinessUnit from vwBusinessUnits
/* Confirmation successfully done re start */
union select @vWorkFlowName, 41,           '(~Resolution~ in (''Done'', ''Stop''))',
                                                                                    'CycleCount_StartLocationCC',              'pr_AMF_CycleCount_StartLocationCount',  BusinessUnit from vwBusinessUnits

Go