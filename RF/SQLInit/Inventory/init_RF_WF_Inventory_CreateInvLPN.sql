/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/04  RIA     Initial Revision(HA-1839)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_CreateInvLPN';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                FormName,                     FormMethod,                                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                         'Inventory_CreateInvLPN',     'pr_AMF_Inventory_ValidateSKU',              BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~SKUInfo_SKU~, '''') <> ''''',      'Inventory_CreateInvLPN',     'pr_AMF_Inventory_CreateInventoryLPN',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '(~Resolution~ in (''Done''))',               'Inventory_CreateInvLPN',     'pr_AMF_Inventory_ValidateSKU',              BusinessUnit from vwBusinessUnits

Go
