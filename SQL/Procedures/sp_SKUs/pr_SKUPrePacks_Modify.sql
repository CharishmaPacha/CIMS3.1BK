/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/11/14  PKS/YA  pr_SKUPrePacks_Modify: Procedure to update ComponentQty.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUPrePacks_Modify') is not null
  drop Procedure pr_SKUPrePacks_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUPrePacks_Modify: Procedure to update Component quantity on SKUPrePacks.
------------------------------------------------------------------------------*/
Create Procedure pr_SKUPrePacks_Modify
  (@SKUPrePackId     TRecordId,
   @ComponentQty     TQuantity,
   @UserId           TUserId,
   @BusinessUnit     TBusinessUnit)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,

          @vSKUPrePackId  TRecordId;
begin
  SET NOCOUNT ON;
  /* Set ComponentQty to Zero if the input param is null */
  set @ComponentQty = coalesce (@ComponentQty, 0);

  /* Fetching SKUPrepackId from the Input param */
  select @vSKUPrePackId = SKUPrePackId
  from SKUPrePacks
  where (SKUPrePackId = @SKUPrePackId);

  /* Validations */
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsRequired';
  else
  if (@ComponentQty = 0)
    set @MessageName = 'ComponentQtyIsNullOrZero';
  else
  if (@SKUPrePackId is null)
    set @MessageName = 'SKUIsRequired';
  else
  if ((@SKUPrePackId is not null) and (@vSKUPrePackId is null))
    set @MessageName = 'InvalidPrePackSKU';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update SKUPrePacks and set the ComponentQty for the given SKU */
  update SKUPrePacks
  set
    ComponentQty   = @ComponentQty,
    ModifiedDate   = current_timestamp,
    ModifiedBy     = coalesce(@UserId, System_User)
  where (SKUPrePackId = @SKUPrePackId);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_SKUPrePacks_Modify */

Go
