/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/23  RIA     Initial Revision(CIMSV3-691)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Shipping_CaptureTrackingNo';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                      FormName,                      FormMethod,                            BusinessUnit)
      select @vWorkFlowName, 1,            null,                               'Shipping_CaptureTrackingNo',  'pr_AMF_Shipping_ValidateLPN',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~LPNInfo_LPN~ <> ''''',            'Shipping_CaptureTrackingNo',  'pr_AMF_Shipping_CaptureTrackingNo',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~CAPTUREINFORESPONSE_ErrorMessage~ <> ''''',
                                                                               'Shipping_CaptureTrackingNo',  'pr_AMF_Shipping_ValidateLPN',         BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data
