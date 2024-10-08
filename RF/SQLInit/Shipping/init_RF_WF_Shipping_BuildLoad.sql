/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/26  RIA     Initial Revision(HA-2675)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Shipping_BuildLoad';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                      FormName,                     FormMethod,                        BusinessUnit)
      select @vWorkFlowName, 1,            null,                               'Shipping_BuildLoad',         'pr_AMF_Shipping_ValidateLoad',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~LoadInfo_LoadNumber~ <> ''''',    'Shipping_BuildLoad',         'pr_AMF_Shipping_Load',            BusinessUnit from vwBusinessUnits

Go