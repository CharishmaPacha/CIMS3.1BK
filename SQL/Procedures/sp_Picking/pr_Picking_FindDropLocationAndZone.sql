/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/16  TK      pr_Picking_FindDropLocationAndZone: Fixed issue not suggesting drop location that is selected while releasing (HA-543)
  2020/05/12  TK      pr_Picking_FindDropLocationAndZone: Rules data BatchType - WaveType (HA-503)
  2019/05/23  MS      pr_Picking_FindDropLocationAndZone : Changes to consider valid DropZones (CID-374)
  2018/03/22  OK      pr_Picking_FindDropLocationAndZone: Enhanced to send the PickZone and DestZone count to determine proper dest location (S2G-453)
  2016/07/14  TK      pr_Picking_FindDropLocationAndZone: Changes made to suggest appropriate Drop Zone Or Location (HPI-287)
  2015/07/21  AY      pr_Picking_FindDropLocationAndZone: Code cleanup and corrections
  2015/06/25  RV      pr_Picking_FindDropLocationAndZone: Separated code from pr_Picking_BatchPickResponse and called
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_FindDropLocationAndZone') is not null
  drop Procedure pr_Picking_FindDropLocationAndZone;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_FindDropLocationAndZone: When picking is complete for a task,
    systems needs to suggest a zone and/or Location to drop the pallet or cart.
    This procedure uses the existing drop location on the Wave or rules to
    identify and return the Location and it's corresponding zone or just the zone
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_FindDropLocationAndZone
  (@WaveNo         TWaveNo,
   @WaveType       TLookUpCode,
   @WaveDropLoc    TLocation,
   @TaskId         TRecordId,
   @Operation      TOperation,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @DestDropLoc    TLocation      output,
   @DestDropZone   TZoneId        output)
as
  declare @vPickBatchRuleId           TRecordId,
          @vBatchWarehouse            TWarehouse,
          @vDestZoneAndLocation       TLocation,
          @vPutawayZone               TLookUpCode,
          @xmlRulesData               TXML,

          @vAllOrdersQualifiedToShip  TFlags,
          @vWaveCategory1             TCategory,
          @vWaveWarehouse             TWarehouse;

  declare @ttOrdersQualified          TEntityKeysTable;
begin /* pr_Picking_FindDropLocationAndZone */
  /* Initialize */
  set @vAllOrdersQualifiedToShip = null;

  select @vWaveCategory1 = Category1,
         @vWaveWarehouse = Warehouse
  from Waves
  where (WaveNo       = @WaveNo) and
        (BusinessUnit = @BusinessUnit);

  /* Replenish picked LPNs should be directed to staging Locations in the zone where they should be PA */
  if (@WaveType in ('R', 'RU', 'RP'))
    begin
      /* get the Putawayzone of starting dest location */
      select @vPutawayZone = LOC.PutawayZone
      from Tasks T
        join Locations LOC on (T.StartDestination = LOC.Location)
      where (T.TaskId = @TaskId);
    end
  else
    /* check if other than replenish orders are qualified to ship or not */
    begin
      /* evaluate whether the picked orders are qualified or not */
      insert into @ttOrdersQualified (EntityId)
        select distinct OrderId
        from TaskDetails
        where (TaskId = @TaskId);

      /* check if the pallet which user is trying to drop contains orders which cannot be shipped */
      if exists (select * from @ttOrdersQualified OQ where dbo.fn_OrderHeaders_OrderQualifiedToShip(OQ.EntityId, null, default /* Validation Flags */) = 'N'/* Not - Qualified */)
        set @vAllOrdersQualifiedToShip = 'N';
    end

  /* Build the data for rule evaluation */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('WaveType',                 @WaveType    ) +
                         dbo.fn_XMLNode('WaveNo',                   @WaveNo      ) +
                         dbo.fn_XMLNode('WaveCategory1',            @vWaveCategory1) +
                         dbo.fn_XMLNode('WaveWarehouse',            @vWaveWarehouse) +
                         dbo.fn_XMLNode('TaskId',                   @TaskId      ) +
                         dbo.fn_XMLNode('PutawayZone',              @vPutawayZone) +
                         dbo.fn_XMLNode('DestDropLoc',              @DestDropLoc ) +
                         dbo.fn_XMLNode('BusinessUnit',             @BusinessUnit) +
                         dbo.fn_XMLNode('Operation',                @Operation   ) +
                         dbo.fn_XMLNode('AllOrdersQualifiedToShip', @vAllOrdersQualifiedToShip));

  /* Get the DestZoneAndLocation from Rules - expectation is that Rule will return
     Location OR Zone. If there is a | char, then it is only Zone after the | else it
     is Location */
  exec pr_RuleSets_Evaluate 'DropLocations', @xmlRulesData, @vDestZoneAndLocation output;

  /* If there is a | char, the data after it is the drop Zone */
  if (charindex('|', @vDestZoneAndLocation) > 0)
    select @DestDropLoc  = substring(@vDestZoneAndLocation, 1, charindex('|', @vDestZoneAndLocation) - 1),
           @DestDropZone = substring(@vDestZoneAndLocation, charindex('|', @vDestZoneAndLocation) + 1, 999);
  else
    /* If there is no |, then it is only Location */
    select @DestDropLoc = @vDestZoneAndLocation;

  /* Get the DropZone based on the Drop Location if we have Location but not the zone */
  if (@DestDropLoc is not null) and (nullif(@DestDropZone, '') is null)
    select @DestDropZone = PutawayZone
    from Locations
    where (Location = @DestDropLoc);

  /* If we have zone then get it's description */
  if (@DestDropZone is not null)
    select @DestDropZone = PZ.ZoneDesc
    from vwPutawayZones PZ
    where (PZ.ZoneId = @DestDropZone);

  select @DestDropLoc  = coalesce(@DestDropLoc,  ''),
         @DestDropZone = coalesce(@DestDropZone, '');

end /* pr_Picking_FindDropLocationAndZone */

Go
