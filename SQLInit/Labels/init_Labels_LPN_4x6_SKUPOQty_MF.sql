/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/05  RKC     Ported changes from prod onsite (BK-75)
  2021/02/22  MS      Enabled cases to print on label (BK-182)
  2020/10/09  MS      Added LD_UnitsPerPackage (HA-1473)
  2020/09/10  KBB     Added Reference Field (HA-1412)
  2020/05/04  AY      Revised to print ReceiverNumber
  2020/04/11  AY      Added UPC & Location (HA-168)
  2020/03/22  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for LPN_4x6_Large label */
declare @ttZPL          TZPLLabel;

declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'LPN_4x6_SKUPOQty_MF';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO550,020^FB1218,1,,C^A0R,180,180^FD<%LPN%>^FS
^FO340,200^BY6^BCR,220,N,Y^FD<%LPN%>^FS

^FO240,050^A0R,80,80^FD<%SKU%>^FS
^FO210,050^A0R,35,35^FD<%SKUDescription%>^FS

^FO160,150^BY2^BUR,40,Y,N^FD<%UPC%>^FS

^FO250,630^A0R,60,60^FD<%Reference%>^FS

^FO090,050^A0R,35,35^FDReceipt <%ReceiptNumber%> (<%ReceiverNumber%>)^FS

^FO140,800^A0R,60,60^FD<%Quantity%> units^FS

^FO040,050^A0R,35,35^FDLocation <%Location%>^FS
^FO040,800^A0R,35,35^FD<%DateReceived%>^FS
';

/* The standard label has specific fields. But there may be conditional fields to print, so include those here */
insert into @ttZPL(ZPLCommand) select @vLabelZPL;
insert into @ttZPL(ZPLCommand, Condition) select '^FO190,800^A0R,60,60^FD<%InnerPacks%> cases^FS', '<%InnerPacks%> <> 0';
insert into @ttZPL(ZPLCommand) select '^XZ';

/* use the below to get the complete ZPL for preview */
--select string_agg(ZPLCommand, char(10)+char(13)) from @ttZPL;

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,    TemplateType, TemplateDetail, SortSeq,   LineCondition,  Category,      SubCategory,  AdditionalData, BusinessUnit)
     select  @vTemplateName,  'ZPL',        ZPLCommand,     Z.SortSeq, Condition,      'LPN',         null,         null,           BusinessUnit from vwBusinessUnits, @ttZPL Z

Go
