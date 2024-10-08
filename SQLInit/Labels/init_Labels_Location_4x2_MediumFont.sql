/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/08  KBB     Initial revision(HA-120)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Location_4x2_MediumFont label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Location_4x2_MediumFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FT110,190
^BY4^BCN,150,N,Y^FD<%Location%>^FS

^FT120,300
^A0N100,100^FD<%Location%>^FS

^FT350,360
^A0N,,40,40^FDLocation^FS

^FO0,0
^GB812,406,,,1

^XZ
';


/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Location',   null,              null,             BusinessUnit from vwBusinessUnits

Go
