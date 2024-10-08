/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/03  VM      pr_LPNs_CreateLPNs, pr_LPNs_CreateLPNs_MaxKitsToCreate: Generalized (FBV3-346)
                      pr_LPNs_CreateLPNs_CreateKits, pr_LPNs_CreateLPNs_MaxKitsToCreate, pr_LPNs_Locate:
                      pr_LPNs_CreateLPNs_MaxKitsToCreate: Validate if SKU does exists in the location, Changes to validate and create Kits to process
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_CreateLPNs_MaxKitsToCreate') is not null
  drop Procedure  pr_LPNs_CreateLPNs_MaxKitsToCreate;
Go
/*------------------------------------------------------------------------------
  Proc  pr_LPNs_CreateLPNs_MaxKitsToCreate: Evaluates the component inventory
    that is available to be consumed and the kits that are being created to
    to determine the maximum kits that can be created with the available
    component inventory.

 #InventoryToConsume: TLPNDetails
 #KitComponentsInfo: TOrderDetails
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_CreateLPNs_MaxKitsToCreate
  (@BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @MaxKitsToCreate   TCount = 0 output)
as
  /* Declare local variables */
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;

begin
  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @MaxKitsToCreate = 0;

  if not exists (select * from #InventoryToConsume) or
     not exists (select * from #KitComponentsInfo)
    return;

  /* Evaluate and update how many Kits can possibly be created from qty that has been picked
     for each component SKU */
  ;with PickedQuantites(OrderDetailId, AvailToConsumeQty) as
  (
    select OrderDetailId, sum(Quantity)
    from #InventoryToConsume
    group by OrderDetailId
  )
  update KCI
  set KCI.KitsPossible  = PQ.AvailToConsumeQty / KCI.UnitsPerCarton
  from #KitComponentsInfo KCI
    join PickedQuantites PQ on (KCI.OrderDetailId = PQ.OrderDetailId);

  /* Evaluate and update how many Kits can be created */
  ;with KitsToCreate(OrderId, ParentHostLineNo, KitsToCreate) as
  (
    select OrderId, ParentHostLineNo, min(coalesce(KitsPossible, 0))
    from #KitComponentsInfo
    group by OrderId, ParentHostLineNo
  )
  update ttKCI
  set ttKCI.KitsToCreate = KTC.KitsToCreate
  from #KitComponentsInfo ttKCI
    join KitsToCreate KTC on (ttKCI.OrderId = KTC.OrderId) and
                             (ttKCI.ParentHostLineNo = KTC.ParentHostLineNo);

  /* MaxKitsToCreate is the min no of Kits can be created from picked inventory */
  select @MaxKitsToCreate = min(KitsToCreate)
  from #KitComponentsInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));

end /* pr_LPNs_CreateLPNs_MaxKitsToCreate */

Go
