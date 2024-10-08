/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/07  KBB      Initial revision (CIMSV3-744)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for LPN_3x2_Large label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'LPN_3x2_LargeFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO10,40
^FB609,1,,C
^A0N,30,30^FD<%LPNTypeDescription%>^FS

^FO90,90
^BY4^BCN,120,N,Y^FD<%LPN%>^FS

^FO10,250
^FB609,1,,C
^A0N,130,130^FD<%LPN%>^FS

^FO0,0
^GB609,406,,,1

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'LPN',        null,              null,             BusinessUnit from vwBusinessUnits

Go
