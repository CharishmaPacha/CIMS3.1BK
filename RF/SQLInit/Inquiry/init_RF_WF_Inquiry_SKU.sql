/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/12  AY      Initial Revision(CIMSV3-???)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inquiry_SKU';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                  FormMethod,                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inquiry_SKU_Form',        'pr_AMF_Inquiry_SKU',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~SKU~,'''') <> ''''',            'Inquiry_SKU_Form',        'pr_AMF_Inquiry_SKU',        BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

