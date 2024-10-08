/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/06/16  KL      pr_BoLOrderDetails_Update / pr_BoLCarrierDetails_Update: Update weight on Loads when manually edit weight on BoL details (FB-708)
  2013/04/05  PKS     pr_BoLOrderDetails_Update / pr_BoLCarrierDetails_Update: Weight of BolOrderDetails are updated then same was updated
  2013/01/30  YA      pr_BoLOrderDetails_Update: Updating one OrderDetail should update all the details on that Master BoL for the same CustPO..
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoLOrderDetails_Update') is not null
  drop Procedure pr_BoLOrderDetails_Update;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoLOrderDetails_Update:
    This Procedure will update the BoLOrderDetails
------------------------------------------------------------------------------*/
Create Procedure pr_BoLOrderDetails_Update
  (@BoLOrderDetailId  TRecordId,
   @BoLNumber         TBoLNumber,
   @CustPO            TCustPO      = null,  /* Not updated */
   @NumPallets        TCount       = null,  /* Not used */
   @NumLPNs           TCount       = null,
   @NumInnerPacks     TCount       = null,  /* Not used */
   @NumUnits          TCount       = null,  /* Not used */
   @Volume            TVolume      = null,  /* Not used */
   @Weight            TWeight      = null,
   @Palletized        TFlag        = null,
   @ShipperInfo       TDescription = null,
   @Message           TDescription = null output)
as
  declare @ReturnCode    TInteger,
          @MessageName   TMessageName,
          @vBoLId        TBoLId,
          @vBoLDetailId  TRecordId,
          @MasterBoL     TBoLNumber,
          @ShipToId      TShipToId,
          @vLoadId       TLoadId,
          @vBoLCarrierDetailCount  TCount;
begin  /* pr_BoLOrderDetails_Update */

  select @ReturnCode  = 0,
         @Message     = null,
         @MessageName = null;

  if (@BoLOrderDetailId is null)
    set @MessageName = 'BoLOrderDetailIdIsRequired';

  if (@MessageName is not null)
    goto ErrorHandler;

    /* Get BoL Info  here - This info is UNUSED */
  select @vBoLId        = BoLId,
         @vBoLDetailId  = BoLOrderDetailId,
         @vLoadId       = LoadId
  from vwBoLOrderDetails
  where (BoLOrderDetailId = @BoLOrderDetailId);

  /* Update BoLOrder Details for the BoL */
  update BoLOrderDetails
  set NumPallets    = @NumPallets,
      NumLPNs       = @NumLPNs,
      NumInnerPacks = @NumInnerPacks,
      NumUnits      = @NumUnits,
      Volume        = @Volume,
      Weight        = @Weight,
      Palletized    = @Palletized,
      ShipperInfo   = @ShipperInfo
  where (BoLOrderDetailId = @BoLOrderDetailId);

  /*** No clue what these next two blocks of code are for - AY 2020/06/20 */
  /* Fetch the Master BoL to update on all */
  select @MasterBoL = MasterBoL
  from BoLs
  where (BoLId = @vBoLId);

  /* Update BoLOrder Details for the BoL */
  update BoLOrderDetails
  set ShipperInfo = @ShipperInfo
  where (BoLId in (select BoLId
                   from BoLs
                   where (MasterBoL = @MasterBoL))) and
        (CustomerOrderNo = @CustPO);

  /* Check how many BoL Carrier details are there. If there is only one
     BoL Carrier detail, then when the weight is updated on the BoLOrderDetail
     section, then update the weight on the BoLCarrier detail section as well
     so that user does not have to correct both of them */
  select @vBoLCarrierDetailCount = count(*)
  from BolCarrierDetails
  where (BolId = @vBoLId);

  if (@vBoLCarrierDetailCount = 1)
    begin
      With BoLWeight(BoLId, Weight) As
      (
        /* Will get the total weight for the BoL */
        select @vBoLId, sum(Weight)
        from BoLOrderDetails
        where (BoLId = @vBoLId)
      )
      update BCD
      set BCD.Weight = BW.Weight
      from BoLCarrierDetails BCD
        join BoLWeight BW on (BW.BoLId = BCD.BoLId)
      where BCD.BoLId = @vBoLId;

      /* recalculate weight on Load */
      exec pr_Load_Recount @vLoadId;
    end

  /* Build the success message */
  set @Message = dbo.fn_Messages_GetDescription('BoL_OrderDetailsModify_Successful');

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_BoLOrderDetails_Update */

Go
