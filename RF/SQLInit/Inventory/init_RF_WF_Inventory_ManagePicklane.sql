/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/16  RIA     Added steps to stop the operation (HA-1688)
  2021/04/16  RIA     Added steps to refresh the DataTable (HA-1688)
  2021/03/07  RIA     Added step to getskus (HA-1688)
  2020/07/25  RIA     Added steps to handle InvAddClass and included comments (HA-652)
  2020/01/07  RIA     Changes to work flow (CIMSV3-655)
  2020/01/05  RIA     Initial Revision(CIMSV3-643)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_ManagePicklane';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                      FormName,                     FormMethod,                                       BusinessUnit)
      select @vWorkFlowName, 1,            null,                               'Inventory_ManagePicklane',   'pr_AMF_Inventory_ValidatePicklane',              BusinessUnit from vwBusinessUnits
/* If GetInvClasses is applicable and user selected necessary option(AddSKU), we take user to new form */
union select @vWorkFlowName, 2,            '~InventoryClassRequired~ = ''Y''', 'Inventory_MP_AddSKUWithInvClass',
                                                                                                             'pr_AMF_Inventory_ManagePicklane_ManageSKU',      BusinessUnit from vwBusinessUnits
/* If user selected SetUpPicklane, only after completing AddSKU(if present) this gets satisfied */
union select @vWorkFlowName, 3,            '~ConfirmSetupPicklane~ = ''Y''',   'Inventory_SetupPicklane',    'pr_AMF_Inventory_ManagePicklane_SetupPicklane',  BusinessUnit from vwBusinessUnits
/* If user selected AddInventory, only after completing AddSKU/SetUpPicklane(if present) this gets satisfied */
union select @vWorkFlowName, 4,            '~ConfirmAddInventory~ = ''Y''',    'Inventory_AddInventory',     'pr_AMF_Inventory_ManagePicklane_AddInventory',   BusinessUnit from vwBusinessUnits
/* After successfully validating the Picklane, below step gets satisfied */
union select @vWorkFlowName, 5,            '~LocationInfo_Location~ <> ''''',  'Inventory_ManagePicklane',   'pr_AMF_Inventory_ManagePicklane_ManageSKU',      BusinessUnit from vwBusinessUnits
/* If Adding Inv Classes is applicable for client and user selects AddSKU then below step gets called */
union select @vWorkFlowName, 6,            '~RFFormAction~ = ''GetInvClasses''',
                                                                               'Inventory_ManagePicklane',   'pr_AMF_Inventory_ManagePicklane_GetInvClasses',  BusinessUnit from vwBusinessUnits
/* to show the list of SKUs in the Location by filter */
union select @vWorkFlowName, 7,            '~RFFormAction~ = ''GetSKUs''',     'Inventory_ManagePicklane',   'pr_AMF_Inventory_ManagePicklane_GetSKUs',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 8,            '~LocationInfo_Location~ = ''''',   'Inventory_ManagePicklane',   'pr_AMF_Inventory_ValidatePicklane',              BusinessUnit from vwBusinessUnits
/* Whenever user clicks on refresh in any screen, any of the below step gets executed */
union select @vWorkFlowName, 21,            '~RFFormAction~ = ''RefreshDataTable''',
                                                                               'Inventory_ManagePicklane',   'pr_AMF_Inventory_ManagePicklane_RefreshDT',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 22,            '~RFFormAction~ = ''RefreshDataTable''',
                                                                               'Inventory_MP_AddSKUWithInvClass',
                                                                                                             'pr_AMF_Inventory_ManagePicklane_RefreshDT',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 23,            '~RFFormAction~ = ''RefreshDataTable''',
                                                                               'Inventory_SetupPicklane',    'pr_AMF_Inventory_ManagePicklane_RefreshDT',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 24,            '~RFFormAction~ = ''RefreshDataTable''',
                                                                               'Inventory_AddInventory',     'pr_AMF_Inventory_ManagePicklane_RefreshDT',      BusinessUnit from vwBusinessUnits
/* Whenever user clicks on complete, the below step gets executed */
union select @vWorkFlowName, 31,            '~RFFormAction~ = ''Stop''',       'Inventory_ManagePicklane',   'pr_AMF_Common_StopOrPause',                      BusinessUnit from vwBusinessUnits
/* Initialize the screen after stopping the process */
union select @vWorkFlowName, 41,            '(~Resolution~ in (''Done'', ''Stop''))',
                                                                               'Inventory_ManagePicklane',   'pr_AMF_Inventory_ValidatePicklane',              BusinessUnit from vwBusinessUnits

Go
