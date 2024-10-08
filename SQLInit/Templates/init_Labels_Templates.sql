/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/24  VM      Use pr_Setup_ContentTemplates (CIMSV3-1109)
  2020/03/27  AY      Initial revision
------------------------------------------------------------------------------*/

Go

declare @BusinessUnit TBusinessUnit, @UserId TUserId;

/******************************************************************************/
/* Setup the ZPL for Template_4x6_LargeFont label when EntityKey is 5-8 chars */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Template_4x6_LargeFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO640,20
^FB1218,1,,C
^A0R,70,70^FD<%EntityTypeDesc%>^FS

^FO350,300
^BY5^BCR,220,N,Y^FD<%EntityKey%>^FS

^FO100,20
^FB1218,1,,C
^A0R,200,200^FD<%EntityKey%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
/* Drop temp table, if it exists and then create the temp table */
if (object_id('tempdb..#ContentTemplates') is not null) drop table #ContentTemplates;

create table #ContentTemplates (RecordId int identity(1, 1) not null);
exec pr_PrepareHashTable 'ContentTemplatesDataSetup', '#ContentTemplates';

insert into #ContentTemplates
            (TemplateName,    TemplateType, LineType, TemplateDetail, LineCondition,  Category,      SubCategory, SortSeq,  AdditionalData)
      select @vTemplateName,  'ZPL',        null,     @vLabelZPL,     null,           'Generic',      null,       null,     null

exec pr_Setup_ContentTemplates 'R' /* Replace */, @BusinessUnit, @UserId;

Go
