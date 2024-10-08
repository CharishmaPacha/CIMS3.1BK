/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/11  SK      pr_Pallets_Lost: Set clear pallet to Y when pallet is marked as lost (HA-2244)
  2020/12/29  AY      pr_Pallets_Lost: Revamp to use default reason codes (HA-1837)
  2012/08/20  PK      pr_Pallets_Lost: Updating Pallets Count on the Location if Pallet Lost.
  2012/07/22  PK      Added pr_Pallets_Lost
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_Lost') is not null
  drop Procedure pr_Pallets_Lost;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_Lost: Procedure to update the Pallet and all it's LPN as Lost,
    used during CC of Pallet or short pick of pallet
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_Lost
  (@PalletId      TRecordId,
   @ReasonCode    TReasonCode = null,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @Status        TStatus = 'O' output)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,
          @vRecordId         TRecordId,

          @vLocationId       TRecordId,
          @vLPNId            TRecordId,
          @vLPN              TLPN,
          @vCount            TCount,
          @vNumLPNs          TCount,
          @vQuantity         TQuantity,
          @vInnerpacks       TInnerPacks,
          @vReasonCode       TReasonCode;

  declare @ttPalletLPNs      TEntityKeysTable;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vReasonCode  = @ReasonCode;

  /* Validations */
  if (@PalletId is null)
    set @vMessageName = 'InvalidPallet';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vReasonCode is null)
    select @vReasonCode = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCLost',    null /* CIMS Default */, @BusinessUnit, @UserId);

  /* Update Pallet Location and Status */
  update Pallets
  set @vLocationId  = LocationId,
      @vNumLPNs     = NumLPNs,
      @vQuantity    = Quantity,
      @vInnerPacks  = Innerpacks,
      LocationId    = null,
      Status        = coalesce(@Status, Status),
      ModifiedDate  = current_timestamp,
      ModifiedBy    = @UserId
  where (PalletId = @PalletId);

  /* Insert all the LPNs which are on the Pallet to a temp table */
  insert into @ttPalletLPNs(EntityId, EntityKey)
    select LPNId, LPN from LPNs where (PalletId = @PalletId);

  /* Mark all LPNs on the Pallet as Lost, if the Pallet is Lost */
  while exists (select * from @ttPalletLPNs where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId = RecordId,
                   @vLPNId    = EntityId
      from @ttPalletLPNs
      where (RecordId > @vRecordId)
      order by RecordId;

      exec pr_LPNs_Lost @vLPNId,
                        @vReasonCode,
                        @UserId,
                        'Y'       /* Clear Pallet on LPNs */,
                        default   /* Audit Activity */,
                        'O'       /* @Status */,
                        'U'       /* @OnhandStatus */;
    end

  /* Reduce the NumPallets on the Location */
  exec pr_Locations_UpdateCount @LocationId   = @vLocationId,
                                @NumPallets   = 1,
                                @UpdateOption = '-' /* Subtract */;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_Lost */

Go
