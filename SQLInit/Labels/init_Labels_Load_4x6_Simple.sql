/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/29  PK      Added ShipFrom, ShipTo, ShipVia and ShipViaDesc (HA-1723).
  2020/04/07  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Load_4x6_Simple label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Load_4x6_Simple';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FT740,020^FB1218,1,,C^A0R,70,70^FD<%LoadTypeDesc%>^FS

^FT680,060^A0R,40,40^FDShip From:^FS
^FT680,260^A0R,40,40^FD<%ShipFrom%>^FS

^FT630,060^A0R,40,40^FDShip To:^FS
^FT630,260^A0R,40,40^FD<%ShipToName%>^FS

^FT350,220^BY5^BCR,220,N,Y^FD<%LoadNumber%>^FS

^FT180,020^FB1218,1,,C^A0R,180,180^FD<%LoadNumber%>^FS

^FT040,020^FB1218,1,,C^A0R,40,40^FD<%ShipViaDescription%> (<%ShipVia%>)^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Receiver',   null,              null,             BusinessUnit from vwBusinessUnits

Go
