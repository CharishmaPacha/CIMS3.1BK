/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/08  TK      pr_Loads_Action_Cancel, pr_Load_RemoveOrders
                        Several corrections to use temp table instead of #ttSelectedEntities to resolve load close issue
                      pr_Load_MarkAsShipped: Changes to pr_Load_RemoveOrders proc signature (HA-1520)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_Cancel') is not null
  drop Procedure pr_Loads_Action_Cancel;
Go
/*------------------------------------------------------------------------------
  pr_Loads_Action_Cancel: This procedure will cancel the Load(s).
          This proc will internally calls the pr_Load_RemoveOrders.

          '<Loads xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <LoadDetails>
           <LoadNumber>19</LoadNumber>
           </LoadDetails>
          </Loads>'
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_Cancel
  (@xmlData         xml,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @ResultXML       TXML = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TMessageName,
          /* Loads Related*/
          @vLoadNumber        TLoadNumber,
          @vLoadId            TLoadId,
          @vRecordId          TRecordId,
          @vTotalLoads        TCount,
          @vLoadsCanceled     TCount,
          /* Other Info..*/
          @ttOrders           TEntityValuesTable,
          @ttLoads            TEntityKeysTable;

begin /* pr_Loads_Action_Cancel */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vMessage       = null,
         @vRecordId      = 0,
         @vTotalLoads    = 0,
         @vLoadsCanceled = 0;

  if (object_id('tempdb..#ttSelectedEntities') is null)
    select * into #ttSelectedEntities from @ttOrders;

  if (not exists (select * from #ttSelectedEntities))
    insert into #ttSelectedEntities (EntityKey, RecordId)
      select Record.Col.value('LoadNumber[1]',  'TLoadNumber'),
             row_number() over (order by (select 1))
      from @xmlData.nodes('Loads/LoadDetails') as Record(Col)

  if (@BusinessUnit is null)
    set @vMessageName = 'InvalidBusinessUnit';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get the total no. of Loads that user requested be canceled. */
  select @vTotalLoads = count(*) from #ttSelectedEntities;

  /* Delete the Invaild loads from #ttSelectedEntities */
  delete ttSE
  output 'E', 'Load_CancelLoad_InvalidStatus', Deleted.EntityKey
  into #ResultMessages (MessageType, MessageName, Value1)
  from Loads L join #ttSelectedEntities ttSE on (L.LoadId = ttSE.EntityId)
  where (Status not in ('N' /* New */, 'I' /* In progress */, 'R' /* Ready To Load */, 'L' /* Ready To Ship */)) and
        (RoutingStatus not in ('P' /* Pending */, 'N' /* NotRequired */));

  /* Iterate thru the each Loads and remove each one to the Load */
  while (exists (select * from #ttSelectedEntities where RecordId > @vRecordId))
    begin
      select top 1 @vLoadNumber  = ttSE.EntityKey,
                   @vLoadId      = ttSE.EntityId,
                   @vRecordId    = ttSE.RecordId
      from #ttSelectedEntities ttSE
      where (ttSE.RecordId > @vRecordId)
      order by RecordId;

      if (@vLoadId is null) continue;

      /* Initialize */
      delete from @ttOrders;

      /* Load Orders into tabvar to process */
      insert into @ttOrders(EntityType, EntityId, RecordId)
        select 'PickTicket', OrderId, row_number() over (order by (select 1))
        from vwLoadOrders
        where (LoadId = @vLoadId);

      /* All the orders on Load shall be removed and the Load is canceled */
      exec @vReturnCode = pr_Load_RemoveOrders @vLoadNumber, @ttOrders, 'Y' /* Cancel Load*/, 'Load_Cancel', @BusinessUnit, @UserId;

      /* If ther is no error then we need to count it as canceled. */
      if (@vReturnCode = 0)
        begin
          set @vLoadsCanceled += 1;

          exec pr_AuditTrail_Insert 'LoadCancelled', @UserId, null /* ActivityDateTime - if null takes the Current TimeStamp */,
                                    @LoadId        = @vLoadId;
        end
     end

  /* Based upon the number of Loads that have been Canceled, give an appropriate message */
  exec pr_Messages_BuildActionResponse 'Load', 'CancelLoad', @vLoadsCanceled, @vTotalLoads;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_Cancel */

Go
