/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/21  RIA     Added steps for GetSKUs (HA-2878)
  2021/04/05  TK      LPNType may not be returned always so use EntityType instead, like we use in Adjust Inventory (HA-2542)
  2019/10/28  RIA     Initial Revision(CIMSV3-632)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_TransferInventory';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                   FormName,                                  FormMethod,                             BusinessUnit)
      select @vWorkFlowName, 1,            null,                            'Inventory_TransferLPNInventory',          'pr_AMF_Inventory_ValidateEntity',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~EntityType~ = ''LOC''',        'Inventory_TransferLocationInventory',     'pr_AMF_Inventory_TransferInventory',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~Transfer~ = ''Done''',         'Inventory_TransferLPNInventory',          'pr_AMF_Inventory_ValidateEntity',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~EntityType~ = ''LPN''',        'Inventory_TransferLPNInventory',          'pr_AMF_Inventory_TransferInventory',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 21,           '~RFFormAction~ = ''GetSKUs''',  'Inventory_TransferLPNInventory',          'pr_AMF_Inventory_GetSKUs',             BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 22,           '~RFFormAction~ = ''GetSKUs''',  'Inventory_TransferLocationInventory',     'pr_AMF_Inventory_GetSKUs',             BusinessUnit from vwBusinessUnits

Go
