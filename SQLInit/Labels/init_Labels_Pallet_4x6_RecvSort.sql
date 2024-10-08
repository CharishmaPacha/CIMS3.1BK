/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/26  MS      WaveNo is Duplicated, Hence use WaveNumber for LPN Fields in Label (JL-221)
  2020/03/04  MS      Corrections to label (JL-125)
  2019/12/27  MS      Initial revision (JL-39)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Pallet_4x6_RecvSort */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Pallet_4x6_RecvSort';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA

^FT50,1180
^A0B,35,35^FDDivision ^FS
^FT50,1050
^A0B,35,35^FD<%Division%>^FS

^FT100,1180
^A0B,35,35^FDReceipt^FS
^FT100,1050
^A0B,45,45^FD<%ReceiptTypeDesc%> <%ReceiptNumber%>^FS

^FT170,1180
^A0B,35,35^FDCut^FS
^FT170,1050
^AVB,50,50^FD<%CustPO%>^FS

^FT220,1180
^A0B,35,35^FDStyle^FS
^FT220,1050
^A0B,45,45^FD<%SKU2%>^FS

^FT270,1180
^A0B,35,35^FDColor^FS
^FT270,1050
^A0B,45,45^FD<%SKU3%>^FS

^FT380,1180
^A0B,50,50^FD<%SalesOrderInfo%>^FS

^FT130,500
^A0B,120,120^FDLane <%DestLocation%>^FS

^FT200,500
^A0B,35,35^FD<%CrossDockInfo%>^FS

^FT200,300
^A0B,35,35^FD<%WaveNumber%>^FS

^FT280,500
^A0B,35,35^FDBOXES^FS
^FT280,300
^A0B,45,45^FD<%NumLPNs%>^FS

^FT330,500
^A0B,35,35^FDTotal Units^FS
^FT330,300
^A0B,35,35^FD<%Quantity%>^FS
----
----^FT380,500
----^A0B,35,35^FD^FXLocation#^FS
----^FT380,300
----^A0B,35,35^FD^FX<%Location%>^FS
----
^FT440,1100
^A0B,30,30^FD^^FXSKU#:^FS
^FT440,1150
^A0B,30,30^FD<%SKU1%>^FS

^FT480,950
^A0B,35,35^FD<%SizeScale%>^FS
^FT520,950
^A0B,35,35^FD<%SizeSpread%>^FS

^FT450,320
^A0B,30,30^FD<%CurrentDateTime-DMM/dd/yyyy%>^FS
^FT480,320
^A0B,30,30^FD<%CurrentDateTime-Dhh:mm:ss%>^FS

^FT630,1000
^A0B,120,120^FD<%Pallet%>^FS
^FO650,140
^BY5^BCB,100,N,N^FD<%Pallet%>^FS

^FO400,50
^GB380,1130,3^FS

^XZ
'

/*----------------------------------------------------------------------------*/
/* Delete and add new one */
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'ShipLabel',  'PalletLabel-ZPL', null,             BusinessUnit from vwBusinessUnits

Go
