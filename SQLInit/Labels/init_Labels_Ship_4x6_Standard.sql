/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/11  KBB     Initial revision (BK-468)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Ship_4x6_Standard label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Ship_4x6_Standard';

/*----------------------------------------------------------------------------*/
select @vLabelZPL ='
^XA
^PRC
^LH0,0^FS
^LL1218
^MD0
^MNY

^LH0,0^FS
^FO021,018^A0N,21,18^FDSHIP FROM^FS
^FO021,048^A0N,31,28^FD<%ShipFromName%>^FS
^FO021,092^A0N,27,23^FD<%ShipFromAddress1%>^FS
^FO021,133^A0N,27,23^FD<%ShipFromCityStateZip%>^FS

^FO380,018^A0N,21,18^FDSHIP TO^FS
^FO380,050^A0N,31,28^FD<%ShipToName%>^FS
^FO380,090^A0N,27,23^FD<%ShipToAddress1%>^FS
^FO380,130^A0N,27,23^FD<%ShipToAddress2%>^FS
^FO380,170^A0N,27,23^FD<%ShipToCityStateZip%>^FS

^FO021,221^A0N,21,18^FDSHIP TO POST^FS
^FO147,221^A0N,21,18^FD(420) <%ShipToZip%>^FS
^FO050,255^BY3,3.0^BCN,101,N,N,Y,N^FR^FD>;>842099999^FS

^FO380,226^A0N,30,23^FDCARRIER: <%ShipVia%> ^FS
^FO380,270^A0N,30,23^FDPRO#:<%ProNumber%> ^FS
^FO380,315^A0N,30,23^FDB/L #: <%BillofLading%> ^FS

^FO021,380^A0N,40,35^FDPO: <%CustPO%>^FS
^FO021,430^A0N,40,35^FDPickTicket #: <%PickTicket%>^FS
^FO021,530^A0N,40,35^FDSKU: <%SKU%>^FS
^FO500,530^A0N,40,35^FDQty: <%LPNQuantity%>^FS
^FO021,480^A0N,40,35^FDLPN: <%LPN%>^FS
^FO500,480^A0N,40,35^FDCarton  <%CurrentCarton%> of <%NumberofCartons%>^FS

^FO021,627^A0N,21,18^FDSHIP FOR^FS
^FO125,662^A0N,31,29^FD(91) <%ShipToStore%>^FS

^FO051,701^BY3,3.0^BCN,101,N,N,Y,N^FR^FD>;>891<%ShipToStore%>^FS
^FO480,670^A0N,110,110^FD<%ShipToStore%>^FS

^FO021,825^A0N,21,18^FDSERIAL SHIPPING CONTAINER CODE^FS
^FO102,865^A0N,36,53^FD<%UCCBarcode-F(??) ? ??????? ????????? ?%>^FS
^FO98,909^BY4,3.0^BCN,294,N,N,Y,N^FR^FD>;>8<%UCCBarcode%>^FS

^FO002,811^GB806,0,1^FS
^FO002,608^GB812,0,1^FS
^FO000,204^GB812,0,1^FS
^FO365,000^GB0,365,1^FS
^FO002,366^GB812,0,1^FS
^FO406,609^GB0,203,1^FS
^PQ1,0,0,N
^XZ
';

/*----------------------------------------------------------------------------*/
/* Delete and add new one */
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'ShipLabel',  null,              null,             BusinessUnit from vwBusinessUnits

Go