/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/30  RIA     Changed form confition (OB2-1783)
  2020/05/15  RIA     Renamed Inquiry_Pallet_Picking_Form to Inquiry_Pallet_PickingCart_Form (HA-433)
  2020/05/08  RIA     Changed form conditions (HA-433)
  2020/05/06  AY      Setup Inquiry form for Receiving Pallet (HA-433)
  2019/05/31  RIA     WorkFlowName changes (CIMSV3-463)
  2019/05/15  RIA     Initial Revision(CIMSV3-463)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Inquiry_Pallet';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
            (FormSequence, FormCondition,                             FormName,                  FormMethod,                  WorkFlowName,   BusinessUnit)
      select 1,            null,                                      'Inquiry_Pallet_Form',     'pr_AMF_Inquiry_Pallet',     @vWorkFlowName, BusinessUnit from vwBusinessUnits
union select 2,            'coalesce(~Pallet~,'''') <> '''' and (~TaskId~ > 0) and (~PalletType~ = ''C'')',
                                                                      'Inquiry_Pallet_PickingCart_Form',
                                                                                                 'pr_AMF_Inquiry_Pallet',     @vWorkFlowName, BusinessUnit from vwBusinessUnits
union select 3,            'coalesce(~Pallet~,'''') <> ''''',         'Inquiry_Pallet_Form',     'pr_AMF_Inquiry_Pallet',     @vWorkFlowName, BusinessUnit from vwBusinessUnits

Go
