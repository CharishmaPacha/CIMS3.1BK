/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/06  MS      Correction to LabelFormatName (CIMSV3-804)
  2020/03/19  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Receipt_4x6_LargeFont label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Receipt_4x6_LargeFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO640,20
^FB1218,1,,C
^A0R,70,70^FD<%ReceiptTypeDesc%>^FS

^FO350,300
^BY5^BCR,220,N,Y^FD<%ReceiptNumber%>^FS

^FO100,20
^FB1218,1,,C
^A0R,200,200^FD<%ReceiptNumber%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Receipt',    null,              null,             BusinessUnit from vwBusinessUnits

Go
