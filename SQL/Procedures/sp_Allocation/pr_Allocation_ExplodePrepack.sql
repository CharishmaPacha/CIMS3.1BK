/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  RIA     pr_Allocation_ExplodePrepack: Changes to pr_LPNs_AddSKU signature (HA-1794)
  2016/05/05  TK      pr_Allocation_ExplodePrepack & pr_Allocation_MaxPrePacksToBreak: Initial Revision (FB-648)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_ExplodePrepack') is not null
  drop Procedure pr_Allocation_ExplodePrepack;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_ExplodePrepack: This procedure will explode a PrepackSKU with
    its components SKUs as individual inventory
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_ExplodePrepack
  (@LPNId                 TRecordId,
   @PrePackSKUId          TRecordId,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   @PrePacksToExplode     TQuantity,
   ------------------------------------------
   @PrePacksExploded    TQuantity = 0 output)
as
  declare @ReturnCode           TInteger,
          @vMessageName         TMessageName,
          @vRecordId            TRecordId,

          @ReasonCode           TReasonCode,

          @vLPN                 TLPN,
          @vLPNId               TRecordId,
          @vLPNDetailId         TRecordId,
          @vLPNInnerPacks       TInnerpacks,
          @vLPNQty              TQuantity,
          @vLPNLocation         TLocation,
          @vLPNLocationId       TRecordId,

          @QtyToExplode         TQuantity,

          @vMasterSKU           TSKU,
          @vMasterSKUId         TRecordId,
          @vSKU                 TSKU,
          @vSKUId               TRecordId,

          @vCompSKULPNId        TRecordId,
          @vCompSKULPNDetailId   TRecordId,

          @vComponentSKUId      TRecordId,
          @vComponentSKU        TSKU,
          @vComponentQuantity   TQuantity,

          @vGenerateExportOnExplode
                                TFlag,

          @vAuditComment        TVarchar;

  declare @ttComponentSKUs Table
          (RecordId          TRecordId identity (1,1),
           MasterSKUId       TRecordId,
           MasterSKU         TSKU,
           ComponentSKUId    TRecordId,
           ComponentSKU      TSKU,
           ComponentQuantity TQuantity);

begin /* pr_Allocation_ExplodePrepack */
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Local variable assignment */
  select @vRecordId     = 0,
         @vAuditComment = 'ExplodePrepackOnAllocation';

  /* From LPN Info */
  select @vLPN            = LPN,
         @vLPNId          = LPNId,
         @vLPNDetailId    = LPNDetailId,
         @vLPNInnerPacks  = Innerpacks,
         @vLPNQty         = Quantity,
         @vLPNLocationId  = LocationId
  from vwLPNDetails
  where (LPNId = @LPNId) and
        (SKUId = @PrePackSKUId) and
        (OnhandStatus = 'A' /* Available */);  -- Consider Directed as well?

  /* Master SKU Info */
  select @vSKU   = SKU,
         @vSKUId = SKUId
  from SKUs
  where (SKUId = @PrePackSKUId);

  /* Get the SKUPrepack info */
  select @vMasterSKUId = MasterSKUId,
         @vMasterSKU   = MasterSKU
  from vwSKUPrePacks
  where (MasterSKUId  = @vSKUId) and
        (Status       = 'A' /* Active */);

  /* Get all component SKUs of the Master SKU into a temp table */
  insert into @ttComponentSKUs (MasterSKUId, MasterSKU, ComponentSKUId, ComponentSKU, ComponentQuantity)
    select MasterSKUId, MasterSKU, ComponentSKUId, ComponentSKU, ComponentQty
    from vwSKUPrePacks
    where (MasterSKUId = @vMasterSKUId) and
          (Status      = 'A' /* Active */);

  /* select Max Qty that can be exploded from LPN */
  set @QtyToExplode = dbo.fn_MinInt(@PrePacksToExplode, @vLPNQty)

  /* begin loop */
  while (exists(select * from @ttComponentSKUs where RecordId > @vRecordId))
    begin
      /* select top 1 record */
      select top 1 @vRecordId          = RecordId,
                   @vMasterSKUId       = MasterSKUId,
                   @vMasterSKU         = MasterSKU,
                   @vComponentSKUId    = ComponentSKUId,
                   @vComponentSKU      = ComponentSKU,
                   @vComponentQuantity = (ComponentQuantity * @QtyToExplode)
      from @ttComponentSKUs
      where (RecordId > @vRecordId)
      order by RecordId;

      /* see if Component SKU already exists in the LPN */
      select @vCompSKULPNId = LPNId,
             @vCompSKULPNDetailId = LPNDetailId
      from LPNDetails
      where (LPNId = @vLPNId) and
            (SKUId = @vComponentSKUId);

      /* If component SKU exists the adjust Qty or Add SKU */
      if (@vCompSKULPNDetailId is not null)
        exec pr_LPNDetails_AddOrUpdate @vCompSKULPNId, null /* LPNLine */, null /* CoO */,
                                       @vComponentSKUId, @vComponentSKU, null /* innerpacks */, @vComponentQuantity,
                                       0 /* ReceivedUnits */, null /* ReceiptId */, null /* ReceiptDetailId */,
                                       null/* OrderId */, null/* OrderDetailId */, null /* OnHandStatus */, null /* Operation */,
                                       null /* Weight */, null /* Volume */, null /* Lot */,
                                       @BusinessUnit /* BusinessUnit */, @vCompSKULPNDetailId  output;
      else
        /* Add SKU */
        begin
          exec @ReturnCode = pr_LPNs_AddSKU @vLPNId,
                                            @vLPN,
                                            null, /* SKUId */
                                            @vComponentSKU,
                                            0 /* InnerPacks */,
                                            @vComponentQuantity /* Quantity */,
                                            @ReasonCode, /* Reason Code */
                                            '', /* InventoryClass1 */
                                            '', /* InventoryClass2 */
                                            '', /* InventoryClass3 */
                                            @BusinessUnit,
                                            @UserId;

          /* Insert Audit Trail */
          exec pr_AuditTrail_Insert 'ExplodePP_AddSKUToLPN', @UserId, null /* ActivityTimestamp */,
                                    @LPNId      = @vLPNId,
                                    @SKUId      = @vComponentSKUId,
                                    @Quantity   = @vComponentQuantity;
        end
    end /* End Loop */

  /* Adjust LPN to reduce Exploded Prepack Qty */
  exec @ReturnCode = pr_LPNs_AdjustQty @vLPNId,
                                       @vLPNDetailId,
                                       @vMasterSKUId,
                                       @vMasterSKU,
                                       0, /* InnerPacks */
                                       @QtyToExplode, /* Quantity */
                                       '-' /* Update Option - Exact Qty */,
                                       @vGenerateExportOnExplode /* Export? Yes */,
                                       @ReasonCode,  /* Reason Code - in future accept reason from User */
                                       null, /* Reference */
                                       @BusinessUnit,
                                       @UserId;

  if (@ReturnCode = 0)
    begin
      update LPNs
      set PickingClass = 'BP' /* Break Pack */
      where (LPNId = @vLPNId);

      set @PrePacksExploded = @QtyToExplode;
    end

  /* Audit Trail */
  if (@ReturnCode = 0)
    begin
      exec pr_AuditTrail_Insert @vAuditComment, @UserId, null /* ActivityTimestamp */,
                                @LPNId       = @vLPNId,
                                @SKUId       = @vMasterSKUId,
                                @LocationId  = @vLPNLocationId,
                                @Quantity    = @QtyToExplode,
                                @Comment     = @vAuditComment output;
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  rollback transaction;
  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Allocation_ExplodePrepack */

Go
