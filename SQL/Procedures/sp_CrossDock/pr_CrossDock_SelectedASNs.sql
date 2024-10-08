/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/09/16  PK      pr_CrossDock_ProcessASNs, pr_CrossDock_SelectedASNs: Changes related to the change of Order Status Code.
  2012/07/31  PKS     pr_CrossDock_SelectedASNs.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CrossDock_SelectedASNs') is not null
  drop Procedure pr_CrossDock_SelectedASNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_CrossDock_SelectedASNs:
------------------------------------------------------------------------------*/
Create Procedure pr_CrossDock_SelectedASNs
  (@ReceiptOrders TXML,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @Message       TMessage output)
as
  declare @xmlData            XML,
          @vLPNsToCrossDock   TCount,
          @vASNsToCrossDock   TCount,
          @vOrdersToCrossDock TCount,
          @vLPNsCrossDocked   TCount,
          @vASNsCrossDocked   TCount,
          @vCrossDockASN      TReceiptNumber,

          @ReturnCode         TInteger,
          @MessageName        TMessageName;

  declare @ttCrossDockOrderDetails TEntityKeysTable,
          @ttCrossDockLPNs         TEntityKeysTable;

  declare @ttCrossDockASNs table
          (ReceiptId     TRecordId,
           ReceiptNumber TReceiptNumber,
           CustPO        TCustPO,
           DateExpected  TDateTime);

begin
begin try
  SET NOCOUNT ON;
  begin transaction;

  select @xmlData = convert(xml, @ReceiptOrders);

  /* Get all the ASNs are given which qualify to be cross docked */
  insert into @ttCrossDockASNs (ReceiptId, ReceiptNumber, CustPO, DateExpected)
    select RH.ReceiptId,
           RH.ReceiptNumber,
           RH.UDF1,
           RH.DateExpected
    from (select Record.Col.value('.', 'TRecordId') as ReceiptId
          from @xmlData.nodes('CrossDockASNs/ReceiptIds/ReceiptId') as Record(Col)) T
               join ReceiptHeaders RH on (T.ReceiptId = RH.ReceiptId)
    where (RH.ReceiptType  = 'A'/* ASNs */) and
          (RH.BusinessUnit = @BusinessUnit) and
          (RH.Status in ('T' /* InTransit */, 'R' /* Receiving */, 'E' /* Received */));

  select @vASNsToCrossDock = @@rowcount;

  /* select the LPNs for the ASNs we have identified to be cross docked */
  insert into @ttCrossDockLPNs(EntityId)
    select L.LPNId
    from LPNs L join @ttCrossDockASNs A on L.ReceiptId = A.ReceiptId
    where (L.Status        = 'T' /* In Transit */) and
          (L.OnhandStatus  <> 'R' /* Reserved */)
    order by A.DateExpected, L.LPN;

  select @vLPNsToCrossDock = @@rowcount;

  /* Get all lines that need to be cross docked */
  insert into @ttCrossDockOrderDetails(EntityId)
    select OD.OrderDetailId
    from OrderDetails OD join OrderHeaders OH    on (OD.OrderId = OH.OrderId)
                         join @ttCrossDockASNs A on (coalesce(A.CustPO, '') = coalesce(OH.CustPO, ''))
    where (OH.UDF4 in ('CrossDock', 'Prepack')) and
          (OD.UnitsToAllocate > 0) and
          (OH.Status in ('N' /* New */, 'W' /* Batched */, 'C' /* Picking */ )) and
          (OH.Archived = 'N' /* No */) and
          (OD.BusinessUnit = @BusinessUnit)
    order by Priority, CancelDate, DesiredShipdate;

  select @vOrdersToCrossDock = @@rowcount;

  if (@vASNsToCrossDock = 0)
    set @MessageName = 'NoASNsToCrossDock'
  else
  if (@vLPNsToCrossDock = 0)
    set @MessageName = 'NoLPNsToCrossDock'
  else
  if (@vOrdersToCrossDock = 0)
    set @MessageName = 'NoOrdersToCrossDock'

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Call Procedure to match the LPNs with the OrderDetails */
  exec pr_CrossDock_ASNLPNs @ttCrossDockLPNs, @ttCrossDockOrderDetails,
                            @BusinessUnit, @UserId,
                            @vLPNsCrossDocked output;

  select @vASNsCrossDocked = count(*),
         @vCrossDockASN    = Min(ReceiptNumber)
  from @ttCrossDockASNs;

  if (@vASNsCrossDocked = 1)
    set @Message = 'CrossDockSingleASN';
  else
    set @Message = 'CrossDockMultipleASNs';

  exec @Message = dbo.fn_Messages_Build @Message, @vCrossDockASN, @vASNsCrossDocked, @vLPNsCrossDocked;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  rollback transaction;
  exec @ReturnCode = pr_ReRaiseError;
end catch;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_CrossDock_SelectedASNs */

Go
