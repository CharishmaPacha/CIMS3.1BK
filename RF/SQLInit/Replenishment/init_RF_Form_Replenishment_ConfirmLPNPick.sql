/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/15  RIA     Changes to css class (CIMSV3-650)
  2019/11/04  RIA     Made changes to display appropriate info (CID-836)
  2019/07/21  RIA     Initial Revision(CID-836)
------------------------------------------------------------------------------*/

declare @vFormName  TName,
        @vHtml      varchar(max);

select @vFormName = 'Replenishment_LPNPick_Confirm';
delete from AMF_Forms where FormName = @vFormName;

/* Fetch the Form for regular LPN Picking and change the js methods, operation
   and insert it into Forms */
select @vHtml = RawHtml
from AMF_Forms
where (FormName = 'Picking_LPNPick_Confirm') and (DeviceCategory = 'STD');

/* Adapt it for replenishment */
select @vHtml = replace(@vHtml, 'LPN Pick',                            'Replenish LPN Pick'), -- Title
       @vHtml = replace(@vHtml, 'CustomerOrderPicking',                'Replenishment'),      -- Operation
       @vHtml = replace(@vHtml, 'Picking_LPNPick_SkipPick',            'Replenishment_LPNPick_SkipPick'),
       @vHtml = replace(@vHtml, 'Picking_LPNPick_PausePicking',        'Replenishment_LPNPick_PausePicking'),
       @vHtml = replace(@vHtml, 'Picking_LPNPickConfirm_OnShow',       'Replenishment_LPNPickConfirm_OnShow');

/* Insert Replenishment form */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Replenish LPN Pick', 'STD', BusinessUnit, @vHtml
from vwBusinessUnits;
