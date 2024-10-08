/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/01  TK      fn_SKUs_IsOperationAllowed: Revamped to consider operation (S2GCAN-26)
  2018/02/28  SV      fn_SKUs_IsOperationAllowed: Corrected the defaut value for the control UPCsRequired (S2G-302)
  2018/02/10  AY      fn_SKUs_IsOperationAllowed: Enforce UPC/CaseUPC (S2G-155)
  2014/12/29  DK      fn_SKUs_IsOperationAllowed: Validating SKUs based on control variable.
  2013/08/27  TD      fn_SKUs_IsOperationAllowed:Sending description instead of Message.
  2013/08/17  AY      fn_SKUs_IsOperationAllowed: New function introduced
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_SKUs_IsOperationAllowed') is not null
  drop Function fn_SKUs_IsOperationAllowed;
Go
/*------------------------------------------------------------------------------
  Function fn_SKUs_IsOperationAllowed: There could be certain requirements to be able to
   receive a SKU in the Warehouse, these are validated in this function. Similar
   requirements may exist for Shipping and hence the validations could later be
   expanded based upon Operation.
------------------------------------------------------------------------------*/
Create Function fn_SKUs_IsOperationAllowed
  (@SKUId           TRecordId,
   @Operation       TDescription)
  -------------------------------
   returns          TDescription
as
begin
  declare  @vMessageName             TMessageName,
           @vWeight                  TWeight,
           @vVolume                  TVolume,
           @vLength                  TLength,
           @vWidth                   TWidth,
           @vHeight                  THeight,
           @vUnitsPerInnerPack       TInteger,
           @vInnerPacksPerLPN        TInteger,
           @vPalletTie               TVarChar,
           @vPalletHigh              TVarChar,
           @vUPC                     TUPC,
           @vCaseUPC                 TUPC,
           @vSKUCubeWeightRequired   TControlValue,
           @vSKUDimensionsRequired   TControlValue,
           @vSKUPackInfoRequired     TControlValue,
           @vPalletTieHighRequired   TControlValue,
           @vUPCsRequired            TControlValue,
           @vControlCategory         TCategory,
           @vBusinessUnit            TBusinessUnit;

  /* Get SKU details here */
  select @vWeight            = nullif(UnitWeight, ''),
         @vVolume            = nullif(UnitVolume, ''),
         @vLength            = nullif(UnitLength, ''),
         @vWidth             = nullif(UnitWidth,  ''),
         @vHeight            = nullif(UnitHeight, ''),
         @vUnitsPerInnerPack = nullif(UnitsPerInnerPack, ''),
         @vInnerPacksPerLPN  = nullif(InnerPacksPerLPN, ''),
         @vPalletTie         = nullif(PalletTie, ''),
         @vPalletHigh        = nullif(PalletHigh, ''),
         @vUPC               = UPC,
         @vCaseUPC           = CaseUPC,
         @vBusinessUnit      = BusinessUnit,
         @vMessageName       = null,
         @vControlCategory   = 'SKU_' + @Operation
  from SKUs
  where (SKUId = @SKUId);

  /* Get Controls */
  select @vSKUDimensionsRequired  = dbo.fn_Controls_GetAsString(@vControlCategory, 'SKUDimensionsRequired',  'N' /* No */, @vBusinessUnit, System_User);
  select @vSKUCubeWeightRequired  = dbo.fn_Controls_GetAsString(@vControlCategory, 'SKUCubeWeightRequired',  'N' /* No */, @vBusinessUnit, System_User);
  select @vSKUPackInfoRequired    = dbo.fn_Controls_GetAsString(@vControlCategory, 'SKUPackInfoRequired',    'N' /* No */, @vBusinessUnit, System_User);
  select @vPalletTieHighRequired  = dbo.fn_Controls_GetAsString(@vControlCategory, 'PalletTieHighRequired',  'N' /* No */, @vBusinessUnit, System_User);
  select @vUPCsRequired           = dbo.fn_Controls_GetAsString(@vControlCategory, 'UPCsRequired',           'U' /* UPC */, @vBusinessUnit, System_User);

  /* Validations */
  if (@vSKUDimensionsRequired = 'Y' /* Yes */) and
     ((coalesce(@vLength, 0) = 0) or
      (coalesce(@vHeight, 0) = 0) or
      (coalesce(@vWidth,  0) = 0))
    set @vMessageName = 'SKUDimensionsRequired';
  else
  if (@vSKUCubeWeightRequired = 'Y' /* Yes */) and
     ((coalesce(@vVolume, 0) = 0) or
      (coalesce(@vWeight, 0) = 0))
    set @vMessageName = 'SKUCubeWeightRequired';
  else
  if (@vSKUPackInfoRequired = 'Y' /* Yes */) and
     ((coalesce(@vUnitsPerInnerPack, 0) = 0) or
      (coalesce(@vInnerPacksPerLPN, 0) = 0))
    set @vMessageName = 'SKUPackInfoRequired';
  else
  if (@vPalletTieHighRequired = 'Y' /* Yes */) and
     ((coalesce(@vPalletTie, 0) = 0) or
      (coalesce(@vPalletHigh, 0) = 0))
    set @vMessageName = 'PalletTieHighRequired';
  else
  if (charindex('U', @vUPCsRequired) > 0) and (coalesce(@vUPC, '') = '')
    set @vMessageName = 'UPCRequired';
  else
  if (charindex('C', @vUPCsRequired) > 0) and (coalesce(@vCaseUPC, '') = '')
    set @vMessageName = 'CaseUPCRequired';

  /* Return message */
  return @vMessageName;
end /* fn_SKUs_IsOperationAllowed */

Go
