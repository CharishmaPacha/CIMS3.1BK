/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/13  VS      pr_Entities_RequestRecalcCounts: Passed EntityStatus to RecalcCulate the Entity (BK-910)
  2021/05/04  AY      pr_Entities_RequestRecalcCounts: Handle null entries (HA Go Live)
  2021/04/10  AY/RKC  pr_Entities_RequestRecalcCounts: Changed to ignore nulls (HA-2593)
  2021/04/03  AY      pr_Entities_RequestRecalcCounts, pr_Entities_RecalcCounts: Revised to process
  2017/08/29  TK      pr_Entities_RequestRecalcCounts: Initial Revision (HPI-1644)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entities_RequestRecalcCounts') is not null
  drop Procedure pr_Entities_RequestRecalcCounts ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entities_RequestRecalcCounts: It inserts the given entities into
    RecalcCounts table, to defer updates to entites. Input can be individual
    entity or a list of entities passed in as @RecountKeysTable or thru
    #EntitesToRecalc: RecalcCounts
------------------------------------------------------------------------------*/
Create Procedure pr_Entities_RequestRecalcCounts
  (@Entity            TEntity,
   @EntityId          TRecordId     = null,
   @EntityKey         TEntityKey    = null,
   @RecalcOption      TFlags        = 'SC',
   @ProcId            TInteger      = 0,
   @Operation         TOperation    = null,
   @BusinessUnit      TBusinessUnit = null,
   @EntityStatus      TStatus       = null,
   @RecountKeysTable  TRecountKeysTable READONLY)
as
  declare @ttRecountKeysTable    TRecountKeysTable;
begin /* pr_Entities_RequestRecalcCounts */
  SET NOCOUNT ON;

  /* $ is used to indicate to defer it, so if $ is sent here, this goes into infinite loop */
  select @RecalcOption = replace (@RecalcOption, '$', ''); -- strip out the $

  /* If user passed in EntityId only, then get EntityKey and BU as well */
  if (@EntityId is not null) and (@EntityKey is null)
    begin
      /* If Entity is Wave then get Wave info */
      if (@Entity = 'Wave')
        select @EntityKey    = WaveNo,
               @BusinessUnit = BusinessUnit
        from Waves
        where (WaveId = @EntityId);
      else
      /* If Entity is Order then get Order info */
      if (@Entity = 'Order')
        select @EntityKey    = PickTicket,
               @BusinessUnit = BusinessUnit
        from OrderHeaders
        where (OrderId = @EntityId);
      else
      /* If Entity is Location then get Location info */
      if (@Entity = 'Location')
         select @EntityKey    = Location,
                @BusinessUnit = BusinessUnit
         from Locations
         where (LocationId = @EntityId);
      else
      /* If Entity is LPN then get LPN info */
      if (@Entity = 'LPN')
         select @EntityKey    = LPN,
                @BusinessUnit = BusinessUnit
         from LPNs
         where (LPNId = @EntityId);
      else
      /* If Entity is Load then get Load info */
      if (@Entity = 'Load')
         select @EntityKey    = LoadNumber,
                @BusinessUnit = BusinessUnit
         from Loads
         where (LoadId = @EntityId);
    end

  /* If user passed in EntityId and EntityKey then insert them and exit for better performance - no need to use temp table */
  if (@EntityId is not null) and (@EntityKey is not null)
    begin
      insert into RecalcCounts(EntityType, EntityId, EntityKey, EntityStatus, RecalcOption, Operation, ProcedureName, BusinessUnit)
        select @Entity, @EntityId, @EntityKey, @EntityStatus, @RecalcOption, @Operation, Object_Name(@ProcId), @BusinessUnit

      return;
    end

  /* insert entites to recalc counts */
  if exists(select * from @RecountKeysTable) and (@Entity is not null)
    begin
      insert into RecalcCounts(EntityType, EntityId, EntityKey, EntityStatus, RecalcOption, Operation, ProcedureName, BusinessUnit)
        select @Entity, EntityId, EntityKey, @EntityStatus, @RecalcOption, @Operation, Object_Name(@ProcId), @BusinessUnit
        from @RecountKeysTable
        where (EntityId is not null or EntityKey is not null);
    end

  /* Record all entities from #EntitiesToRecalc */
  if (object_id('tempdb..#EntitiesToRecalc') is not null)
    insert into RecalcCounts(EntityType, EntityId, EntityKey, EntityStatus, RecalcOption, Operation, ProcedureName, BusinessUnit)
      select distinct EntityType, EntityId, EntityKey, EntityStatus, replace (RecalcOption, '$', ''), Operation, ProcedureName, coalesce(BusinessUnit, @BusinessUnit)
      from #EntitiesToRecalc
      where ((@RecalcOption = 'DeferAll' or RecalcOption like '$%')) and (Status <> 'P' /* Processed */) and
            (EntityType is not null) and
            (EntityId is not null or EntityKey is not null);

end /* pr_Entities_RequestRecalcCounts */

Go
