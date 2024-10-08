/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/19  RIA     Initial Revision(HA-2347)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inquiry_Load';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                       FormMethod,                    BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inquiry_Load_Form',            'pr_AMF_Inquiry_Load',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~LoadNumber~,'''') <> ''''',     'Inquiry_Load_Form',            'pr_AMF_Inquiry_Load',         BusinessUnit from vwBusinessUnits

Go
