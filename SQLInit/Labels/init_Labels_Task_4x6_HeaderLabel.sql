/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/13  RT      Decreased the font size for date (BK-534)
  2021/03/05  RKC     Ported changes from prod onsite (BK-75)
  2021/02/22  MS      Changes to print NumCases (BK-182)
  2020/04/25  AJM     Initial revision (HA-322)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Task_4x6_HeaderLabel label */
declare @ttZPL          TZPLLabel;

declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Task_4x6_HeaderLabel';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
LH0,0
^PON

^FO025,050^AUN,57,57^FDTask # :  <%TaskId%>^FS
^FO620,037^GB88,88,3^FS
^FO650,055^AUN,45,59^FD<%Priority%>^FS
^FO210,110^BY3,2.0^B3N,N,70,N,N^FD<%TaskId%>^FS

^FO025,200^A0N,50,50^FDWave ^FS
^FO250,205^A0N,50,50^FD<%WaveNo%>^FS
^FO250,260^A0N,45,45^FD<%WaveTypeDesc%>^FS

^FO025,330^A0N,40,40^FDPick Type^FS
^FO250,330^A0N,40,40^FD<%TaskSubTypeDesc%>^FS

^FO025,380^A0N,40.40^FDAccount^FS
^FO250,380^A0N,40.40^FD<%AccountName%>^FS
^FO025,430^A0N,40.40^FDPick Zone^FS
^FO250,430^A0N,40.40^FD<%PickZone%>^FS
^FO250,480^A0N,40.40^FD<%PickZoneDesc%>^FS
^FO025,530^A0N,40.40^FDPicks From^FS
^FO250,530^A0N,40.40^FD<%PicksFrom%>^FS

^FO000,590^GB812,002,,,2^FS

^FO010,600^FB180,1,0,C^A0N,35,35^FD# Orders ^FS
^FO150,600^FB180,1,0,C^A0N,35,35^FD# Picks ^FS
^FO280,600^FB180,1,0,C^A0N,35,35^FD# Cases ^FS
^FO430,600^FB250,1,0,C^A0N,35,35^FD# Cartons/Totes ^FS
^FO620,600^FB250,1,0,C^A0N,35,35^FD# Units ^FS

^FO010,650^FB180,1,0,C^A0N,35,35^FD<%NumOrders%>^FS
^FO150,650^FB180,1,0,C^A0N,35,35^FD<%NumPicks%>^FS
^FO280,650^FB180,1,0,C^A0N,35,35^FD<%NumCases%>^FS
^FO430,650^FB250,1,0,C^A0N,35,35^FD<%NumTempLabels%>^FS
^FO620,650^FB250,1,0,C^A0N,35,35^FD<%Quantity%>^FS

^FO000,690^GB812,002,,,2^FS

^FO025,1180^A0N,26,26^FDPrinted: <%PrintTime%>^FS
^FO300,1180^FB500,1,0,R^A0N,26,26^FDCreated: <%CreatedDate%>^FS
';

/* The standard label has specific fields. But there may be conditional fields to print, so include those here */
insert into @ttZPL(ZPLCommand) select @vLabelZPL;
insert into @ttZPL(ZPLCommand) select '^XZ';

/* use the below to get the complete ZPL for preview */
--select string_agg(ZPLCommand, char(10)+char(13)) from @ttZPL;

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,    TemplateType, TemplateDetail, SortSeq,   LineCondition,  Category,      SubCategory,  AdditionalData, BusinessUnit)
     select  @vTemplateName,  'ZPL',        ZPLCommand,     Z.SortSeq, Condition,      'Task',        null,         null,           BusinessUnit from vwBusinessUnits, @ttZPL Z

Go
