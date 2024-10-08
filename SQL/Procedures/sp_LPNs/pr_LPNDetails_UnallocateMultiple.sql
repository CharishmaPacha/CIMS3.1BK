/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/31  TK      pr_LPNDetails_UnallocateMultiple & pr_LPNs_Void: Minor fixes noticed during dev testing (HA-1947)
  2020/09/30  TK      pr_LPNDetails_UnallocateMultiple: Recount Pallet to clear order info when all LPNs on pallet is allocated to a same order (HPI-2951)
  2018/12/02  AY      pr_LPNDetails_UnallocateMultiple: Change to reflect new ActivityLog_AddMessage (FB-1226)
              AY      pr_LPNDetails_UnallocateMultiple: Process all LPN Details when only LPNId is given
  2015/10/13  OK      pr_LPNDetails_UnallocateMultiple: Added the procedure to Unallocate multiple LPNs (FB-412)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_UnallocateMultiple') is not null
  drop Procedure pr_LPNDetails_UnallocateMultiple;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_UnallocateMultiple: This procedure unallocate multiple LPN Details
    in a loop. If there is an error with one of the records, then it rolls back the
    updates for that record only. If this is called within the scope of a transaction
    then it does nothing to affect that. If not, it beings and commits/rollsback
    the transaction it creates.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_UnallocateMultiple
  (@Operation         TDescription,
   @LPNsToUnallocate  TEntityKeysTable ReadOnly,
   @LPNId             TRecordId,
   @LPNDetailId       TRecordId,
   @UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @vRecordId      TRecordId,

          @vActivityLogId TRecordId,
          @vLPNId         TRecordId,
          @vLPNDetailId   TRecordId,
          @vErrMsg        TMessage,
          @vTranCount     TCount;

  declare @ttLPNDetails         TEntityKeysTable,
          @ttPalletsToRecount   TRecountKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vTranCount   = @@trancount;

  /* Get the LPN Details to temp table */
  if ((@LPNId is not null) and (@LPNDetailId is not null))
    insert into @ttLPNDetails(EntityId, EntityKey)
      select @LPNId, @LPNDetailId
  else
  if ((@LPNId is not null) and (@LPNDetailId is null))
    insert into @ttLPNDetails(EntityId, EntityKey)
      select LPNId, LPNDetailId
      from LPNDetails
      where (LPNId = @LPNId) and (OnhandStatus = 'R');
  else
    insert into @ttLPNDetails(EntityId, EntityKey)
      select EntityId, EntityKey
      from @LPNsToUnallocate;

begin try
  if (@vTranCount = 0)
    begin transaction;

  while (exists (select * from @ttLPNDetails where RecordId > @vRecordId))
    begin
      /* Get the next one here in the loop */
      select top 1 @vRecordId    = RecordId,
                   @vLPNId       = EntityId,
                   @vLPNDetailId = EntityKey
      from @ttLPNDetails
      where RecordId > @vRecordId;

      begin try
        /* save the transaction at this point so that if there is an error with the
        unallocating the LPNDetail, then only that is rolled back and we continue
        with other LPN Details */
        Save Transaction LPNDUnAllocate;

        exec pr_LPNDetails_Unallocate @vLPNId, @vLPNDetailId, @UserId, @Operation;

      end try
      begin catch
        /* Unless it is sn irrecoverable error, then rollback for this LPNDetail only. However
           if it is an error that cannot be recovered, then exit */
        if (XAct_State() <> -1)
          rollback transaction LPNDUnAllocate;
        else
          exec pr_ReRaiseError;

        /* Log the error and do not raise the error */
        select @vErrMsg = Error_Message();
        exec pr_ActivityLog_AddMessage @Operation, @vLPNId, @vLPNDetailId, 'LPN-LPNDetail', @vErrMsg, @@ProcId;
      end catch
    end

  /* Get all the Pallets to be recounted */
  insert into @ttPalletsToRecount (EntityId)
    select distinct PalletId
    from LPNs L
      join @ttLPNDetails ttLD on (L.LPNId = ttLD.EntityId)
    where (PalletId is not null);

  /* Defer counts on Pallets to clear order info if needed */
  if exists (select * from @ttPalletsToRecount)
    exec pr_Entities_RequestRecalcCounts 'Pallet', @RecalcOption = 'C', @ProcId = @@ProcId,
                                         @BusinessUnit     = @BusinessUnit,
                                         @RecountKeysTable = @ttPalletsToRecount;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If we have started the transaction then commit */
  if (@vTranCount = 0)
    commit;
end try
begin catch
  /* If we have started the transaction then rollback, else let caller do it */
  if (@vTranCount = 0) rollback;
  else
    exec pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_UnallocateMultiple */

Go
