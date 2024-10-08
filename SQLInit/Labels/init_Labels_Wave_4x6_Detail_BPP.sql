/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/23  AY      Add CustPO (HA Mock GoLive)
  2020/05/08  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Wave_4x6_Detail_BPP */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Wave_4x6_Detail_BPP';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO700,020^FB1218,1,,C^A0R,70,70^FD<%WaveTypeDesc%> Wave^FS

^FO550,350^BY4^BCR,150,N,Y^FD<%WaveNo%>^FS

^FO350,020^FB1218,1,,C^A0R,150,150^FD<%WaveNo%>^FS

^FO250,050^A0R,70,70^FD<%AccountName%>^FS
^FO180,050^A0R,70,70^FDPO: <%CustPO%>^FS

^FO140,050^A0R,35,35^FD# Orders <%NumOrders%>^FS
^FO100,050^A0R,35,35^FD# Cartons/Units <%LPNsAssigned%> /  <%NumUnits%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Wave',       null,              null,             BusinessUnit from vwBusinessUnits

Go
