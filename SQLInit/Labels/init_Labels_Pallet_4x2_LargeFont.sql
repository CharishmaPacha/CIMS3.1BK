/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/05  AJM      Initial revision(HA-364)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Pallet_4x2_LargeFont';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO10,40
^FB802,1,,C
^A0N,50,50^FD<%PalletTypeDesc%>^FS

^FO100,100
^BY5^BCN,150,N,Y^FD<%Pallet%>^FS

^FO10,270
^FB802,1,,C
^A0N,150,150^FD<%Pallet%>^FS

^FO0,0
^GB812,406,,,1

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Pallet',     null,              null,             BusinessUnit from vwBusinessUnits

Go
