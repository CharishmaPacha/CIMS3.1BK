/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  AJM     Initial revision (HA-1802)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Setup the ZPL for CC task header label */
declare @vLabelZPL      varchar(max),
        @vTemplateName  TName = 'Task_4x6_CycleCount';

/*----------------------------------------------------------------------------*/
select @vLabelZPL = '
^XA
^LH<%LabelHomeX%>,0

^FO025,050^A0N,50,50^FDBatch: ^FS
^FO170,050^A0N,50,50^FD <%BatchNo%>^FS
^FO180,120^BY3^BCN,110,N,Y^FD<%BatchNo%>^FS

^FO170,250^A0N,50,50^FD<%TaskSubTypeDesc%>^FS

^FO025,330^A0N,40,40^FDPriority:^FS
^FO300,330^A0N,40,40^FD<%Priority%>^FS
^FO025,380^A0N,40,40^FDScheduled Date:^FS
^FO300,380^A0N,40,40^FD<%ScheduledDate%>^FS

^FO025,430^A0N,40,40^FDLocations:^FS
^FO300,430^A0N,40,40^FD<%StartLocation%> ...^FS
^FO300,480^A0N,40,40^FD<%EndLocation%>^FS
^FO025,530^A0N,40,40^FDAssignedTo:^FS
^FO300,530^A0N,40,40^FD<%AssignedTo%>^FS

^XZ
';

/*----------------------------------------------------------------------------*/
delete from ContentTemplates where TemplateName = @vTemplateName;

insert into ContentTemplates
            (TemplateName,                   TemplateType, TemplateDetail,          Category,              SubCategory,       AdditionalData,   BusinessUnit)
      select @vTemplateName,                 'ZPL',        @vLabelZPL,              'CycleCountTasks',     null,              null,             BusinessUnit from vwBusinessUnits

Go