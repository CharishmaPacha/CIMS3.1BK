/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  AY      Changes to Load detail label to print Trailer #
  2020/11/29  PK      Added ShipFrom, ShipTo, ShipVia and ShipViaDesc (HA-1723).
  2020/04/07  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Load_4x6_Simple label */
declare @vLabelZPL1      varchar(max),
        @vTemplateName1  TName = 'Load_4x6_Simple';

/*----------------------------------------------------------------------------*/
select @vLabelZPL1 = '
^XA
^LH<%LabelHomeX%>,0

^FO640,020^FB1218,1,,C^A0R,070,070^FD<%LoadTypeDesc%>^FS

^FO350,220^BY5^BCR,220,N,Y^FD<%LoadNumber%>^FS
^FO100,020^FB1218,1,,C^A0R,200,200^FD<%LoadNumber%>^FS

^FO000,000^GB812,1218,,,1

^XZ
';

/******************************************************************************/
/* Setup the ZPL for Load_4x6_Details label */
declare @vLabelZPL2      varchar(max),
        @vTemplateName2  TName = 'Load_4x6_Details';

/*----------------------------------------------------------------------------*/
select @vLabelZPL2 = '
^XA
^LH<%LabelHomeX%>,0

^FT740,020^FB1218,1,,C^A0R,70,70^FD<%LoadTypeDesc%>^FS

^FT680,060^A0R,40,40^FDShip From/To:^FS
^FT680,300^A0R,40,40^FD<%ShipFrom%> to <%ShipToName%>^FS

^FT600,060^A0R,70,70^^FD<%AccountName%>^FS
^FT600,010^FB1218,1,,R^A0R,70,70^FD<%ClientLoad%>^FS

^FT430,220^BY5^BCR,150,N,Y^FD<%LoadNumber%>^FS
^FT250,020^FB1218,1,,C^A0R,180,180^FD<%LoadNumber%>^FS

^FT140,020^FB1218,1,,C^A0R,70,70^FD<%TrailerNumber%>^FS
^FT040,020^FB1218,1,,L^A0R,40,40^FD<%ShipViaDescription%> (<%ShipVia%>)^FS
^FT040,010^FB1218,1,,R^A0R,40,40^FD<%DesiredShipDate-Dd%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName1;
delete from ContentTemplates where TemplateName = @vTemplateName2;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName1,                'ZPL',        @vLabelZPL1,              'Load',       null,              null,             BusinessUnit from vwBusinessUnits
union select @vTemplateName2,                'ZPL',        @vLabelZPL2,              'Load',       null,              null,             BusinessUnit from vwBusinessUnits

Go
