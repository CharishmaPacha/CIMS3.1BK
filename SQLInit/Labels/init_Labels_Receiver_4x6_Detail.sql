/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/19  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Receiver_4x6_Detail label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Receiver_4x6_Detail';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO700,20
^FB1218,1,,C
^A0R,70,70^FDReceiver^FS

^FO530,260
^BY5^BCR,150,N,Y^FD<%ReceiverNumber%>^FS

^FO300,20
^FB1218,1,,C
^A0R,200,200^FD<%ReceiverNumber%>^FS

^FO280,50^A0R,25,25^FDContainer^FS
^FO200,50^A0R,70,70^FD<%Container%>^FS

^FO170,50^A0R,25,25^FDPO^FS
^FO100,50^A0R,70,70^FD<%ReceiverRef1%>^FS

^FO50,50^A0R,30,30^FDDate: <%ReceiverDate-Ddd/MM/yyyy%>^FS

^FO130,800^A0R,70,70^FD<%ReceiverRef2%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Receiver',   null,              null,             BusinessUnit from vwBusinessUnits

Go
