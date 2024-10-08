/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/09  RIA     Corrected Form Name for Start Receiving and adapted it for ASN receiving (JL-296)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/02/03  RIA     Initial Revision(CIMSV3-652)
------------------------------------------------------------------------------*/

declare @vFormName  TName,
        @vHtml      varchar(max);

select @vFormName = 'Receiving_ReceiveASN_StartReceiving';
delete from AMF_Forms where FormName = @vFormName;

/* Fetch the Form for Start Receiving and change the title, operation, others
   and insert it into Forms */
select @vHtml = RawHtml
from AMF_Forms
where (FormName = 'Receiving_StartReceiving') and (DeviceCategory = 'STD');

/* Adapt it for ReceiveASNLPN */
select @vHtml = replace(@vHtml, 'Start Receiving',      'Start ASN Receiving'), -- Title
       @vHtml = replace(@vHtml, '"ReceiveInventory"',   '"ReceiveASNLPN"');      -- Operation

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
  select @vFormName, 'Start ASN Receiving', 'STD', BusinessUnit, @vHtml
  from vwBusinessUnits;
