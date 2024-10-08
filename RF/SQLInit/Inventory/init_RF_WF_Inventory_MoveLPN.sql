/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/29  RIA     Initial Revision(CID-871)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_MoveLPN';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                             FormMethod,                             BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inventory_MoveLPN',                  'pr_AMF_Inventory_ValidateLPN',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~LPNInfo_LPN~ <> ''''',                   'Inventory_MoveLPN',                  'pr_AMF_Inventory_MoveLPN',             BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~LPNInfo_LPN~ = ''''',                    'Inventory_MoveLPN',                  'pr_AMF_Inventory_ValidateLPN',         BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

