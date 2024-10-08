/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/09  RIA     Corrected Form Name for Start Receiving (JL-296)
  2020/05/17  RIA     Changed operation (HA-491)
  2020/03/17  RIA     Initial Revision(CIMSV3-755)
------------------------------------------------------------------------------*/

declare @vFormName  TName,
        @vHtml      varchar(max);

select @vFormName = 'Receiving_ReceiveToLoc_StartReceiving';
delete from AMF_Forms where FormName = @vFormName;

/* Fetch the Form for Start Receiving and change the title, operation, others
   and insert it into Forms */
select @vHtml = RawHtml
from AMF_Forms
where (FormName = 'Receiving_StartReceiving') and (DeviceCategory = 'STD');

/* Adapt it for ReceiveToLoc */
select @vHtml = replace(@vHtml, 'Start Receiving',      'Start Receive To Location'), -- Title
       @vHtml = replace(@vHtml, '"ReceiveInventory"',   '"ReceiveToLocation"');      -- Operation

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
  select @vFormName, 'Start Receive To Location', 'STD', BusinessUnit, @vHtml
  from vwBusinessUnits;
