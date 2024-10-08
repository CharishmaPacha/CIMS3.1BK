/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/07  KBB      Initial revision(HA-50)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Receipt_4x6_MediumFont label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Receipt_4x6_MediumFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO640,20
^FB1218,1,,C
^A0R,70,70^FD<%ReceiptTypeDesc%>^FS

^FO350,160
^BY5^BCR,220,N,Y^FD<%ReceiptNumber%>^FS

^FO100,20
^FB1218,1,,C
^A0R,150,150^FD<%ReceiptNumber%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Receipt',    null,              null,             BusinessUnit from vwBusinessUnits

Go
