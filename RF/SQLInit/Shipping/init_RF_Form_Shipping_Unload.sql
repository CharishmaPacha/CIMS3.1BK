/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/22  RIA     Initial Revision(CIMSV3-690)
------------------------------------------------------------------------------*/

declare @vFormName  TName,
        @vHtml      varchar(max);

select @vFormName = 'Shipping_Unload';
delete from AMF_Forms where FormName = @vFormName;

/* Fetch the Form for Load Pallet/LPN and change the captions and insert
   it into Forms */
select @vHtml = replace(replace(RawHtml, 'Load Pallet/LPN', 'Unload Pallet/LPN'), 'LoadLPNOrPallet', 'UnloadLPNOrPallet')
from AMF_Forms
where (FormName = 'Shipping_Load') and (DeviceCategory = 'STD');

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
  select @vFormName, 'Unload Pallet/LPN', 'STD', BusinessUnit, @vHtml
  from vwBusinessUnits;
