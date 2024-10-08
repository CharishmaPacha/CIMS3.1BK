/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/04/03  AY      fn_SKUs_GetDisplaySKU: Bug fix is to handle nulls
  2013/09/19  TD      fn_SKUs_GetDisplaySKU: sending blank instead of null.
  2013/08/23  AY      fn_SKUs_GetDisplaySKU: Migrated from OB
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_SKUs_GetDisplaySKU') is not null
  drop Function fn_SKUs_GetDisplaySKU;
Go
/*------------------------------------------------------------------------------
  Function fn_SKUs_GetDisplaySKU:
------------------------------------------------------------------------------*/
Create Function fn_SKUs_GetDisplaySKU
  (@SKU              TSKU,
   @Operation        TCategory,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
  -----------------------------------
  returns @ttSKUInfo table(SKUId          TRecordId,
                           DisplaySKU     TSKU,
                           DisplaySKUDesc TDescription)
as
begin
  declare @vSKUId            TRecordId,
          @vSKU              TSKU,
          @vSKU1             TSKU,
          @vSKU2             TSKU,
          @vSKU3             TSKU,
          @vSKU4             TSKU,
          @vSKU5             TSKU,
          @vSKU1Desc         TDescription,
          @vSKU2Desc         TDescription,
          @vSKU3Desc         TDescription,
          @vSKU4Desc         TDescription,
          @vSKU5Desc         TDescription,
          @vSKUDescription   TDescription,
          @vUPC              TUPC,
          @vAlternateSKU     TSKU,
          @vDisplaySKU       TControlValue,
          @vDisplaySKUDesc   TControlValue;

  /* Get the DisplaySKU, DisplaySKUDesc Formats */
  select @vDisplaySKU     = dbo.fn_Controls_GetAsString(@Operation, 'DisplaySKU', '%SKU%',
                                                        @BusinessUnit, @UserId),
         @vDisplaySKUDesc = dbo.fn_Controls_GetAsString(@Operation, 'DisplaySKUDesc', '%SKUDesc%',
                                                        @BusinessUnit, @UserId);

  /* Get the SKU info */
  select @vSKUId          = S.SKUId,
         @vSKU            = S.SKU,
         @vSKU1           = coalesce(S.SKU1, ''),
         @vSKU2           = coalesce(S.SKU2, ''),
         @vSKU3           = coalesce(S.SKU3, ''),
         @vSKU4           = coalesce(S.SKU4, ''),
         @vSKU5           = coalesce(S.SKU5, ''),
         @vSKUDescription = coalesce(S.Description, ''),
         @vUPC            = coalesce(S.UPC, ''),
         @vAlternateSKU   = coalesce(S.AlternateSKU, ''),
         @vSKU1Desc       = coalesce(S.SKU1Description, ''),
         @vSKU2Desc       = coalesce(S.SKU2Description, ''),
         @vSKU3Desc       = coalesce(S.SKU3Description, ''),
         @vSKU4Desc       = coalesce(S.SKU4Description, ''),
         @vSKU5Desc       = coalesce(S.SKU5Description, '')
  from fn_SKUs_GetScannedSKUs(@SKU, @BusinessUnit) SS join SKUs S on SS.SKUId = S.SKUId

  /* Build the SKU to Display */
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU1Desc%', @vSKU1Desc);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU2Desc%', @vSKU2Desc);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU3Desc%', @vSKU3Desc);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU4Desc%', @vSKU4Desc);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU5Desc%', @vSKU5Desc);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU1%',     @vSKU1);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU2%',     @vSKU2);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU3%',     @vSKU3);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU4%',     @vSKU4);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU5%',     @vSKU5);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKUDesc%',  @vSKUDescription);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%SKU%',      @vSKU);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%UPC%',      @vUPC);
  select @vDisplaySKU  = replace(@vDisplaySKU, '%AltSKU%',   @vAlternateSKU);

  /* Build the SKU to Display */
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU1Desc%', @vSKU1Desc);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU2Desc%', @vSKU2Desc);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU3Desc%', @vSKU3Desc);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU4Desc%', @vSKU4Desc);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU5Desc%', @vSKU5Desc);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU1%',     @vSKU1);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU2%',     @vSKU2);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU3%',     @vSKU3);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU4%',     @vSKU4);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU5%',     @vSKU5);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKUDesc%',  @vSKUDescription);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%SKU%',      @vSKU);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%UPC%',      @vUPC);
  select @vDisplaySKUDesc  = replace(@vDisplaySKUDesc, '%AltSKU%',   @vAlternateSKU);

  insert into @ttSKUInfo
    select @vSKUId, @vDisplaySKU, @vDisplaySKUDesc;

  return;
end /* fn_SKUs_GetDisplaySKU */

Go
