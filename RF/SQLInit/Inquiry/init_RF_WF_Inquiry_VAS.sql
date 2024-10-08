/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/24  NB      FormCondition correction to match with XML returned (CIMSV3-582)
  2019/06/21  RIA     Changes to call pr_AMF_Picking_VASComplete (CID-577)
  2019/05/19  RIA     Initial Revision(CID-382)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inquiry_VAS';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                  FormMethod,                    BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Inquiry_VAS_Form',        'pr_AMF_Inquiry_VAS',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~LPNInfo_LPN~,'''') <> ''''',    'Inquiry_VAS_Form',        'pr_AMF_Inquiry_VAS',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~RFFormAction~ = ''VASCOMPLETE''',        'Inquiry_VAS_Form',        'pr_AMF_Picking_VASComplete',  BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

