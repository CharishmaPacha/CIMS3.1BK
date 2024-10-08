/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/21  RIA    Made changes to display caption (CID-836)
  2019/07/21  RIA     Initial Revision(CID-836)
------------------------------------------------------------------------------*/

declare @vFormName  TName,
        @vHtml      varchar(max);

select @vFormName = 'Replenishment_LPNPick_GetPick';
delete from AMF_Forms where FormName = @vFormName;

/* Fetch the Form for LPN Get Pick Task and change the submenu, operation, PickGroup
   and insert it into Forms */
select @vHtml = RawHtml
from AMF_Forms
where (FormName = 'Picking_LPNPick_GetPick') and (DeviceCategory = 'STD');

/* Adapt it for replenishment */
select @vHtml = replace(@vHtml, 'LPN Picking',          'Replen LPN Picking'), -- Title
       @vHtml = replace(@vHtml, 'CustomerOrderPicking', 'Replenishment'),      -- Operation
       @vHtml = replace(@vHtml, 'RFPicking',            'RFReplenishment'),    -- Submenu
       @vHtml = replace(@vHtml, 'RF-C-L',               'RF-R-L');             -- PickGroup

/* Insert Replenishment form */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Replenish LPN Picking', 'STD', BusinessUnit, @vHtml
from vwBusinessUnits;
