/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/09  RIA     Changes to workflow (CIMSV3-812)
  2020/04/11  RIA     Changes to workflow (CIMSV3-812)
  2019/08/17  RIA     Changes to complete build (CID-948)
  2019/08/17  RIA     Initial Revision(CID-948)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_AddSKUToLPN';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                FormName,                     FormMethod,                                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                         'Inventory_AddSKUToLPN',      'pr_AMF_Inventory_ValidateLPN',              BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~SKUInfo_SKU~, '''') <> ''''',      'Inventory_AddSKUToLPN',      'pr_AMF_Inventory_AddSKUToLPN',              BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            'coalesce(~LPNInfo_LPN~, '''') <> ''''',      'Inventory_AddSKUToLPN',      'pr_AMF_Inventory_AddSKUToLPN_ValidateSKU',  BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~RFFormAction~ = ''AddSKUToLPNComplete''',   'Inventory_AddSKUToLPN',      'pr_AMF_Common_StopOrPause',                 BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '(~Resolution~ in (''Done''))',               'Inventory_AddSKUToLPN',      'pr_AMF_Inventory_ValidateLPN',              BusinessUnit from vwBusinessUnits

Go
