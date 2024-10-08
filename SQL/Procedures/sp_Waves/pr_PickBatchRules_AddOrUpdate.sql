/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/10/27  YJ      Added OrderInnerPacks, OrderUnits for pr_PickBatchRules_AddOrUpdate.
  2014/07/10  TD      pr_PickBatchRules_AddOrUpdate:Added new fields MaxInnerPacks,LPNs.
                      pr_PickBatchRules_AddOrUpdate: Updating MaxWeight, OrderWeightMin,OrderWeightMax,
  2011/08/04  TD      Added pr_PickBatchRules_AddOrUpdate, pr_PickBatch_Update
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatchRules_AddOrUpdate') is not null
  drop Procedure pr_PickBatchRules_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatchRules_AddOrUpdate:
    This proc will add a new PickBatching rule and edit and update the existing rule with new values..
    Assumes that All other validations done by Caller or from UI.
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatchRules_AddOrUpdate
  (@OrderType         TTypeCode,
   @OrderPriority     TPriority,
   @ShipVia           TShipVia,
   @SoldToId          TCustomerId,
   @ShipToId          TShipToId,
   @BatchType         TTypeCode,
   @BatchPriority     TPriority,
   @BatchStatus       TStatus,
   @MaxOrders         TCount,
   @MaxLines          TCount,
   @MaxSKUs           TCount,
   @MaxUnits          TCount,
   @MaxWeight         TWeight,
   @OrderWeightMin    TWeight,
   @OrderWeightMax    TWeight,
   @MaxVolume         TVolume,
   @MaxInnerPacks     TInnerPacks,
   @MaxLPNs           TCount,
   @OrderVolumeMin    TVolume,
   @OrderVolumeMax    TVolume,
   @OrderInnerPacks   TInteger,
   @OrderUnits        TInteger,
   @DestZone          TLookUpCode,
   @DestLocation      TLocation,
   @SortSeq           TSortSeq,
   @Status            TStatus,
   @VersionId         TRecordId,
   @BusinessUnit      TBusinessUnit,
   -----------------------------------------------
   @RuleId            TRecordId        output,
   @CreatedDate       TDateTime = null output,
   @ModifiedDate      TDateTime = null output,
   @CreatedBy         TUserId   = null output,
   @ModifiedBy        TUserId   = null output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription;

begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @Status      = coalesce(@Status, 'A' /* Active */);

  /* Need  Validations */
  if (@BusinessUnit is null)
    set @MessageName = 'InvalidBusinessUnit';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (coalesce(@RuleId, 0) = 0)
    begin
        /*if RuleId is null then it will insert.Ie.. add new one.  */
      insert into PickBatchRules(OrderType,
                                 OrderPriority,
                                 ShipVia,
                                 SoldToId,
                                 ShipToId,
                                 BatchType,
                                 BatchPriority,
                                 BatchStatus,
                                 MaxOrders,
                                 MaxLines,
                                 MaxSKUs,
                                 MaxUnits,
                                 MaxWeight,
                                 OrderWeightMin,
                                 OrderWeightMax,
                                 MaxVolume,
                                 MaxInnerPacks,
                                 MaxLPNs,
                                 OrderVolumeMin,
                                 OrderVolumeMax,
                                 OrderInnerPacks,
                                 OrderUnits,
                                 DestZone,
                                 DestLocation,
                                 SortSeq,
                                 Status,
                                 VersionId,
                                 BusinessUnit,
                                 CreatedBy,
                                 CreatedDate )
                        select
                                 @OrderType,
                                 @OrderPriority,
                                 @ShipVia,
                                 @SoldToId,
                                 @ShipToId,
                                 @BatchType,
                                 @BatchPriority,
                                 @BatchStatus ,
                                 @MaxOrders,
                                 @MaxLines,
                                 @MaxSKUs,
                                 @MaxUnits,
                                 @MaxWeight,
                                 @OrderWeightMin,
                                 @OrderWeightMax,
                                 @MaxVolume,
                                 @MaxInnerPacks,
                                 @MaxLPNs,
                                 @OrderVolumeMin,
                                 @OrderVolumeMax,
                                 @OrderInnerPacks,
                                 @OrderUnits,
                                 @DestZone,
                                 @DestLocation,
                                 @SortSeq,
                                 @Status,
                                 @VersionId,
                                 @BusinessUnit,
                                 coalesce(@CreatedBy, System_user),
                                 coalesce(@CreatedDate, current_timestamp);
    end
  else
    begin
      update PickBatchRules
      set OrderType       = @OrderType,
          OrderPriority   = @OrderPriority,
          ShipVia         = @ShipVia,
          SoldToId        = @SoldToId,
          ShipToId        = @ShipToId,
          BatchType       = @BatchType,
          BatchPriority   = @BatchPriority,
          BatchStatus     = @BatchStatus,
          MaxOrders       = @MaxOrders,
          MaxLines        = @MaxLines,
          MaxSKUs         = @MaxSKUs,
          MaxUnits        = @MaxUnits,
          MaxWeight       = @MaxWeight,
          OrderWeightMin  = @OrderWeightMin,
          OrderWeightMax  = @OrderWeightMax,
          MaxVolume       = @MaxVolume,
          MaxInnerPacks   = @MaxInnerPacks,
          MaxLPNs         = @MaxLPNs,
          OrderVolumeMin  = @OrderVolumeMin,
          OrderVolumeMax  = @OrderVolumeMax,
          OrderInnerPacks = @OrderInnerPacks,
          OrderUnits      = @OrderUnits,
          DestZone        = @DestZone,
          DestLocation    = @DestLocation,
          SortSeq         = @SortSeq,
          Status          = @Status,
          VersionId       = coalesce(@VersionId,     VersionId),
          BusinessUnit    = coalesce(@BusinessUnit,  BusinessUnit),
          ModifiedBy      = coalesce(@ModifiedBy,    System_User),
          ModifiedDate    = coalesce(@ModifiedDate,  current_timestamp)
      where(RuleId = @RuleId);
    end

  if (@ReturnCode = 0)
    goto ExitHandler;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatchRules_AddOrUpdate */

Go
