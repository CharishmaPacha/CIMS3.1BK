/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/03  BSP     Initial revision (BK-934)
------------------------------------------------------------------------------*/

Go

declare @BusinessUnit TBusinessUnit, @UserId TUserId;

/******************************************************************************/
/* Setup the ZPL for LPN_3x2_SKUDetails label */
declare @vLabelZPL       varchar(max),
        @vTemplateName   TName = 'LPN_3x2_SKUDetails';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO010,040^FB609,1,,C^A0N,30,30^FD<%LPNTypeDescription%>^FS

^FO100,090^BY3^BCN,120,N,Y^FD<%LPN%>^FS

^FO010,230^FB609,1,,C^A0N,90,90^FD<%LPN%>^FS

^FO020,340^A0N,40,40^FD<%SKU%>^FS
^FO020,380^A0N,15,15^FDSKU^FS

^FO430,340^A0N,30,30^FD<%Quantity%>^FS
^FO430,380^A0N,15,15^FDQuantity^FS

^FO004,004^GB602,399,,,1

^XZ
';

/*----------------------------------------------------------------------------*/
if (object_id('tempdb..#ContentTemplates') is not null) drop table #ContentTemplates;

create table #ContentTemplates (RecordId int identity(1, 1) not null);
exec pr_PrepareHashTable 'ContentTemplatesDataSetup', '#ContentTemplates';

insert into #ContentTemplates
            (TemplateName,    TemplateType, LineType, TemplateDetail, LineCondition,  Category,    SubCategory, SortSeq,  AdditionalData)
      select @vTemplateName,  'ZPL',        null,     @vLabelZPL,     null,           'LPN',       null,        null,     null

exec pr_Setup_ContentTemplates 'R' /* Replace */, @BusinessUnit, @UserId;

Go
