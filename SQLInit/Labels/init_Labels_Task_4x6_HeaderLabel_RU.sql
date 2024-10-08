/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/13  RT      Decreased the font size for date (BK-534)
  2020/05/23  AJM     Initial revision (HA-634)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for Task_4x6_HeaderLabel_RU label */
declare @ttZPL          TZPLLabel;

declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Task_4x6_HeaderLabel_RU';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
LH0,0

^FO025,050^AUN,57,57^FDTask # : <%TaskId%>^FS
^FO620,037^GB88,88,3^FS
^FO650,055^AUN,45,59^FD<%Priority%>^FS
^FO210,110^BY3,2.0^B3N,N,70,N,N^FD<%TaskId%>^FS

^FO025,200^A0N,50,50^FDWave ^FS
^FO280,205^A0N,50,50^FD<%WaveNo%>^FS
^FO280,260^A0N,45,45^FD<%WaveTypeDesc%>^FS

^FO025,330^A0N,45,40^FDReplenish Type^FS
^FO280,330^A0N,40,40^FD<%ReplenishType%>^FS

^FO025,380^A0N,40,40^FDAccount^FS
^FO280,380^A0N,40,40^FD<%AccountName%>^FS

^FO025,430^A0N,40,40^FDPick Zone^FS
^FO280,430^A0N,40,40^FD<%PickZone%>^FS
^FO280,480^A0N,40,40^FD<%PickZoneDesc%>^FS

^FO025,530^A0N,40,40^FDDest Zone^FS
^FO280,530^A0N,40,40^FD<%DestZone%>^FS

^FO025,580^A0N,40,40^FDPicks From^FS
^FO280,580^A0N,40,40^FD<%NumLocations%> Location(s)^FS
^FO280,630^A0N,40,40^FD<%PicksFrom%>^FS

^FO025,680^A0N,40,40^FDPick For^FS
^FO280,680^A0N,40,40^FD<%NumDestinatons%> Destination(s)^FS
^FO280,730^A0N,40,40^FD<%PicksFor%>^FS

^FO000,780^GB812,002,,,2^FS

^FO010,800^FB180,1,0,C^A0N,35,35^FD# LPNs ^FS
^FO250,800^FB180,1,0,C^A0N,35,35^FD# Cases ^FS
^FO500,800^FB180,1,0,C^A0N,35,35^FD# Units ^FS

^FO020,840^FB180,1,0,C^A0N,35,35^FD<%NumLPNs%>^FS
^FO260,840^FB180,1,0,C^A0N,35,35^FD<%NumCases%>^FS
^FO510,840^FB180,1,0,C^A0N,35,35^FD<%Quantity%>^FS

^FO000,880^GB812,002,,,2^FS

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
