/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/04  SK     Initial Revision (HA-1398)
------------------------------------------------------------------------------*/

declare @vFormName  TName,
        @vHtml      varchar(max);

select @vFormName = 'Replenishment_ConfirmUnitPick';
delete from AMF_Forms where FormName = @vFormName;

/* Fetch the Case/Unit Picking form and change the js methods, operation
   and insert it into Forms */
select @vHtml = RawHtml
from AMF_Forms
where (FormName = 'BatchPicking_ConfirmUnitPick') and (DeviceCategory = 'STD');

/* Adapt it for replenishment */
select @vHtml = replace(@vHtml, 'Confirm Task Pick',     'Replenish Case/Unit Pick'), -- Title
       @vHtml = replace(@vHtml, 'CustomerOrderPicking',  'Replenishment');            -- Operation

/* Insert Replenishment form */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Replenish Confirm Case/Unit Pick', 'STD', BusinessUnit, @vHtml
from vwBusinessUnits;
