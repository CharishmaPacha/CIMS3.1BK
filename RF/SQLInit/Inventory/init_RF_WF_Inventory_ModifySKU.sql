/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/13  RIA     Changes to form method names (CIMSV3-1108)
  2020/10/20  RIA     Changes to form condition to confirm only on button click (CIMSV3-1108)
  2020/10/01  RIA     Initial Revision(CIMSV3-1108)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_ModifySKU';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                               FormMethod,                              BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'Inventory_ModifySKU',                  'pr_AMF_Inventory_ValidateSKU',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~SKUInfo_SKU~, '''') <> ''''', 'Inventory_ModifySKU',                  'pr_AMF_Inventory_ValidateSKU',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~RFFormAction~ = ''Modify''',           'Inventory_ModifySKU',                  'pr_AMF_Inventory_ModifySKU',            BusinessUnit from vwBusinessUnits

Go
