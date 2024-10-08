/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/17  SK      Workflows to be based on RFFormAction value (HA-905)
  2020/05/23  SK      Initial Revision (HA-640)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Picking_ActivateShipCartons';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;

insert into AMF_WorkFlowDetails
             (WorkFlowName,  FormSequence, FormCondition,                      FormName,                           FormMethod,                                       BusinessUnit)
      select @vWorkFlowName, 1,            null,                               'Picking_ActivateShipCartons',      'pr_AMF_Picking_ShipCartonActivation_Validate',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 2,            '~LPN~ <> ''''',                    'Picking_ActivateShipCartons',      'pr_AMF_Picking_ShipCartonActivation_Confirm',    BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 3,            '~m_LPN~ = ''''',                   'Picking_ActivateShipCartons',      'pr_AMF_Picking_ShipCartonActivation_Validate',   BusinessUnit from vwBusinessUnits
union select @vWorkFlowName, 4,            '~RFFormAction~ = ''Validate''',    'Picking_ActivateShipCartons',      'pr_AMF_Picking_ShipCartonActivation_Validate',   BusinessUnit from vwBusinessUnits

Go