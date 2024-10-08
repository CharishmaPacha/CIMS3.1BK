/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/15  RIA     Initial Revision(CIMSV3-631)
------------------------------------------------------------------------------*/

declare @vFormName  TName,
        @vHtml      varchar(max);

select @vFormName = 'Replenishment_PutawayLPN';
delete from AMF_Forms where FormName = @vFormName;

/* Fetch the Form for Putaway LPN to Picklane and change the title, submenu and insert
   it into Forms */
select @vHtml = replace(replace(RawHtml, 'RFPutaway', 'RFReplenishment'), 'Putaway LPN', 'Putaway Replenish LPN')
from AMF_Forms
where (FormName = 'Putaway_PutawayToPickLane') and (DeviceCategory = 'STD');

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
  select @vFormName, 'Putaway Replenish LPN', 'STD', BusinessUnit, @vHtml
from vwBusinessUnits;
