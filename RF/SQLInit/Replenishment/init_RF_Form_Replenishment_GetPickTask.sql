/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/04  SK      Initial Revision (HA-1398)
------------------------------------------------------------------------------*/

declare @vFormName  TName,
        @vHtml      varchar(max);

select @vFormName = 'Replenishment_GetPickTask';
delete from AMF_Forms where FormName = @vFormName;

/* Fetch the Form for Batch Picking Get Pick Task and change the submenu, operation,
   PickGroup and insert it into Forms */
select @vHtml = RawHtml
from AMF_Forms
where (FormName = 'BatchPicking_GetPickTask') and (DeviceCategory = 'STD');

/* Adapt it for replenishment */
select @vHtml = replace(@vHtml, 'Get Task To Pick',     'Replen Case/Unit Picking'), -- Title
       @vHtml = replace(@vHtml, 'CustomerOrderPicking', 'Replenishment'),            -- Operation
       @vHtml = replace(@vHtml, 'RFPicking',            'RFReplenishment'),          -- Submenu
       @vHtml = replace(@vHtml, 'RF-C-CSU',             'RF-R-CSU');                 -- PickGroup

/* Insert Replenishment form */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Replenish Get Pick Task', 'STD', BusinessUnit, @vHtml
from vwBusinessUnits;
