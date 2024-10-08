/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/09  PHK      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Printer_3x2_MediumFont label - suitable for DeviceId/DeviceName of upto 20 chars */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Printer_3x2_MediumFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0
^ML1624
^SS,,,,

^FO10,50
^FB609,1,,C
^A0N,60,60^FD<%DeviceName%>^FS

^FO50,130
^BY2^BCN,120,N,Y^FD<%DeviceId%>^FS

^FO10,300
^FB609,1,,C
^A0N,60,60^FD<%PrinterPort%>^FS

^FO0,0
^GB609,406,,,1

^XZ
';

/******************************************************************************/
/* Setup the ZPL for Printer_3x2_SmallFont label suitable for DeviceId/Name for upto 30 chars */
declare @vLabelZPL2      varchar(max),
        @vTemplateName2  TName = 'Printer_3x2_SmallFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL2 = '
^XA
^LH<%LabelHomeX%>,0
^ML1624
^SS,,,,

^FO10,50
^FB609,1,,C
^A0N,40,40^FD<%DeviceName%>^FS

^FO120,130
^BY1^BCN,120,N,Y^FD<%DeviceId%>^FS

^FO10,300
^FB609,1,,C
^A0N,60,60^FD<%PrinterPort%>^FS

^FO0,0
^GB609,406,,,1

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;
delete from ContentTemplates where TemplateName = @vTemplateName2;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Printer',    null,              null,             BusinessUnit from vwBusinessUnits
union select @vTemplateName2,                'ZPL',        @vLabelZPL2,             'Printer',    null,              null,             BusinessUnit from vwBusinessUnits

Go
