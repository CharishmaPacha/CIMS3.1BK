/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  RIA     Changed form method (OB2-1773)
  2021/03/16  RIA     Added workflow for complete/done returns (OB2-1357)
  2021/02/12  RIA     Changes to formcondition, name and nethod (OB2-1357)
  2020/02/24  RIA     Initial Revision(CIMSV3-732)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Return_RMA';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                             FormName,                      FormMethod,                            BusinessUnit)
      select @vWorkFlowName, 1,            null,                                      'Returns_ScanRMA',             'pr_AMF_Returns_ValidateEntity',       BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '(coalesce(~Entity~, '''') <> '''')',      'Returns_StartReturns',        'pr_AMF_Returns_ConfirmReceiveRMA',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '(~RFFormAction~ in (''ValidateEntity''))','Returns_StartReturns',        'pr_AMF_Returns_ValidateLPNOrLocation',BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '(~RFFormAction~ in (''ValidateSKU''))',   'Returns_StartReturns',        'pr_AMF_Returns_ValidateSKU',          BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 5,            '(~Resolution~ in (''Done''))',            'Returns_ScanRMA',             'pr_AMF_Returns_ValidateEntity',       BusinessUnit from vwBusinessUnits

Go
