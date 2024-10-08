/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/26  RIA     Initial Revision (HA-2087)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Shipping_CancelShipCartons';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;

insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                      FormName,                           FormMethod,                                       BusinessUnit)
      select @vWorkFlowName, 1,            null,                               'Shipping_CancelShipCartons',       'pr_AMF_Shipping_CancelShipCartons_Validate',     BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '(coalesce(~LPNInfo_LPN~, '''') <> '''')',
                                                                               'Shipping_CancelShipCartons',       'pr_AMF_Shipping_CancelShipCartons_Confirm',      BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '(~Resolution~ in (''Done''))',     'Shipping_CancelShipCartons',       'pr_AMF_Shipping_CancelShipCartons_Validate',     BusinessUnit from vwBusinessUnits

Go
