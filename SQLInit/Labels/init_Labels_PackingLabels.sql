/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/18  AY      Cleanup (HA-2412)
  2021/03/27  RV      Reduce the ship to address to do not overlap (HA-2412)
  2019/08/03  MS      Initial revision (CID-889)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Packing_LPNLabel label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Packing_4x6_LPNLabel';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH0,0
^PON
^LRN
^CI0

^FO33,310^BY1^BCB,54,N,Y^FD<%PickTicket%>^FS
^FT93,301^A0B,65,88^FD<%CurrentCarton%> of <%NumberofCartons%>^FS

^FT070,1190^A0B,45,55^FDPick Ticket^FS
^FT130,1190^A0B,45,55^FDAccount^FS
^FT190,1190^A0B,45,55^FDCust PO^FS

^FT070,920^A0B,45,55^FD<%PickTicket%>^FS
^FT130,920^A0B,45,55^FD<%AccountName%>^FS
^FT190,920^A0B,45,55^FD<%CustPO%>^FS

^FT260,1190^A0B,45,55^FDShip To:^FS

^FT300,1190^A0B,30,30^FD<%ShipToName%>^FS
^FT340,1190^A0B,30,30^FD<%ShipToAddress1%>^FS
^FT380,1190^A0B,30,30^FD<%ShipToAddress2%> ^FS
^FT420,1190^A0B,30,30^FD<%ShipToCSZ%>^FS

^FT300,600^A0B,30,30^FDShip Via^FS
^FT340,600^A0B,30,30^FDCarton Type^FS
^FT380,600^A0B,30,30^FDWeight ^FS
^FT420,600^A0B,30,30^FDUnits^FS

^FT300,400^A0B,30,40^FD<%ShipViaDesc%>^FS
^FT340,400^A0B,30,30^FD<%CartonTypeDesc%>^FS
^FT380,400^A0B,30,30^FD<%LPNWeight-NG%>^FS
^FT420,400^A0B,30,30^FD<%LPNQuantity%>^FS

^FO436,300^BY4^BCB,100,N,N^FD<%LPN%>^FS
^FO580,020^FB1218,1,,C^A0B,45,60^FD<%LPN%>^FS
^FO640,020^FB1218,1,,C^A0B,45,60^FD<%UCCBarcode%>^FS

^FT720,1193^A0B,30,30^FDMessage: ^FS
^FT720,875^A0B,30,30^FD<%UDF4%> ^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'Generic',    null,              null,             BusinessUnit from vwBusinessUnits

Go
