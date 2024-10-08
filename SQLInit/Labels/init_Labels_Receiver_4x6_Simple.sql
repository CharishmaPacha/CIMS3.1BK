/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/19  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Receiver_4x6_Simple label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Receiver_4x6_Simple';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO640,20
^FB1218,1,,C
^A0R,70,70^FDReceiver^FS

^FO350,260
^BY5^BCR,220,N,Y^FD<%ReceiverNumber%>^FS

^FO100,20
^FB1218,1,,C
^A0R,200,200^FD<%ReceiverNumber%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Receiver',   null,              null,             BusinessUnit from vwBusinessUnits

Go
