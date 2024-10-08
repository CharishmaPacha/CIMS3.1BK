/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/01/18  SV      pr_Pallets_Modify: V3 enhancement to peform ClearUserOnCart from Pallets page (CIMSV3-175)
  2016/12/30  MV      pr_Pallets_Modify: Not allow to clear the cart if Packing by User is empty on the Picked status cart (HPI-853)
  2016/10/12  KL      Added new procedure pr_Pallets_ClearCart.
                      pr_Pallets_Modify: Invoked pr_Pallets_ClearCart procedure (HPI-850)
  2016/06/22  KL      pr_Pallets_Modify: Added audit trail messages (NBD-593)
  2016/06/03  RV      pr_Pallets_Modify: Clear the user from cart to allow another user to pack,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_Modify') is not null
  drop Procedure pr_Pallets_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_Modify:
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_Modify
  (@PalletContents    TXML,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @Message           TMessage output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vEntity              TEntity  = 'Pallet',
          @vAction              TAction,
          @xmlData              xml,
          @vPalletsCount        TCount,
          @vPalletsUpdatedCount TCount,
          @vPalletId            TRecordId,
          @vValidStatuses       TStatus,
          @vAuditActivity       TActivityType;

  /* Temp table to hold all the Pallets to be updated */
  declare @ttPallets          TEntityKeysTable,
          @ttPalletsUpdated   TEntityKeysTable,
          @ttPalletsAuditInfo TAuditTrailInfo;

begin /* pr_Pallets_Modify */
begin try
  begin transaction;
  SET NOCOUNT ON;
  set @xmlData = convert(xml, @PalletContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return

  select @vValidStatuses = dbo.fn_Controls_GetAsString('Pallet_ClearCartUser', 'ValidStatuses', 'KGD' /* Picked, Packing, Packed */,
                                                       @BusinessUnit, @UserId)

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/ModifyPallets') as Record(Col);

  /* Load all the Pallets into the temp table which are to be updated in Pallets table */
  insert into @ttPallets (EntityId, EntityKey)
    select Record.Col.value('PalletId[1]', 'TRecordId') PalletId,
           Record.Col.value('Pallet[1]',   'TPallet')   Pallet
    from @xmlData.nodes('/ModifyPallets/Pallets') as Record(Col);

  /* Get number of rows inserted */
  select @vPalletsCount = @@rowcount;

  /* ClearUserOnCart: This action value is sent from V3 app */
  if (@vAction in ('ClearCartUser', 'ClearUserOnCart'))
    begin
      select @vAuditActivity = 'AT_ClearedUserOnCart',
             @vAction        = 'ClearCartUser';

      update P
      set PackingByUser  = null,
          ModifiedDate   = current_timestamp,
          ModifiedBy     = @UserId
      output inserted.PalletId into @ttPalletsUpdated (EntityId)
      from Pallets P
        join @ttPallets TP on (TP.EntityKey = P.Pallet) and (P.BusinessUnit = @BusinessUnit)
      where (charindex(P.Status, @vValidStatuses) > 0) and (PackingByUser is not null);

      /* Get the count of total number of Pallets Updated */
      set @vPalletsUpdatedCount = @@rowcount;

      /* If user cleared on multiple Pallets and only one audit record is created for all of
         them, then associate the Updated Pallets with the Audit record */
      insert into @ttPalletsAuditInfo (EntityType, EntityId, EntityKey, ActivityType,
                                       Comment, BusinessUnit, UserId)
        select 'Pallet', PalletId, Pallet, @vAuditActivity,
                dbo.fn_Messages_BuildDescription(@vAuditActivity, 'Pallet', Pallet /* Pallet */ , null, null , null, null , null, null, null, null, null, null) /* Comment */,
                @BusinessUnit,  @UserId
        from Pallets P join @ttPalletsUpdated TP on (TP.EntityId = P.PalletId);

      /* AT to log over the clear user on cart */
      exec pr_AuditTrail_InsertRecords  @ttPalletsAuditInfo;
    end
  else
  if (@vAction = 'ClearCart')
    begin
      exec pr_Pallets_ClearCart @ttPallets, @UserId, @BusinessUnit, @Message output;
    end

  /* Based upon the number of Pallets that have been modified, give an appropriate message */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vAction, @vPalletsUpdatedCount, @vPalletsCount;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_Modify */

Go
