/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_ExplodeLPNs') is not null
  drop Procedure pr_LPNs_ExplodeLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_ExplodeLPN: This procedure creates the LPNs for each IP on the LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_ExplodeLPNs
  (@LPNId         TRecordId,
   @LPNsToExplode TEntityKeysTable readonly,
   @PalletId      TRecordId,
   @OrderId       TRecordId,
   @Options       TFlags,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vRecordId             TRecordId,

          @vLPNId                TRecordId,
          @vLPN                  TLPN,
          @vLPNType              TTypeCode,
          @vInnerPacks           TInnerPacks,
          @vQuantity             TQuantity,
          @vReceiptId            TRecordId,
          @vOrderId              TRecordId,
          @vPalletId             TRecordId,
          @vLocationId           TRecordId,
          @vLoadId               TRecordId,
          @vShipmentId           TRecordId,
          @vBoLId                TRecordId,
          @vBoL                  TBoL,
          @vLPNDetailIdToSplit   TRecordId,
          @vInnerPacksToSplit    TCount,

          @xmlRulesData          TXML,
          @vEntity               TEntity,
          @vIsLPNExplodeRequired TControlValue;

  declare @ttLPNstoExplode       TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get all the LPNs */
  if (@LPNId is not null) /* If LPNId passed */
    begin
      insert into @ttLPNsToExplode (EntityId)
        select @LPNId;
    end
  else
  if (@PalletId is not null) /* If Pallet is passed then process all the LPNs on the pallet */
    begin
      insert into @ttLPNsToExplode (EntityId, EntityKey)
        select LPNId, LPN
        from LPNs
        where (PalletId = @PalletId)
        order by LPNId;
    end
  else
  if (@OrderId is not null)
    begin
      insert into @ttLPNsToExplode (EntityId, EntityKey)
        select LPNId, LPN
        from LPNs
        where (OrderId = @OrderId)
        order by LPNId;
    end
  else
    begin
      insert into @ttLPNsToExplode (EntityId, EntityKey)
        select EntityId, EntityKey
        from @LPNsToExplode
        order by RecordId;
    end

  /* Loop through all the LPNs */
  while (exists (select * from @ttLPNsToExplode where RecordId > @vRecordId))
    begin
      /* get the top LPNId */
      select top 1 @vLPNId     = EntityId,
                   @vRecordId  = RecordId
      from @ttLPNsToExplode
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get all the Detail information */
      select @vLPN         = LPN,
             @vLPNType     = LPNType,
             @vInnerPacks  = InnerPacks,
             @vReceiptId   = ReceiptId,
             @vOrderId     = OrderId,
             @vPalletId    = PalletId,
             @vLocationId  = LocationId,
             @vLoadId      = LoadId,
             @vShipmentId  = ShipmentId,
             @vBoL         = BoL,
             @vEntity      = 'LPN'
      from LPNs
      where (LPNId = @vLPNId);

      if (@vBoL is not null)
        select @vBoLId = BoLId from BoLs where BoLNumber = @vBoL;

      /* Build the data for rule evaluation */
      select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                             dbo.fn_XMLNode('Entity',    @vEntity  ) +
                             dbo.fn_XMLNode('LPNId',     @vLPNId   ) +
                             dbo.fn_XMLNode('LPN',       @vLPN     ) +
                             dbo.fn_XMLNode('LPNType',   @vLPNType ) +
                             dbo.fn_XMLNode('PalletId',  @vPalletId) +
                             dbo.fn_XMLNode('OrderId',   @vOrderId ));

      /* For particular order only we need to explode the LPN. Rules will determine whether exploding is required or not */
      exec pr_RuleSets_Evaluate 'OnShipping_ExplodeLPN', @xmlRulesData, @vIsLPNExplodeRequired output;

      /* If Exploding is not required for the LPN then skip that LPN and process others */
      if (@vIsLPNExplodeRequired = 'N')
        continue;

      /* If LPN has multiple Innerpacks then create the LPN for each IP */
      select @vInnerPacksToSplit = @vInnerPacks - 1;

      while (@vInnerPacksToSplit > 0)
        begin
          /* Create the LPNs for each IP */
          exec @vReturnCode =  pr_LPNs_SplitLPN @FromLPN         = @vLPN,
                                                @SplitInnerPacks = 1,
                                                @UserId          = @UserId,
                                                @BusinessUnit    = @BusinessUnit;

          select @vInnerPacksToSplit -= 1;
        end /* End while - To split LPNs */

      /* recount all the required info */
      if (@vPalletId is not null)
        exec pr_Pallets_UpdateCount @vPalletId;

      if (@vLoadId is not null)
        exec pr_Load_Recount @vLoadId;

      if (@vLocationId is not null)
        exec pr_Locations_UpdateCount @vLocationId, null, '*' ;

      if (@vBoLId is not null)
        exec pr_BoL_Recount @vBoLId;

      if (@vShipmentId is not null)
        exec pr_Shipment_Recount @vShipmentId;

      if (@vReceiptId is not null)
        exec pr_ReceiptHeaders_Recount @vReceiptId;

      if (@vOrderId is not null)
        exec pr_OrderHeaders_Recount @vOrderId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_ExplodeLPNs */

Go
