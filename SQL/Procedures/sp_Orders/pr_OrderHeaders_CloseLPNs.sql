/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_CloseLPNs') is not null
  drop Procedure pr_OrderHeaders_CloseLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_CloseLPNs:
  Action = Consume or Ship
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_CloseLPNs
  (@OrderId           TRecordId,
   @Action            TAction,
   @ValidLPNStatuses  TFlags,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @vRecordId      TRecordId;

  declare @vExportLPNs    TFlags,
          @vLPNQuantity   TQuantity,
          @vLPNId         TRecordId,
          @vLPN           TLPN,
          @ttLPNs         TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* load all the LPNs into temp table */
  insert into @ttLPNs(EntityId, EntityKey)
    select LPNId, LPN
    from LPNs
    where (OrderId = @OrderId) and
          ((@ValidLPNStatuses is null) or (charindex(Status, @ValidLPNStatuses) > 0)) and
          (Status not in ('V' /* Voided */, 'S' /* Shipped */)) and
          (LPNType <> 'TO') /* Tote */;

  /* Get the control value to determine if we want to export LPNs or not */
  select @vExportLPNs = dbo.fn_Controls_GetAsString('Ship', 'ExportLPNs', 'Y' /* Yes */, @BusinessUnit, @UserId);

  while (exists (select * from @ttLPNs where RecordId > @vRecordId))
    begin
      select top 1 @vLPNId       = EntityId,
                   @vLPN         = EntityKey,
                   @vLPNQuantity = Quantity,
                   @vRecordId    = RecordId
      from @ttLPNs TL join LPNs L on TL.EntityId = L.LPNId
      where RecordId > @vRecordId
      order by RecordId;

      if (@Action = 'Consume')
        begin
          exec pr_LPNs_SetStatus @vLPNId, 'C' /* Consumed */;

          /* Export the LPN to notify that we have not less inventory */
          exec @vReturnCode = pr_Exports_LPNData 'Xfer' /* Transfer */,
                                                 @LPNId        = @vLPNId,
                                                 @TransQty     = @vLPNQuantity,
                                                 @BusinessUnit = @BusinessUnit,
                                                 @CreatedBy    = @UserId;
        end
      else
      if (@Action = 'Ship')
        begin
          /* call procedure here to ship the LPN */
          exec pr_LPNs_Ship @vLPNId, @vLPN, @BusinessUnit, @UserId, @vExportLPNs /* Generate Exports */;
        end
    end /* End of while loop */

  if (@vReturnCode > 0)
    goto ExitHandler;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_CloseLPNs */

Go
