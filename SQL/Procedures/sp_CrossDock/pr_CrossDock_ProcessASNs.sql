/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/09/16  PK      pr_CrossDock_ProcessASNs, pr_CrossDock_SelectedASNs: Changes related to the change of Order Status Code.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CrossDock_ProcessASNs') is not null
  drop Procedure pr_CrossDock_ProcessASNs;
Go
/*------------------------------------------------------------------------------
  Procedure pr_CrossDock_ProcessASNs : This is typically used for an automated
    process where a job runs constantly to see if there are any LPNs that are
    coming in that can be cross docked against Outstanding Orders.
------------------------------------------------------------------------------*/
Create Procedure pr_CrossDock_ProcessASNs
  (@BusinessUnit      TBusinessUnit,
   @UserId            TUserId)
as
declare @vReturnCode       TInteger,
        @vMessageName      TMessageName,

        @vCrossDockedLPNs  TCount,
        @vOrderLineCount   TCount,

        @ttCrossDockLPNs   TEntityKeysTable,
        @ttCrossDockOrders TEntityKeysTable;
begin
begin try
  SET NOCOUNT ON;
  begin transaction;

  /* Get all lines that need to be cross docked */
  insert into @ttCrossDockOrders(EntityId, EntityKey)
    select OD.OrderDetailId, OD.OrderId
    from OrderDetails OD join OrderHeaders OH on (OD.OrderId = OH.OrderId)
    where (OH.UDF4 = 'CrossDock') and
          (OD.UnitsToAllocate > 0) and
          (OH.Status in ('N' /* New */, 'W' /* Batched */, 'C' /* Picking */ )) and
          (OH.Archived = 'N' /* No */) and
          (OD.BusinessUnit = @BusinessUnit)
    order by Priority, CancelDate, DesiredShipdate;

  set @vOrderLineCount = @@rowcount;

  /* 2. select the LPNs, SKUs and its Qty from LPNDetails which has the ASN ReceiptIds. */
  insert into @ttCrossDockLPNs(EntityId, EntityKey)
    select L.LPNId, L.LPN
    from LPNDetails LD join ReceiptHeaders RH on (LD.ReceiptId = RH.ReceiptId)
                       join LPNs L on (LD.LPNId = L.LPNId)
    where (RH.ReceiptType = 'A'/* ASNs */) and
          (RH.BusinessUnit = @BusinessUnit) and
          (RH.Status in ('T' /* InTransit */, 'R' /* Receiving */, 'E' /* Received */)) and
          (L.Status = 'T' /* In Transit */) and
          (L.OnhandStatus <> 'R' /* Reserved */)
    order by RH.DateExpected, L.LPN;

  /* If there are no LPNs returned then stop starting the loop and raise error */
  if (@@rowcount = 0)
    set @vMessageName = 'NoLPNsToCrossDock';
  else
  if (@vOrderLineCount = 0)
    set @vMessageName = 'NoOrdersToCrossDock';

  if (@vMessageName is not null)
    goto ErrorHandler;

  exec pr_CrossDock_ASNLPNs @ttCrossDockLPNs, @ttCrossDockOrders,
                            @BusinessUnit, @UserId, @vCrossDockedLPNs output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  rollback transaction;
  exec @vReturnCode = pr_ReRaiseError;
end catch;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_CrossDock_ProcessASNs */

Go
