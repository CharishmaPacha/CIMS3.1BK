/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/02  AY      Revised to print more info (HA Mock GoLive)
  2021/02/15  PHK     Made corrections to print the data correctly (HA-1972)
  2020/07/23  PHK/AY  Initial revision
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Pallet_4x6_ShippingPallet';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO720,20^FB609,1,,L^A0R,50,50^FDLoad <%LoadNumber%>^FX<%PalletTypeDesc%>^FS
^FO710,600^FB600,1,,R^A0R,80,80^FD____  of  ____^FX^FS

^FO550,320^BY5^BCR,150,N,Y^FD<%Pallet%>^FS
^FO400,10^FB1218,1,,C^A0R,120,120^FD<%Pallet%>^FS

^FO330,20^A0R,80,80^FD<%AccountName%>^FS
^FO200,20^A0R,50,50^FD^FXSold To <%SoldToId%>-<%SoldToName%>^FS
^FO230,20^A0R,80,80^FDPO <%CustPO%>^FS

^FO130,20^A0R,30,30^FDWave <%WaveType%> <%WaveNo%>^FS
^FO020,20^A0R,100,100^FD<%NumLPNs%> Cartons^FS

^FO270,1000^A0R,25,25^FDShip To DC/Store^FS
^FO060,600^FB600,1,,R^A0R,200,200^FR^FD<%ShipToStore%>^FS
^FO030,600^FB600,1,,R^A0R,40,40^FD<%ShipToCity%>, <%ShipToState%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Pallet',     null,              null,             BusinessUnit from vwBusinessUnits

Go
