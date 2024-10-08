/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/22  YJ      Initial Revision(CIMSV3-828)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inquiry_ReceiptOrder';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                       FormMethod,                    BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inquiry_ReceiptOrder_Form',    'pr_AMF_Inquiry_ReceiptOrder', BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~ReceiptNumber~,'''') <> ''''',  'Inquiry_ReceiptOrder_Form',    'pr_AMF_Inquiry_ReceiptOrder', BusinessUnit from vwBusinessUnits

Go
