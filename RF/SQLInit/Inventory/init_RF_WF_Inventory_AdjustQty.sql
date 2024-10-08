/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/14  RIA     Added steps for GetSKUs (HA-2938)
  2021/01/17  TK      Changed FormCondition to use EntityType instead of LPNType (BK-107)
  2019/09/23  RIA     Changes to workflow (CIMSV3-624)
  2019/06/25  RIA     Initial Revision(CID-593)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_AdjustQty';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                             FormMethod,                             BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inventory_AdjustLPNQty',             'pr_AMF_Inventory_ValidateEntity',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~EntityType~ = ''LOC''',                  'Inventory_AdjustLocationQty',        'pr_AMF_Inventory_AdjustQty',           BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~Resolution~ = ''Done''',                 'Inventory_AdjustLPNQty',             'pr_AMF_Inventory_ValidateEntity',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~EntityType~ = ''LPN''',                  'Inventory_AdjustLPNQty',             'pr_AMF_Inventory_AdjustQty',           BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 21,           '~RFFormAction~ = ''GetSKUs''',            'Inventory_AdjustLocationQty',        'pr_AMF_Inventory_GetSKUs',             BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 22,           '~RFFormAction~ = ''GetSKUs''',            'Inventory_AdjustLPNQty',             'pr_AMF_Inventory_GetSKUs',             BusinessUnit from vwBusinessUnits

Go
