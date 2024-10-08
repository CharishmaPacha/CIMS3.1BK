/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/23  MS      Initial revision (JL-123)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for LPN_4x3 label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'LPN_4x3_SizeSpread';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA

^LH0,0

^FT295,130
^A0N,70,70^FD<%LPN_UDF6%>^FS

^FT125,180
^A0N,30,30^FD<%SizeScale%>^FS
^FT125,210
^A0N,30,30^FD<%SizeSpread%>^FS

^FT35,250
^A0N,25,25^FD<%SKU2%>^FS

^FT275,250
^A0N,25,25^FDCOLOR:^FS
^FT355,250
^A0N,25,25^FD<%SKU3%>^FS

^FT520,250
^A0N,25,25^FDDIM:^FS
^FT580,250
^A0N,25,25^FD<%SKU4%>^FS

^FT35,290
^A0N,25,25^FDCOUNTRY OF ORIGIN:^FS
^FT275,290
^A0N,25,25^FD<%CoO%>^FS

^FT35,330
^A0N,25,25^FDCARTON DIMENSION:^FS
^FT275,330
^A0N,25,25^FD<%LPN_UDF1%>x<%LPN_UDF2%>x<%LPN_UDF3%>^FS

^FT520,300
^A0N,25,25^FDPACK QTY:^FS
^FT635,300
^A0N,25,25^FD<%Quantity%>^FS

^FT520,330
^A0N,25,25^FDWEIGHT:^FS
^FT615,330
^A0N,25,25^FD<%LPNWeight-N###.00%>^FS

^FT130,410
^A0N,60,60^FD<%LPN%>^FS
^FT150,550
^BY2^BCN,120,N,Y^FD<%LPN%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'LPN',        null,              null,             BusinessUnit from vwBusinessUnits

Go
