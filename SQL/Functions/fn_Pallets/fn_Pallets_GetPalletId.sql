/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/02/25  AY      fn_Pallets_GetPalletId, pr_Pallets_SetLocation: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Pallets_GetPalletId') is not null
  drop Function fn_Pallets_GetPalletId;
Go
Create Function fn_Pallets_GetPalletId
  (@LPNorPallet  TLPN,
   @BusinessUnit TBusinessUnit)
  -----------------------------
   returns       TRecordId
as
begin
  declare @vPalletId TRecordId;

  /* Check to see if the user scanned a Pallet */
  select @vPalletId = PalletId
  from Pallets
  where (Pallet = @LPNorPallet) and (BusinessUnit = @BusinessUnit);

  /* If scanned entity is not pallet, then see if it is LPN and then try to
     find the Pallet the LPN is on */
  if (@vPalletId is null)
    select @vPalletId = PalletId
    from LPNs
    where (LPN = @LPNorPallet) and (BusinessUnit = @BusinessUnit);

  return(@vPalletId);
end /* pr_Pallets_GetPalletId */

Go
