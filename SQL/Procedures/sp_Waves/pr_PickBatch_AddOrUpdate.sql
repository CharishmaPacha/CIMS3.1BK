/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/08/04  TD      pr_PickBatch_Update => pr_PickBatch_AddOrUpdate
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_AddOrUpdate') is not null
  drop Procedure pr_PickBatch_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_AddOrUpdate:
    This proc will update only Priority field.
    Assumes that All other validations done by Caller or from UI.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_AddOrUpdate
  (@BatchNo         TPickBatchNo  = null,
   @BatchType       TTypeCode     = null,
   @Status          TStatus       = null,
   @Priority        TPriority     = null, /* Now we are updating only Priority */
   @NumOrders       TCount        = null,
   @NumLines        TCount        = null,
   @NumSKUs         TCount        = null,
   @NumUnits        TCount        = null,
   @SoldToId        TCustomerId   = null,
   @ShipToId        TShipToId     = null,
   @ShipVia         TShipVia      = null,
   @PickZone        TLookUpCode   = null,
   @PalletId        TRecordId     = null,
   @WaveId          TRecordId     = null,
   @RuleId          TRecordId     = null,
   @BusinessUnit    TBusinessUnit = null,
   ---------------------------------------------
   @RecordId        TRecordId            output,
   @CreatedDate     TDateTime     = null output,
   @ModifiedDate    TDateTime     = null output,
   @CreatedBy       TUserId       = null output,
   @ModifiedBy      TUserId       = null output)
as
  declare @ReturnCode   TInteger,
          @MessageName  TMessageName,
          @Message      TDescription;
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @Status      = coalesce(@Status, 'N' /* New */);;

  /* Need  Validations */

  if (@RecordId is null)
    set @MessageName = 'InvalidBatch';
  else
  if (@BusinessUnit is null)
    set @MessageName = 'InvalidBusinessUnit';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Trying  to add new record if not exists */
  if (coalesce(@RecordId, 0) = 0)
    begin
      insert into PickBatches(BatchNo,
                              BatchType,
                              Status,
                              WaveStatus,
                              Priority,
                              NumOrders,
                              NumLines,
                              NumSKUs,
                              NumUnits,
                              SoldToId,
                              ShipToId,
                              ShipVia,
                              PickZone,
                              PalletId,
                              RuleId,
                              BusinessUnit,
                              CreatedBy,
                              CreatedDate )
                    select
                              @BatchNo,
                              @BatchType,
                              @Status,
                              @Status,
                              @Priority,
                              @NumOrders,
                              @NumLines,
                              @NumSKUs,
                              @NumUnits ,
                              @SoldToId,
                              @ShipToId,
                              @ShipVia,
                              @PickZone,
                              @PalletId,
                              @RuleId,
                              @BusinessUnit,
                              coalesce(@CreatedBy, System_user),
                              coalesce(@CreatedDate, current_timestamp);

    end
  else
    begin
      update PickBatches
      set BatchNo       = coalesce(@BatchNo,      BatchNo),
          BatchType     = coalesce(@BatchType,    BatchType),
          Status        = coalesce(@Status,       Status),
          WaveNo        = coalesce(@BatchNo,      BatchNo),
          WaveType      = coalesce(@BatchType,    BatchType),
          WaveStatus    = coalesce(@Status,       Status),
          Priority      = coalesce(@Priority,     Priority),
          NumOrders     = coalesce(@NumOrders,    NumOrders),
          NumLines      = coalesce(@NumLines,     NumLines),
          NumSKUs       = coalesce(@NumSKUs,      NumSKUs),
          NumUnits      = coalesce(@NumUnits,     NumUnits),
          SoldToId      = coalesce(@SoldToId,     SoldToId),
          ShipToId      = coalesce(@ShipToId,     ShipToId),
          ShipVia       = coalesce(@ShipVia,      ShipVia),
          PickZone      = coalesce(@PickZone,     PickZone),
          PalletId      = coalesce(@PalletId,     PalletId),
          RuleId        = coalesce(@RuleId,       RuleId),
          ModifiedBy    = coalesce(@ModifiedBy,   System_User),
          ModifiedDate  = coalesce(@ModifiedDate, current_timestamp)
      where (WaveId = @RecordId);

    end

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_AddOrUpdate */

Go
