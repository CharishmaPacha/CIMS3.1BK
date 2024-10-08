/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/26  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for LPN_4x6_Large label */
declare @ttZPL          TZPLLabel;

declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'LPN_4x6_SKUPO';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO550,010^FB1218,1,,C^A0R,180,180^FD<%LPN%>^FS
^FO380,200^BY6^BCR,180,N,Y^FD<%LPN%>^FS

^FO240,050^A0R,100,100^FD<%SKU%>^FS
^FO200,050^A0R,50,50^FD<%SKUDescription%>^FS

^FO100,010^FB1200,1,,R^A0R,100,100^FD<%Quantity%> units^FS

^FO040,050^A0R,35,35^FDReceipt <%ReceiptNumber%> (<%ReceiverNumber%>)^FS
^FO040,010^FB1200,1,,R^A0R,35,35^FD<%DateReceived%>^FS
';

/* The standard label has specific fields. But there may be conditional fields to print, so include those here */
insert into @ttZPL(ZPLCommand) select @vLabelZPL;
insert into @ttZPL(ZPLCommand, Condition) select '^FO190,010^FB1200,1,,R^A0R,60,60^FD<%InnerPacks%> cases^FS', '<%InnerPacks%> <> 0';
insert into @ttZPL(ZPLCommand) select '^XZ';

/* use the below to get the complete ZPL for preview */
--select string_agg(ZPLCommand, char(10)+char(13)) from @ttZPL;

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,    TemplateType, TemplateDetail, SortSeq,   LineCondition,  Category,      SubCategory,  AdditionalData, BusinessUnit)
     select  @vTemplateName,  'ZPL',        ZPLCommand,     Z.SortSeq, Condition,      'LPN',         null,         null,           BusinessUnit from vwBusinessUnits, @ttZPL Z

Go
