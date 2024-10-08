/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/11  RIA     Initial Revision(CID-911)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inventory_MovePallet';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                             FormMethod,                             BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inventory_MovePallet',               'pr_AMF_Inventory_ValidatePallet',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~PalletInfo_Pallet~ <> ''''',             'Inventory_MovePallet',               'pr_AMF_Inventory_MovePallet',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~PalletInfo_Pallet~ = ''''',              'Inventory_MovePallet',               'pr_AMF_Inventory_ValidatePallet',      BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

