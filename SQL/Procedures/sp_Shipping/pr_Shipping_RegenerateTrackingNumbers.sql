/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/02  RV      pr_Shipping_SaveLPNData & pr_Shipping_RegenerateTrackingNumbers: Made changes to insert EntityId on ShipLabels (BK-460)
  2020/02/24  YJ      pr_Shipping_GetShipmentData, pr_Shipping_RegenerateTrackingNumbers,
                      pr_Shipping_SaveLPNData, pr_Shipping_SaveShipmentData, pr_Shipping_ValidateToShip,
                      pr_Shipping_VoidShipLabels: Changes to update PickTicket, WaveNo, WaveId on ShipLabels (CID-1335)
  2018/05/05  AJ/TK   Added pr_Shipping_RegenerateTrackingNumbers (S2G-549)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_RegenerateTrackingNumbers') is not null
  drop Procedure pr_Shipping_RegenerateTrackingNumbers;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_RegenerateTrackingNumbers: We may have errors in generating
    tracking numbers (wrong address, zip code etc.). We need ability to re-generate
    the tracking number after the issue is resolved and this procedures sets up for
    all LPNs of given Order or the list of LPNs passed in.

  If the LPN already has if The Lhis procedure updates ShipLabels table
  If there is shiplabel entry exists with valid tracking number and Status = 'A'
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_RegenerateTrackingNumbers
  (@OrderId        TRecordId,
   @LPNId          TRecordId,
   @LPNs           TEntityKeysTable ReadOnly,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @Message        TMessage         output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vTotalRecords       TCount,
          @vProcessedLPNCount  TCount,

          @vValidStatuses      TControlValue,
          @vAuditRecordId      TRecordId;
  declare @ttLPNs              TEntityKeysTable,
          @ttAuditLPNs         TEntityKeysTable;
  declare @ttUpdatedEntities   table (EntityKey     TEntityKey,
                                      BusinessUnit  TBusinessUnit);
begin
  select @vReturnCode        = 0,
         @vMessageName       = null,
         @vTotalRecords      = 0,
         @vProcessedLPNCount = 0;

  /* We only would want to re-generate tracking no if the LPN is of valid status - there by
     preventing insertion of Putaway LPNs etc into Shiplables table even if user has chosen them */
  select @vValidStatuses = dbo.fn_Controls_GetAsString('Shipping', 'RegenerateTrackingNo', 'AFUKGDEL'/* Allocate, NewTemp, Picking, Picked, Packed, Staged, Loaded */,
                                                       @BusinessUnit, @UserId);

  /* get the LPNs into temp table if the user has given the LPNId */
  if exists (select * from @LPNs)
    insert into @ttLPNs (EntityId, EntityKey)
      select EntityId, EntityKey
      from @LPNs;
  else
  if (@OrderId is not null)
    insert into @ttLPNs (EntityId, EntityKey)
      select LPNId, LPN
      from LPNs
      where (OrderId = @OrderId);
  else
    insert into @ttLPNs (EntityId, EntityKey)
      select LPNId, LPN
      from LPNs
      where (LPNId = @LPNId);

  set @vTotalRecords = @@rowcount;

  /* Delete LPNs with Invalid Statuses */
  delete ttL
  from @ttLPNs ttL join LPNs L on (ttL.EntityId = L.LPNId)
  where (charindex(L.Status, @vValidStatuses) = 0);

  /* Delete LPNs with Invalid LPN Types */
  delete ttL
  from @ttLPNs ttL join LPNs L on (ttL.EntityId = L.LPNId)
  where (L.LPNType in ('A', 'L'/* Cart, Logical */));

  /* If there is a valid label already generated, then don't generate another one */
  delete ttL
  from @ttLPNs ttL join ShipLabels S on (ttL.EntityKey = S.EntityKey) and
                                        (S.BusinessUnit = @BusinessUnit) and
                                        (S.Status = 'A') and
                                        (S.ProcessStatus not in ('LGE'));

  /* Reset Process Status if entry exists in ShipLabels table with an error.
     If the prior label was voided, then we shouldn't update it, we would create a new entry */
  update SL
  set ProcessStatus = 'N' /* No */
  output Inserted.EntityKey, Inserted.BusinessUnit into @ttUpdatedEntities(EntityKey, BusinessUnit)
  from ShipLabels SL
    join @ttLPNs ttL on (SL.EntityKey     = ttL.EntityKey) and
                        (SL.BusinessUnit  = @BusinessUnit) and
                        (SL.ProcessStatus in ('LGE'))      and
                        (SL.Status        = 'A' /* Active */);

  /* Insert required labels into ShipLabels table if they were not updated above */
  insert into ShipLabels (EntityType, EntityId, EntityKey, OrderId, PickTicket, WaveId, WaveNo, LabelType, TrackingNo,
                          RequestedShipVia, ShipVia, Carrier, BusinessUnit, CreatedBy)
    output Inserted.EntityKey, Inserted.BusinessUnit into @ttUpdatedEntities(EntityKey, BusinessUnit)
    select distinct 'L' /* LPN */, L.LPNId, L.LPN, OH.OrderId, OH.PickTicket, OH.PickBatchId, OH.PickBatchNo, 'S' /* Ship Label */, '', /* TrackingNo does not allow null */
                    OH.ShipVia, OH.ShipVia, coalesce(S.Carrier, ''), @BusinessUnit, @UserId
    from @ttLPNs ttL
      left outer join @ttUpdatedEntities ttUE on (ttL.EntityKey     = ttUE.EntityKey) and
                                                 (ttUE.BusinessUnit = @BusinessUnit)
      join LPNs         L  on (ttL.EntityId = L.LPNId)
      join OrderHeaders OH on (L.OrderId    = OH.OrderId)
      join ShipVias     S  on (OH.ShipVia   = S.ShipVia) and
                              (OH.BusinessUnit = S.BusinessUnit) and
                              (S.Carrier in ('UPS', 'FEDEX', 'USPS'))
    where (ttUE.EntityKey is null);

  /* Get all the updated or inserted records to log AT */
  insert into @ttAuditLPNs (EntityId, EntityKey)
    select LPNId, LPN
    from LPNs L
      join @ttUpdatedEntities ttUE on (L.LPN          = ttUE.EntityKey) and
                                      (L.BusinessUnit = ttUE.BusinessUnit);

  set @vProcessedLPNCount = @@rowcount;

  exec @Message = dbo.fn_Messages_BuildActionResponse 'LPNs', 'RegenerateTrackingNo', @vProcessedLPNCount, @vTotalRecords;

  /* Insert Audit Trail */
  exec pr_AuditTrail_Insert 'RegenerateTrackingNo', @UserId, null /* ActivityTimestamp */,
                             @BusinessUnit = @BusinessUnit,
                             @AuditRecordId = @vAuditRecordId output;

  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttAuditLPNs, @BusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_RegenerateTrackingNumbers */

Go
