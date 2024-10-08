/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/09  AY      Initial Revision (BK-785)
------------------------------------------------------------------------------*/

Go

declare @BusinessUnit TBusinessUnit, @UserId TUserId;

/******************************************************************************/
/* Setup the ZPL for Location_4x6_PickLane label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName ='SKU_4x6_PickLane_SKU123';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO680,010^FB1218,1,,C^A0R,100,100^FD<%Brand%>^FS
^FO540,020^FB1210,2,,C^A0R,070,070^FD<%Description-L70%>^FS
^FO440,210^BY5^BCR,150,N,Y^FD<%SKU%>^FS
^FO280,020^FB1218,1,,C^A0R,140,140^FD<%SKU%>^FS

^FO270,050^FB1200,1,,L^A0R,20,20^FDStyle^FS
^FO270,610^FB600,1,,L^A0R,20,20^FDColor^FS
^FO270,610^FB550,1,,R^A0R,20,20^FDSize^FS

^FO160,020^FB1200,1,,L^A0R,100,100^FD<%SKU1%>^FS
^FO160,610^FB600,1,,L^A0R,100,100^FD<%SKU2%>^FS
^FO160,610^FB600,1,,R^A0R,100,100^FD<%SKU3%>^FS

^FO120,020^FB1200,1,,L^A0R,50,50^FD<%SKU1Desc%>^FS
^FO120,610^FB600,1,,L^A0R,50,50^FD<%SKU2Desc%>^FS
^FO120,610^FB600,1,,R^A0R,50,50^FD<%SKU3Desc%>^FS

^FO020,020^FB1218,1,,C^A0R,50,50^FD<%PrimaryLocation%>^FS
^FO020,050^BY2^BCR,50,N,Y^FD<%PrimaryLocation%>^FS

^FO000,000^GB812,1218,,,1

^XZ
';

/*----------------------------------------------------------------------------*/
/* Drop temp table, if it exists and then create the temp table */
if (object_id('tempdb..#ContentTemplates') is not null) drop table #ContentTemplates;

create table #ContentTemplates (RecordId int identity(1, 1) not null);
exec pr_PrepareHashTable 'ContentTemplatesDataSetup', '#ContentTemplates';

insert into #ContentTemplates
            (TemplateName,    TemplateType, LineType,  TemplateDetail, LineCondition,  Category,      SubCategory, SortSeq,  AdditionalData)
      select @vTemplateName,  'ZPL',        null,      @vLabelZPL,     null,           'SKU',    null,        null,     null

exec pr_Setup_ContentTemplates 'R' /* Replace */, @BusinessUnit, @UserId;

Go
