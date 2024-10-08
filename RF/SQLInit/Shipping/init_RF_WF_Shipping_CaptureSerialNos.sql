/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/17  RIA     Initial Revision
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Shipping_CaptureSerialNo';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                           FormName,                     FormMethod,                                  BusinessUnit)
      select @vWorkFlowName, 1,            null,                                    'Shipping_CaptureSerialNo',   'pr_AMF_Shipping_SerialNos_ValidateLPN',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            'coalesce(~LPNInfo_LPN~, '''') <> ''''', 'Shipping_CaptureSerialNo',   'pr_AMF_Shipping_SerialNos_Capture',         BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '(~Resolution~ in (''Done''))',          'Shipping_CaptureSerialNo',   'pr_AMF_Shipping_SerialNos_ValidateLPN',     BusinessUnit from vwBusinessUnits

Go
