/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/23  OK      pr_Loads_Action_MarkAsShipped: Changes to update the modified date time when load is marked as Shipping InProgress (HA-2379)
  2021/02/01  TK      pr_Loads_Action_MarkAsShipped: Changes to defer load shipping to background (HA-1955)
                      pr_Loads_Action_MarkAsShipped: Revamped the procedure (CIMSV3-977)
  2020/07/02  AY      pr_Loads_Action_MarkAsShipped: New (CIMSV3-977)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_MarkAsShipped') is not null
  drop Procedure pr_Loads_Action_MarkAsShipped;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_MarkAsShipped: Attempts to mark each load in #ttSelectedEntitites
   as shipped
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_MarkAsShipped
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vRecordId                  TRecordId,
          @vAuditActivity             TActivityType,
          @ttAuditTrailInfo           TAuditTrailInfo,

          @vEntity                    TEntity,
          @vAction                    TAction,
          @vLoadId                    TRecordId,
          @vLoadNumber                TLoadNumber,
          @vRecordsUpdated            TCount,
          @vTotalRecords              TCount;

  declare @ttValidations              TValidations,
          @ttLoadsToShip              TRecountKeysTable;
begin /* pr_Loads_Action_MarkAsShipped */
  SET NOCOUNT ON;

  select @vReturnCode      = 0,
         @vMessageName     = null,
         @vRecordId        = 0,
         @vRecordsUpdated  = 0,
         @vAuditActivity   = '';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Get the total count of records */
  select @vTotalRecords = count(*) from #ttSelectedEntities

  /* Create #Validations if it doesn't exist */
  if object_id('tempdb..#Validations') is null
    select * into #Validations from @ttValidations;

  /* Basic validations of input data or entity info */

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Iterating to mark all loads as shipped */
  while exists(select * from #ttSelectedEntities where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId   = SE.RecordId,
                   @vLoadId     = SE.EntityId,
                   @vLoadNumber = SE.EntityKey
      from #ttSelectedEntities SE
      where (RecordId > @vRecordId)
      order by RecordId;

      begin try
        delete from #Validations; -- Clear

        /* Validate whether Load can be shipped */
        exec @vReturnCode = pr_Load_ValidateToShip @vLoadId;

        /* If there is an exception, it would go to the catch block, if there are validations
           that failed, then those should have been already inserted into #ResultMessages */
        if (not exists (select * from #Validations))
          begin
            /* If there is no exception then insert load info into temp table to defer shipping */
            insert into @ttLoadsToShip (EntityId, EntityKey) select @vLoadId, @vLoadNumber;

            /* Update Loads Status to Shipping In-Progress */
            update Loads
            set Status       = 'SI' /* Shipping In-progress */,
                ModifiedDate = current_timestamp
            where (LoadId = @vLoadId);

            /* Give information that Load is queued for shipping */
            insert into #ResultMessages (MessageType, MessageName, Value1)
              select 'I', 'LoadShip_Queued', @vLoadNumber

            select @vRecordsUpdated = @vRecordsUpdated + 1;
          end

      end try
      begin catch
        /* Log the error */
        insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
          select 'E', 'LoadShip_ErrorProcessing', @vLoadNumber, ERROR_MESSAGE();
      end catch
    end

  /* Invoke procedure to defer Load shipping */
  exec pr_Entities_ExecuteInBackGround 'Load', null, null, 'CLS'/* ProcessCode - Confirm Load as Shipped */,
                                       @@ProcId, 'ConfirmLoadAsShipped'/* Operation */, @BusinessUnit, @ttLoadsToShip;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_MarkAsShipped */

Go
