/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/05  VS      pr_OrderHeaders_VoidTempLabels: Void the Shiplabels if we have against the Order (CIMSV3-1361)
  2021/02/04  VS      pr_OrderHeaders_VoidTempLabels, pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_OnChangeShipDetails,
  2020/08/18  OK      pr_OrderHeaders_VoidTempLabels: Added to void the temp labels and Shiplabels even order dont has TaskDetails
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_VoidTempLabels') is not null
  drop Procedure pr_OrderHeaders_VoidTempLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_VoidTempLabels: We have shipping labels being generated ahead
   of the inventory being picked, so there will be situations (like Unwaving of an Order)
   when the generated LPNs, shipping labels have to be voided and this procedure
   achieves that.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_VoidTempLabels
  (@Orders           TEntityKeysTable READONLY,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessage           TMessage,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vActivityType      TActivityType,
          @vAuditRecordId     TRecordId;

  declare @ttLPNsUpdated      TEntityKeysTable,
          @ttAuditTrailInfo   TAuditTrailInfo;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vActivityType = 'AT_'+ @Operation + '_VoidTempLabel';

  /* Update LPNs status and OnHandStatus */
  update L
  set Status       = case when LPNType = 'A' then 'N' else 'V'  /* Void */ end,
      OnhandStatus = 'U'  /* Unavailable */,
      OrderId      = null,
      PickTicketNo = null,
      SalesOrder   = null,
      ShipmentId   = null,
      LoadId       = null,
      LoadNumber   = null,
      PickBatchId  = null,
      PickBatchNo  = null,
      BoL          = null,
      ModifiedDate = current_timestamp,
      ModifiedBy   = coalesce(@UserId, System_User)
  output Deleted.LPNId, Deleted.LPN into @ttLPNsUpdated(EntityId, EntityKey)
  from LPNs L
    join @Orders ttO on (ttO.EntityId = L.OrderId)
  where (L.Status = 'F' /* New Temp */);

  /* Update LPNDetails OnhandStatus as Unavailable, OrderId and OrderDetailId as null */
  update LD
  set OnhandStatus  = 'U'  /* Unavailable */,
      OrderId       = null,
      OrderDetailId = null
  from LPNDetails LD
    join @ttLPNsUpdated ttLU on (ttLU.EntityId = LD.LPNId);

  /* Void labels if exists */
  if exists (select * from @ttLPNsUpdated)
    begin
      exec pr_Shipping_VoidShipLabels null, null /* LPNId */, @ttLPNsUpdated, @BusinessUnit,
                                      default /* RegenerateLabel - No */, @vMessage output;
    end

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select distinct 'LPN', EntityId, EntityKey, @vActivityType, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vActivityType, OH.PickTicket, OH.PickBatchNo, null, null, null) /* Comment */
    from @Orders ttO
      join OrderHeaders OH on (OH.OrderId = tto.EntityId);

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_VoidTempLabels */

Go
