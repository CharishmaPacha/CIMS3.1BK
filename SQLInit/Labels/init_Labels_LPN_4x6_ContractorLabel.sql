/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/01  AY      Added TaskId (HA MockGoLive)
  2020/09/04  AY      Added ShipToName (HA-1385)
  2020/07/28  AY      Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for LPN_4x6_ContractorLabel */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'LPN_4x6_ContractorLabel';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO580,020^FB1218,1,,C^A0R,180,180^FD<%LPN%>^FS
^FO430,200^BY6^BCR,150,N,Y^FD<%LPN%>^FS

^FO320,020^FB600,1,,C^A0R,80,80^FD<%SKU1%>^FS
^FO320,650^FB300,1,,C^A0R,80,80^FD<%SKU2%>^FS
^FO320,900^FB300,1,,C^A0R,80,80^FD<%SKU3%>^FS
^FO300,020^FB600,1,,C^A0R,30,30^FDStyle^FS
^FO300,650^FB300,1,,C^A0R,30,30^FDColor^FS
^FO300,900^FB300,1,,C^A0R,30,30^FDSize^FS

^FO140,950^FB250,1,,C^A0R,100,100^FD<%Quantity%>^FS
^FO100,950^FB250,1,,C^A0R,30,30^FDUnits^FS

^FO230,050^A0R,50,50^FDPO <%CustPO%>^FS
^FO180,050^A0R,50,50^FDLot <%vwLPN_UDF1%>^FS
^FO130,050^A0R,50,50^FDCoO <%CoO%>^FS

^FO050,050^A0R,80,80^FDTransfer # <%PickTicket%>^FS
^FO010,050^A0R,50,50^FDShip To <%ShipToName%>^FS

^FO010,950^FB250,1,,C^A0R,30,30^FD<%TaskId%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'LPN',        null,              null,             BusinessUnit from vwBusinessUnits

Go
