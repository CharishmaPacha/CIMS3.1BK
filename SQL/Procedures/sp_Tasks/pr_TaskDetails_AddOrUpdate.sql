/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_TaskDetails_AddOrUpdate') is not null
  drop Procedure pr_TaskDetails_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_TaskDetails_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_TaskDetails_AddOrUpdate
  (@TaskId               TRecordId,
   @Status               TStatus,
   @TransactionDate      TDateTime,
   @LocationId           TRecordId,
   @LPNId                TRecordId,
   @SKUId                TRecordId,
   @PalletId             TRecordId,

   @BusinessUnit         TBusinessUnit,
   ---------------------------------
   @TaskDetailId         TRecordId        output,
   @CreatedDate          TDateTime = null output,
   @ModifiedDate         TDateTime = null output,
   @CreatedBy            TUserId   = null output,
   @ModifiedBy           TUserId   = null output)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,

          @vLocationId    TRecordId,
          @vLocation      TLocation,
          @vLPNId         TRecordId,
          @vLPN           TLPN,
          @vSKUId         TRecordId,
          @vSKU           TSKU,
          @vPalletId      TRecordId,
          @vPallet        TPallet;

  declare @Inserted table (TaskDetailId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);

begin /* pr_TaskDetails_AddOrUpdate */
  select @ReturnCode  = 0,
         @MessageName = null;

  select @vLocationId = LocationId,
         @vLocation   = Location
  from Locations
  where (LocationId   = @LocationId) and
        (BusinessUnit = @BusinessUnit);

  select @vLPNId = LPNId,
         @vLPN   = LPN
  from LPNs
  where (LPNId        = @LPNId) and
        (BusinessUnit = @BusinessUnit);

  select @vSKUId = SKUId,
         @vSKU   = SKU
  from SKUs
  where (SKUId        = @SKUId) and
        (BusinessUnit = @BusinessUnit);

  select @vPalletId = PalletId,
         @vPallet   = Pallet
  from Pallets
  where (PalletId     = @PalletId) and
        (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@TaskId is null)
    set @MessageName  = 'InvalidTask';
  else
  if (@LocationId is null)
    set @MessageName  = 'InvalidLocation';
  else
  if (@LPNId is null)
    set @MessageName  = 'InvalidLPN';
  else
  if (@SKUId is null)
    set @MessageName  = 'InvalidSKU';
  else
  if (@Status is null)
    set @MessageName  = 'InvalidStatus';
  else
  if (@PalletId is null)
    set @MessageName  = 'InvalidPallet';
  else
  if(@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';
  else
  if (@LocationId is not null) and (@vLocationId is null)
    set @MessageName  = 'LocationDoesNotExist';
  else
  if (@LPNId is not null) and (@vLPNId is null)
    set @MessageName  = 'LPNDoesNotExist';
  else
  if (@SKUId is not null) and (@vSKUId is null)
    set @MessageName  = 'SKUDoesNotExist';
  else
  if (@PalletId is not null) and (@vPalletId is null)
    set @MessageName  = 'PalletDoesNotExist';
  else
  if (@Status is not null) and
     (not exists(select *
                 from Statuses
                 where (Entity     = 'Task') and
                       (StatusCode = @Status) and
                       (Status     = 'A')))
    set @MessageName  = 'StatusDoesNotExist';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Validates TaskId whether it is exists, if it then it updates or inserts  */
  if (not exists(select *
                 from TaskDetails
                 where TaskDetailId = @TaskDetailId))
    begin
      insert into TaskDetails(TaskId,
                              Status,
                              TransactionDate,
                              LocationId,
                              LPNId,
                              SKUId,
                              PalletId,
                              BusinessUnit,
                              CreatedBy)
                       output inserted.TaskDetailId, inserted.CreatedDate, inserted.CreatedBy
                         into @Inserted
                       select @TaskId,
                              @Status,
                              @TransactionDate,
                              @LocationId,
                              @LPNId,
                              @SKUId,
                              @PalletId,
                              @BusinessUnit,
                              coalesce(@CreatedBy, System_User);
      select @TaskDetailId = TaskDetailId,
             @CreatedDate  = CreatedDate,
             @CreatedBy    = CreatedBy
      from @Inserted;
    end
  else
    begin
      update TaskDetails
      set
        Status          = @Status,
        TransactionDate = @TransactionDate,
        @ModifiedDate   = ModifiedDate = current_timestamp,
        @ModifiedBy     = ModifiedBy   = coalesce(@ModifiedBy, System_User)
      where (TaskDetailId = @TaskDetailId) and
            (BusinessUnit = @BusinessUnit);
    end
ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_TaskDetails_AddOrUpdate */

Go
