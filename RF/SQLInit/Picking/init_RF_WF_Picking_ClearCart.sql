/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/17  RIA     Initial Revision(CID-591)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'ClearCart';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                 FormName,                        FormMethod,                                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                          'Picking_ClearCart',             'pr_AMF_Picking_ClearCart',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~Pallet~,'''') <> ''''',             'Picking_ClearCart',             'pr_AMF_Picking_ClearCart',       BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data
