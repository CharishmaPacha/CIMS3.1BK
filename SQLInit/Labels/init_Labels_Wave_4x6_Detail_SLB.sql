/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/08  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Wave_4x6_Detail_SLB */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Wave_4x6_Detail_SLB';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO640,20
^FB1218,1,,C
^A0R,70,70^FD<%WaveTypeDesc%>^FS

^FO350,300
^BY4^BCR,220,N,Y^FD<%WaveNo%>^FS

^FO100,20
^FB1218,1,,C
^A0R,200,200^FD<%WaveNo%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Wave',       null,              null,             BusinessUnit from vwBusinessUnits

Go
