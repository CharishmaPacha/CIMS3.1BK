/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/31  VM      Initial Revision (HA-79)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Misc_ChangeWarehouse';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                             FormMethod,                             BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Misc_ChangeWarehouse',               'pr_AMF_Misc_ChangeWarehouse',          BusinessUnit from vwBusinessUnits

Go
