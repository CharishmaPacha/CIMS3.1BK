/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/04  MS      Changes to print WaveSeqNo (BK-344)
  2021/04/14  MS      Changes to trim LPNWeight (BK-290)
  2021/03/10  MS      Print LPNWeight & SKU (BK-194)
  2020/05/29  MS      Corrections to BU (HA-660)
  2020/02/14  PHK     Made changes to print the WaveType (CID-751)
  2019/08/10  MS      SetUp ZPL for PTSLabel (CID-909)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Ship_4x6_Generic label */
declare @vPickingLabel4x2  varchar(max),
        @vPickingLabel4x8  varchar(max),
        @vTemplateName     TName = 'PickingLabel';

/*----------------------------------------------------------------------------*/
/* Picking label is the 4 x 2 label which has the picking information that we
   print on PTS packing list or on the 4x8 label */
select @vPickingLabel4x2 = '
^FT50,60
^A0N,35,35^FDWave Type ^FS
^FT220,60
^A0N,35,35^FD<%WaveType%>^FS
^FT50,110
^A0N,35,35^FDWave # ^FS
^FT220,110
^A0N,35,35^FD<%PickBatchNo%>^FS
^FT50,160
^A0N,35,35^FDOrder # ^FS
^FT220,160
^A0N,35,35^FD<%PickTicket%>^FS
^FT50,210
^A0N,35,35^FDCarton # ^FS
^FT220,210
^A0N,35,35^FD<%LPN%>^FS
^FT50,260
^A0N,35,35^FDCarton^FS
^FT220,260
^A0N,35,35^FD<%CartonTypeDesc%>^FS
^FT50,310
^A0N,35,35^FDUnits^FS
^FT220,310
^ASN,40,40^FD<%LPNQuantity%>^FS
^FT50,360
^A0N,35,35^FDWeight^FS
^FT220,360
^ASN,40,40^FD<%LPNWeight-NG%> lbs^FS

^FT440,80
^A0N,35,35^FDTask #^FS
^FT550,80
^AUN,40,40^FD<%TaskId%>^FS
^FT440,200
^A0N,35,35^FDPosition ^FS
^FT480,260
^AVN,80,80^FD<%AlternateLPN%>^FS
^FT440,140
^A0N,35,35^FDSKU^FS
^FT520,140
^A0N,25,25^FD<%SKU%>^FS
^FO400,280
^BY2^BCN,80,N,Y^FD<%LPN%>^FS
^FWB
^FT770,230^A0,25,25^FDOrder <%WaveSeqNo%> of <%WaveNumOrders%>^FS

^FO25,20
^GB760,360,2^FS
';

/*----------------------------------------------------------------------------*/
/* When the Picking label is printed on the 4x8 it is printed on the bottom
   2" portion of the label, hence offset the normal picking label by 6"
   On a 203 dpi printer, that is 1218 dots */
select @vPickingLabel4x8 = '
^FX------Position the label after 6 inches 6 + 203 dpi = 1218 dots -----------
^LH0,1218
' + @vPickingLabel4x2;

/*----------------------------------------------------------------------------*/
/* Delete and add new one */
delete from ContentTemplates where TemplateName like @vTemplateName + '%';

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,     SubCategory,       AdditionalData,   BusinessUnit)
      select 'PickingLabel_4x2',             'ZPL',        @vPickingLabel4x2,       'ShipLabel',  'PTS-Picking',     null,             BusinessUnit from vwBusinessUnits
union select 'PickingLabel_4x8',             'ZPL',        @vPickingLabel4x8,       'ShipLabel',  'PTS-Picking',     null,             BusinessUnit from vwBusinessUnits

Go
