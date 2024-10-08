/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/15  KBB     Initial revision(HA-1502)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Location_4x6 Large font label */
declare @vLabelZPL1      varchar(max),
        @vTemplateName1  TName = 'Location_4x6_LargeFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL1 = '
^XA
^LH<%LabelHomeX%>,0

^FO640,20^FB1218,1,,C^A0R,070,070^FD<%LocationTypeDesc%>^FS

^FO350,300^BY5^BCR,220,N,Y^FD<%Location%>^FS

^FO100,020^FB1218,1,,C^A0R,200,200^FD<%Location%>^FS

^FO000,000^GB812,1218,,,1

^XZ
';

/******************************************************************************/
/* Setup the ZPL for Location_4x6_MediumFont label */
declare @vLabelZPL2      varchar(max),
        @vTemplateName2  TName = 'Location_4x6_MediumFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL2 = '
^XA
^LH<%LabelHomeX%>,0

^FO640,20^FB1218,1,,C^A0R,070,070^FD<%LocationTypeDesc%>^FS

^FO350,220^BY5^BCR,220,N,Y^FD<%Location%>^FS

^FO110,020^FB1218,1,,C^A0R,170,170^FD<%Location%>^FS

^FO000,000^GB812,1218,,,1

^XZ
';

/******************************************************************************/
/* Setup the ZPL for Location_4x6_SmallFont label */
declare @vLabelZPL3      varchar(max),
        @vTemplateName3  TName = 'Location_4x6_SmallFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL3 = '
^XA
^LH<%LabelHomeX%>,0

^FO640,20^FB1218,1,,C^A0R,070,070^FD<%LocationTypeDesc%>^FS

^FO350,110^BY4^BCR,220,N,Y^FD<%Location%>^FS

^FO140,020^FB1218,1,,C^A0R,080,080^FD<%Location%>^FS

^FO000,000^GB812,1218,,,1

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName in (@vTemplateName1, @vTemplateName2, @vTemplateName3);

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName1,                'ZPL',        @vLabelZPL1,             'Location',   null,              null,             BusinessUnit from vwBusinessUnits
union select @vTemplateName2,                'ZPL',        @vLabelZPL2,             'Location',   null,              null,             BusinessUnit from vwBusinessUnits
union select @vTemplateName3,                'ZPL',        @vLabelZPL3,             'Location',   null,              null,             BusinessUnit from vwBusinessUnits

Go
