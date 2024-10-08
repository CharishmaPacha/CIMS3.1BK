/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/12  RIA     Initial Revision(HA-)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inquiry_SKUStyle';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                  FormMethod,                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inquiry_SKUStyle',        'pr_AMF_Inquiry_SKUStyle',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~SKU~,'''') <> ''''',            'Inquiry_SKUStyle',        'pr_AMF_Inquiry_SKUStyle',   BusinessUnit from vwBusinessUnits

Go
