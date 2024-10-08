/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_AMF_Info_GetOutstandingPicks, pr_AMF_Info_GetTaskInfoXML: Changes to get PalletType (HA-649)
  2019/07/23  AY      pr_AMF_Info_GetTaskInfoXML: Corrected AssignedTo & added TaskStatus (CID-GoLive)
  2019/07/10  RIA     pr_AMF_Info_GetTaskInfoXML: Changes to add AssignedTo (CID-GoLive)
  2019/06/20  AY      pr_AMF_Info_GetTaskInfoXML: Renamed and added NumCartonsUsed (CID-572)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetTaskInfoXML') is not null
  drop Procedure pr_AMF_Info_GetTaskInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetTaskInfoXML: In V3, we display lot of info in several
    screens and we do not want to depend upon V2 returning the same, so we have
    to fetch all necessary info for presentation
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetTaskInfoXML
  (@TaskId       TRecordId,
   @Operation    TOperation = null,
   @TaskInfoXML  TXML       = null output, -- var char in XML format
   @xmlTaskInfo  XML        = null output) -- true xml data type
as
  declare @vRecordId          TRecordId,
          @vxmlTaskInfo       xml,
          @vAssignedToName    TName,
          @vAssignedTo        TUserId,

          @vPalletId          TRecordId,
          @vPalletType        TTypeCode,
          @vNumLPNsOnCart     TCount,
          @vNumLPNsUsed       TCount;

begin /* pr_AMF_Info_GetTaskInfoXML */

  select @vPalletId   = PalletId,
         @vAssignedTo = AssignedTo
  from Tasks
  where TaskId = @TaskId;

  /* Number of cartons built to the cart */
  select @vNumLPNsOnCart = count(*),
         @vNumLPNsUsed   = sum(Case when Quantity > 0 then 1 else 0 end)
  from LPNs
  where (PalletId = @vPalletId) and (LPNType not in ('A' /* Cart Position */));

  select @vAssignedToName = Name + ' (' + UserName + ')'
  from Users
  where (UserName = @vAssignedTo);

  /* Fetch the PalletType */
  select @vPalletType = PalletType
  from Pallets
  where PalletId = @vPalletId;

  /* Capture Task Information */
  select @vxmlTaskInfo = (select TaskId, TaskType, TaskTypeDescription, TaskSubType, TaskSubTypeDescription,
                                 Status TaskStatus, StatusDescription TaskStatusDesc, WaveNo, WaveTypeDesc,
                                 NumOrders, TotalInnerPacks, TotalUnits, NumLPNs, NumTempLabels,
                                 DetailCount NumPicks, CompletedCount as PicksCompleted, PercentComplete,
                                 coalesce(CartType, 'Picking Cart') CartType, Pallet, @vPalletType as PalletType,
                                 @vNumLPNsOnCart NumCartonsOnCart, @vNumLPNsUsed NumCartonsUsed,
                                 TotalUnitsRemaining UnitsToPick, TotalUnitsCompleted as UnitsPicked,
                                 @vAssignedTo AssignedTo, @vAssignedToName AssignedToName
                          from vwTasks
                          where TaskId = @TaskId
                          for xml raw('TaskInfo'), Elements);

  select @TaskInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('TaskInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlTaskInfo.nodes('/TaskInfo/*') as t(c)
  )
  select @TaskInfoXML = @TaskInfoXML + DetailNode from FlatXML;

  select @TaskInfoXML = coalesce(@TaskInfoXML, '');
  select @xmlTaskInfo = convert(xml, @TaskInfoXML);

end /* pr_AMF_Info_GetTaskInfoXML */

Go

