/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/08/22  VKN     Initial Revision (CIMSV3-3034)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_BuildInventory';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                FormName,                     FormMethod,                                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                         'Inventory_BuildInventory',   'pr_AMF_Inventory_ValidateSKU',              BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~SKUInfo_SKU~, '''') <> ''''',      'Inventory_BuildInventory',   'pr_AMF_Inventory_BuildInventoryLPN',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '(~Resolution~ in (''Done''))',               'Inventory_BuildInventory',   'pr_AMF_Inventory_ValidateSKU',              BusinessUnit from vwBusinessUnits

Go
