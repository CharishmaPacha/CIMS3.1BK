/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/02  VS      pr_API_UPS_AddShipmentRequest: If we get @EntityId then only need to insert into @ttEntitiesToCreateShipment table (HA-3134)
  2021/08/09  OK      pr_API_UPS_AddShipmentRequest: Bugfix to get the distinct order information when order has multiple shipments (BK-478)
  2021/07/28  OK      pr_API_UPS_AddShipmentRequest: Changes to update the WaveNo (BK-445)
                      pr_API_UPS_AddShipmentRequest: Bug fixed to do not insert the record with null (BK-379)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_AddShipmentRequest') is not null
  drop Procedure pr_API_UPS_AddShipmentRequest;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_AddShipmentRequest:
    Generates API outbound transaction to create UPS shipments. This procedure using
    #ShipLabelsToInsert to get the different PTs and add API outbound transactions.
    Also we are always generating the shipment with respect to the PickTicket

  #ShipLabelsToInsert - TShipLabels
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_AddShipmentRequest
  (@InputXML     TXML,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vOperation              TOperation,

          @vEntityId               TRecordId,
          @vEntityType             TEntity,
          @vEntityKey              TEntityKey,

          @vWaveId                 TRecordId,
          @vWaveNo                 TWaveNo,
          @vWavePickMethod         TPickMethod,

          @vInputXML               XML,

          @vBusinessUnit           TBusinessUnit,
          @vUserId                 TUserId;

declare @ttEntitiesToCreateShipment TEntityValuesTable;
begin /* pr_API_UPS_AddShipmentRequest */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vInputXML    = cast(@InputXML as xml);

  select @vEntityType   = Record.Col.value('(EntityType)[1]',   'TEntity'),
         @vEntityId     = Record.Col.value('(EntityId)[1]',     'TRecordId'),
         @vEntityKey    = Record.Col.value('(EntityKey)[1]',    'TEntityKey')
  from @vInputXML.nodes('/Root') Record(Col)
  OPTION (OPTIMIZE FOR ( @vInputXML = null ));

  if (object_id('tempdb..#ShipLabelsToInsert') is not null)
    begin
      /* For UPS we are creating shipment with multiple package for the Order. If we have already
         a valid tracking no for any LPN then exclude those LPNs when getting shipment data */
      insert into @ttEntitiesToCreateShipment(EntityId, EntityKey, UDF1, RecordId)
        select distinct OrderId, PickTicket, WaveNo, dense_rank() over (order by OrderId)
        from #ShipLabelsToInsert
        where (InsertRequired   = 'Y' /* Yes */) and
              (CarrierInterface = 'CIMSUPS');

      /* Do not insert if the record already exist, which is not yet processed */
      delete @ttEntitiesToCreateShipment
      from @ttEntitiesToCreateShipment ETC
        join APIOutboundTransactions AOT on (AOT.EntityId = ETC.EntityId) and (AOT.EntityType = 'Order') and (AOT.TransactionStatus = 'Initial');

      select @vEntityType = 'Order'
    end

  /* If no data is available in temp table trying fetch from Input */
  if (@vEntityId is not null) and
     (not exists(select * from @ttEntitiesToCreateShipment))
    insert into @ttEntitiesToCreateShipment(EntityId, EntityKey, RecordId)
      select @vEntityId, @vEntityKey, 1;

  if not exists(select * from @ttEntitiesToCreateShipment)
    return;

  /* Generate outbound ShipmentRequest transaction */
  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityType, EntityId, EntityKey, Reference1, BusinessUnit, CreatedBy)
    select 'CIMSUPS', 'ShipmentRequest', @vEntityType, EntityId, EntityKey, UDF1, @BusinessUnit, @UserId
    from @ttEntitiesToCreateShipment

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_AddShipmentRequest */

Go
