/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/07/13  AY/PK   fn_LPNDetails_ComputeInnerpacks: Quantity changes to LDQuantity: Migrated from Prod (S2G-727)
  2018/05/01  OK      fn_LPNDetails_ComputeInnerpacks: Changes to return the calculated innerpacks irrespective of LPNDetailId if both Quantity and UnitsPerCase passed (S2G-775)
  2018/04/25  TK      pr_LPNDetails_ConfirmReservation & fn_LPNDetails_ComputeInnerpacks:
                        Bug fix not to update Innerpacks on unit storage locations (S2G-585)
  2018/04/03  TK      fn_LPNDetails_ComputeInnerpacks: Initial Revision (S2G-Support)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_LPNDetails_ComputeInnerpacks') is not null
  drop Function fn_LPNDetails_ComputeInnerpacks;
Go
/*------------------------------------------------------------------------------
  fn_LPNDetails_ComputeInnerpacks: This procedure returns Innerpacks for given LPN Detail
------------------------------------------------------------------------------*/
Create Function fn_LPNDetails_ComputeInnerpacks
  (@LPNDetailId   TRecordId,
   @Quantity      TQuantity,
   @UnitsPerCase  TQuantity)
  -----------------------------------------
   returns        TInteger /* Innerpacks */
as
begin
  /* Declarations */
  declare @vLPNId           TRecordId,
          @vSKUId           TRecordId,
          @vLocStorageType  TTypeCode,
          @vLDQuantity      TQuantity,
          @vUnitsPerCase    TQuantity,
          @vInnerPacks      TInteger;

  /* Initialize */
  set @vInnerPacks = 0;

  /* Get LPN info */
  select @vLPNId          = LPNId,
         @vSKUId          = SKUId,
         @vLocStorageType = StorageType,
         @vLDQuantity     = Quantity,
         @vUnitsPerCase   = UnitsPerPackage
  from vwLPNDetails
  where (LPNDetailId = @LPNDetailId);

  /* Innerpacks on Units Storage Location should be 0 */
  if (@vLocStorageType like 'U%')
    return(@vInnerPacks);

  /* If caller has passed Quantity and Units per Case then compute innerpacks just return. */
  if (coalesce(@Quantity, 0) >= 0) and (coalesce(@UnitsPerCase, 0) > 0)  -- and (@LPNDetailId is null)
    begin
      select @vInnerPacks = floor(@Quantity / @UnitsPerCase);

      return(@vInnerPacks);
    end

  /* If Units per Case not available on LPN detail then try to find out from SKUs */
  if (coalesce(@vUnitsPerCase, 0) = 0)
    select @vUnitsPerCase = UnitsPerInnerpack
    from SKUs
    where (SKUId = @vSKUId);

  /* If SKU pack configs are not defined then return 0 */
  if (coalesce(@vUnitsPerCase, 0) = 0)
    return(@vInnerPacks);

  /* Compute Innerpacks */
  select @vInnerPacks = floor(coalesce(@Quantity, @vLDQuantity, 0) / @vUnitsPerCase);

  return(@vInnerPacks);
end /* fn_LPNDetails_ComputeInnerpacks */

Go

--
