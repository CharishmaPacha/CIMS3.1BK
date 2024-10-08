/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/28  TK      pr_Allocation_GetAllocableLPNs, pr_Allocation_GetAllocationRules, pr_Allocation_PrepareAllocableLPNs &
                        pr_Allocation_GetOrderDetailsToAllocate & pr_Allocation_PrepareToAllocateInventory: Initial Revision
                      pr_Allocation_AllocateInventory: Code revamp - WIP Changes (HA-86)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_PrepareToAllocateInventory') is not null
  drop Procedure pr_Allocation_PrepareToAllocateInventory;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_PrepareToAllocateInventory: This procedure adds required constraints or
    computed columns to the hash tables
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_PrepareToAllocateInventory
  (@WaveId             TRecordId,
   @Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName;
begin /* pr_Allocation_PrepareToAllocateInventory */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Wave Info */

  /* while creating hash tables constraints won't be created so drop the columns for which constraints
     are required and re create them */

  /* For ##AllocableLPNs */
  alter table #AllocableLPNs drop column KeyValue;
  alter table #AllocableLPNs add KeyValue                as cast(SKUId as varchar) + '-' + Ownership + '-' + Warehouse + '-' +
                                                            coalesce(Lot, '') + '-' + coalesce(InventoryClass1, '')

  /* For #OrderDetailsToAllocate */
  alter table #OrderDetailsToAllocate drop column KeyValue;
  alter table #OrderDetailsToAllocate add KeyValue       as cast(SKUId as varchar) + '-' + Ownership + '-' + Warehouse + '-' +
                                                            coalesce(Lot, '') + '-' + coalesce(InventoryClass1, '')

  /* For #SKUOrderDetailsToAllocate */
  alter table #SKUOrderDetailsToAllocate drop column KeyValue;
  alter table #SKUOrderDetailsToAllocate add KeyValue    as cast(SKUId as varchar) + '-' + Ownership + '-' + Warehouse + '-' +
                                                            coalesce(Lot, '') + '-' + coalesce(InventoryClass1, '')

  /* For #TaskInfo */
  alter table #TaskInfo drop column IsLabelGenerated, IsTaskAllocated;
  alter table #TaskInfo add IsLabelGenerated      varchar(10)  not null DEFAULT 'N' /* No */,
                            IsTaskAllocated       varchar(10)  not null DEFAULT 'N' /* No */
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_PrepareToAllocateInventory */

Go
