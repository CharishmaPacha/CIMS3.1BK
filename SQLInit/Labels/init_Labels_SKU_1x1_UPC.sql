/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/08  KBB     Initial revision(HA-122)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for SKU_1x1_UPC label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'SKU_1x1_UPC';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO55,50
^BY1
^BUN,100,Y,N,Y^FD<%UPC%>^FS

^FO0,0
^GB203,203,,,1

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'SKU',        null,              null,             BusinessUnit from vwBusinessUnits

Go
