/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/15  RIA     Initial Revision(CIMSV3-464)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inquiry_LPN';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                       FormMethod,                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inquiry_LPN_Form',             'pr_AMF_Inquiry_LPN',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~LPN~,'''') <> ''''',            'Inquiry_LPN_Form',             'pr_AMF_Inquiry_LPN',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~OrderId~ <> 0',                          'Inquiry_LPN_Form_Allocated',   'pr_AMF_Inquiry_LPN',        BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~PickTicket~ like ''R%''',                'Inquiry_LPN_Form_Replenish',   'pr_AMF_Inquiry_LPN',        BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

