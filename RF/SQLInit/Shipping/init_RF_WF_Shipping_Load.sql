/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/25  RIA     Changes to form method (CIMSV3-689)
  2020/01/22  RIA     Initial Revision(CIMSV3-689)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Shipping_Load';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                      FormName,                     FormMethod,                        BusinessUnit)
      select @vWorkFlowName, 1,            null,                               'Shipping_Load',              'pr_AMF_Shipping_ValidateLoad',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~LoadInfo_LoadNumber~ <> ''''',    'Shipping_Load',              'pr_AMF_Shipping_Load',            BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

