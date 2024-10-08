/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/18  VS      pr_Allocation_UnwaveDisQualifiedOrders: Pass the operation to remove the DisQualifiedOrders (BK-475)
  2018/03/30  TK      pr_Allocation_AllocateWave: Added step to Unwave disqualified orders
                      pr_Allocation_UnwaveDisQualifiedOrders: Initial Revision (S2G-530)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_UnwaveDisQualifiedOrders') is not null
  drop Procedure pr_Allocation_UnwaveDisQualifiedOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_UnwaveDisQualifiedOrders: This procedure evaluates whether
   the orders on the wave are qualified to ship or not, and removes the orders
   from waves which are not qualified
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_UnwaveDisQualifiedOrders
  (@WaveId                TRecordId,
   @Operation             TOperation = null,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessage;
  declare @ttOrdersToUnwave  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Invoke proc to get all dis qualified orders */
  insert into @ttOrdersToUnwave(EntityId, EntityKey)
    exec pr_OrderHeaders_DisQualifiedOrders default, null/* OrderId */, @WaveId, @Operation, @BusinessUnit, @UserId;

  /* Unwave all the orders = */
  exec pr_OrderHeaders_UnWaveOrders @ttOrdersToUnwave, @UserId, @BusinessUnit, @Operation;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_UnwaveDisQualifiedOrders */

Go
