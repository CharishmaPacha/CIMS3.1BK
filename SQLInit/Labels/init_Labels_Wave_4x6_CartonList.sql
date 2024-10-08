/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/12  KBB     Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Wave_4x6_CartonList */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Wave_4x6_CartonList';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO025,050^A0N,50,50^FDWave ^FS
^FO150,050^A0N,50,50^FD<%WaveTypeDesc%> <%WaveNo%>^FS
^FO150,130^BY3^BCN,110,N,Y^FD<%WaveNo%>^FS

^FO025,280^A0N,45,45^FDAccount^FS
^FO200,280^A0N,45,45^FD<%AccountName%>^FS

^FO025,350^A0N,40,40^FD# Orders^FS
^FO225,350^A0N,40,40^FD# Cartons^FS
^FO475,350^A0N,40,40^FD# Units^FS
^FO025,400^A0N,40,40^FD<%NumOrders%>^FS
^FO225,400^A0N,40,40^FD<%LPNsAssigned%>^FS
^FO475,400^A0N,40,40^FD<%NumUnits%>^FS

^FO020,475^GB560,40,40^FS
^FO025,480^A0N,35,35^FR^FDCarton Type           # Cartons Required^FS
^FO025,530^FB780,8,8^ACN,30,20^FD<%CartonTypesList%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Wave',       null,              null,             BusinessUnit from vwBusinessUnits

Go
