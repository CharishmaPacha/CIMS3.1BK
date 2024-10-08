/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/10  TK      pr_Entities_ExecuteInBackground: Changes to identify Pallet entity
  2018/07/25  AY      pr_Entities_ExecuteProcess, pr_Entities_ExecuteInBackground: New procedures for
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entities_ExecuteInBackground') is not null
  drop Procedure pr_Entities_ExecuteInBackGround ;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entities_ExecuteInBackGround:
    It inserts the given entities into BackgroundProcesses table,
    to defer execution of a particular process
------------------------------------------------------------------------------*/
Create Procedure pr_Entities_ExecuteInBackground
  (@Entity            TEntity,
   @EntityId          TRecordId     = null,
   @EntityKey         TEntityKey    = null,
   @ProcessClass      TClass        = 'Process',
   @ProcId            TInteger      = 0,
   @Operation         TOperation    = null,
   @BusinessUnit      TBusinessUnit = null,
   @EntityKeysTable   TRecountKeysTable READONLY,
   @ExecProcedureName TName         = null,
   @InputParams       TXML          = null)
as
  declare @ttRecountKeysTable    TRecountKeysTable;
begin /* pr_Entities_ExecuteInBackGround */
  SET NOCOUNT ON;

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
      /* If Entity is Load then get Load Info */
      if (@Entity = 'Load')
        select @EntityKey    = LoadNumber,
               @BusinessUnit = BusinessUnit
        from Loads
        where (LoadId = @EntityId);
      else
      /* If Entity is LPN then get LPN Info */
      if (@Entity = 'LPN')
        select @EntityKey    = LPN,
               @BusinessUnit = BusinessUnit
        from LPNs
        where (LPNId = @EntityId);
      else
      /* If Entity is Pallet then get Pallet Info */
      if (@Entity = 'Pallet')
        select @EntityKey    = Pallet,
               @BusinessUnit = BusinessUnit
        from Pallets
        where (Pallet = @EntityId);
      else
      /* If Entity is ReceiptHder then get Receipt Info */
      if (@Entity = 'ReceiptHdr') and ((@EntityKey is null) or (@BusinessUnit is null))
        select @EntityKey    = ReceiptNumber,
               @BusinessUnit = BusinessUnit
        from ReceiptHeaders
        where (ReceiptId = @EntityId);

      /* If Entity is Receiver then we are passing both EntityId and EntityKey, so nothing to retrieve */
    end

  /* If user passed in EntityId and EntityKey then insert them and exit for better performance - no need to use temp table */
  if (@EntityId is not null) and (@EntityKey is not null)
    begin
      insert into BackgroundProcesses(EntityType, EntityId, EntityKey, ProcessClass, Operation, RequestedBy,
                                      ExecProcedureName, InputParams, BusinessUnit)
        select @Entity, @EntityId, @EntityKey, @ProcessClass, @Operation, Object_Name(@ProcId),
               @ExecProcedureName, @InputParams, @BusinessUnit

      return;
    end

  /* insert entites to BackgroundProcesses */
  insert into BackgroundProcesses(EntityType, EntityId, EntityKey, ProcessClass, Operation, RequestedBy,
                                  ExecProcedureName, InputParams, BusinessUnit)
    select @Entity, EntityId, EntityKey, @ProcessClass, @Operation, Object_Name(@ProcId),
           @ExecProcedureName, @InputParams, @BusinessUnit
    from @EntityKeysTable;

end /* pr_Entities_ExecuteInBackGround */

Go
