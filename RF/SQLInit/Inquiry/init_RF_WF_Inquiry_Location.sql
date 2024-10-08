/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/19  RIA     Added step to show different forms for Picklane and other LocationTypes (OB2-1767)
  2019/03/13  NB      Initial Revision(CIMSV3-389)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inquiry_Location';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                                     FormName,                  FormMethod,                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                              'Inquiry_Location_Form',   'pr_AMF_Inquiry_Location',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '(~LocationInfo_LocationType~ in (''K''))',        'Inquiry_Location_PicklaneForm',
                                                                                                                         'pr_AMF_Inquiry_Location',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '(~LocationInfo_LocationType~ not in (''K''))',    'Inquiry_Location_Form',   'pr_AMF_Inquiry_Location',   BusinessUnit from vwBusinessUnits

Go
