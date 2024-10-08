/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/20  KBB     Added InvAllocationModel (HA-2365)
  2021/03/02  AY      Revised to print more info (HA Mock GoLive)
  2021/02/24  AY/KBB  Initial revision (HA-2045)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Wave by Style */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Wave_4x6_ByStyleColor';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO190,040^BY3^BCN,110,N,Y^FD<%WaveNo%>^FS
^FO270,170^A0N,50,50^FD<%WaveNo%>^FS

^FO025,260^A0N,40,40^FDAccount^FS
^FO350,260^A0N,40,40^FD<%AccountName%>^FS
^FO025,320^A0N,40,40^FDWH #^FS
^FO350,320^A0N,40,40^FD<%Warehouse%>^FS
^FO025,380^A0N,40,40^FD# Orders^FS
^FO350,380^A0N,40,40^FD<%NumOrdersPerWave%>^FS
^FO025,440^A0N,40,40^FD# Cartons/Units^FS
^FO350,440^A0N,40,40^FD<%NumLPNsPerWave%> / <%NumUnitsPerWave%>^FS

^FO025,500^A0N,40,40^FDAllocation Model^FS
^FO350,500^A0N,40,40^FD<%InvAllocationModel%>^FS

^FO25,575^GB762,0,3^FS

^FO025,590^A0N,40,40^FDStyle:^FS
^FO150,590^A0N,50,50^FD<%SKU1%>^FS

^FO025,650^A0N,40,40^FDColor:^FS
^FO150,650^A0N,50,50^FD<%SKU2%>^FS

^FO050,710^BY2^BCN,110,N,Y^FD<%SKU1%>_<%SKU2%>^FS

^FO050,850^^A0N,40,40^FD<%SKU3Count%> Sizes, <%UnitToShipForGroup%> Units^FS


^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,              SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'PickBatchDetails',    null,              null,             BusinessUnit from vwBusinessUnits;

Go
