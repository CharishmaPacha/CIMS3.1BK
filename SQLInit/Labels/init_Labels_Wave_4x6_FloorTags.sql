/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/09  AY     Initial revision (HA-2974)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Wave floor tags by Style/Color/Size */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Wave_4x6_FloorTagsBySKU';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO750,020^A0R,40,40^FD<%WaveNo%>^FS
^FO750,020^FB1190,1,,R^A0R,40,40^FD<%AccountName%>^FS

^FX Horizontal line after Wave info
^FO740,10^GB0,1200,3^FS

^FO510,010^FB1200,1,,C^A0R,150,150^FD<%SKU1%>^FS
^FO500,010^FB1200,1,,C^A0R,30,30^FDStyle^FS

^FO280,010^FB1200,1,,C^A0R,150,150^FD<%SKU2%>^FS
^FO270,010^FB1200,1,,C^A0R,30,30^FDColor^FS

^FO060,010^FB1200,1,,C^A0R,150,150^FD<%SKU3%>^FS
^FO050,010^FB1200,1,,C^A0R,30,30^FDSize^FS

^FO200,020^FB600,1,,C^A0R,120,120^FX<%SKU2%>^FS
^FO150,020^FB600,1,,C^A0R,40,40^FXColor^FS

^FX Below commented on purpose
^FX To be used if Color - Size are to be displayed next to each other

^FO200,620^FB600,1,,C^A0R,120,120^FX<%SKU3%>^FS
^FO150,620^FB600,1,,C^A0R,40,40^FXSize^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,              SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'WaveDetails',         null,              null,             BusinessUnit from vwBusinessUnits;

Go
