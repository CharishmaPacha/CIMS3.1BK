/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/14  RIA     Changes to work flow (CIMSV3-636)
  2019/10/30  RIA     Initial Revision(CIMSV3-636)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_XferInventory';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                   FormName,                             FormMethod,                             BusinessUnit)
      select @vWorkFlowName, 1,            null,                            'Inventory_XferLPNInventory',         'pr_AMF_Inventory_ValidateEntity',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~LPNType~ = ''L''',             'Inventory_XferLocationInventory',    'pr_AMF_Inventory_TransferInventory',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~Transfer~ = ''Done''',         'Inventory_XferLPNInventory',         'pr_AMF_Inventory_ValidateEntity',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~LPNType~ <> ''L''',            'Inventory_XferLPNInventory',         'pr_AMF_Inventory_TransferInventory',   BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here..
 
 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

