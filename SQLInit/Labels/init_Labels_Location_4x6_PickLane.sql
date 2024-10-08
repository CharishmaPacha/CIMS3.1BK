/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/09  AY      Added Location_4x6_PickLane_SKU123 (BK-785)
  2021/09/27  BSP     Use pr_Setup_ContentTemplates (CIMSV3-1639)
  2020/07/29  KBB     Initial revision (BK-449)
------------------------------------------------------------------------------*/

Go

declare @BusinessUnit TBusinessUnit, @UserId TUserId;

/******************************************************************************/
/* Setup the ZPL for Location_4x6_PickLane label */
declare @vLabelZPL1      varchar(max),
        @vTemplateName1  TName ='Location_4x6_PickLane';

/*----------------------------------------------------------------------------*/
select @vLabelZPL1 = '
^XA
^LH<%LabelHomeX%>,0

^FO640,020^FB1218,1,,C^A0R,100,100^FD<%Brand%>^FS

^FO460,020^FB1210,2,,C^A0R,070,070^FD<%Description%>^FS

^FO220,210^BY5^BCR,220,N,Y^FD<%SKU%>^FS

^FO030,020^FB1218,1,,C^A0R,150,150^FD<%SKU%>^FS

^FO000,000^GB812,1218,,,1

^XZ
';

/******************************************************************************/
/* Setup the ZPL for Location_4x6_PickLane_SKU123 label */
declare @vLabelZPL2      varchar(max),
        @vTemplateName2  TName ='Location_4x6_PickLane_SKU123';

/*----------------------------------------------------------------------------*/
select @vLabelZPL2 = '
^XA
^LH<%LabelHomeX%>,0

^FO680,010^FB1218,1,,C^A0R,100,100^FD<%Brand%>^FS
^FO540,020^FB1210,2,,C^A0R,070,070^FD<%Description-L70%>^FS
^FO440,210^BY5^BCR,100,N,Y^FD<%SKU%>^FS
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

^FO020,300^A0R,50,50^FD<%Location%>^FS
^FO020,050^BY2^BCR,50,N,Y^FD<%Location%>^FS

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
      select @vTemplateName1, 'ZPL',        null,      @vLabelZPL1,    null,           'Location',    null,        null,     null
union select @vTemplateName2, 'ZPL',        null,      @vLabelZPL2,    null,           'Location',    null,        null,     null

exec pr_Setup_ContentTemplates 'R' /* Replace */, @BusinessUnit, @UserId;

Go
