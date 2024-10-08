/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/08/02  TD      Added new Proc pr_Exports_SKUData.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_SKUData') is not null
  drop Procedure pr_Exports_SKUData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_SKUData:
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_SKUData
  (@TransType        TTypeCode,
   @SKUsToExport     TEntityKeysTable ReadOnly,
   @SKUId            TRecordId,
   @UPC              TUPC,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,

   @RecordId         TRecordId = null output,
   @TransDateTime    TDateTime = null output,
   @CreatedDate      TDateTime = null output,
   @ModifiedDate     TDateTime = null output,
   @CreatedBy        TUserId   = null output,
   @ModifiedBy       TUserId   = null output)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,

          @TransEntity      TEntity      = null,
          @TransQty         TQuantity,
          @vSKUId           TRecordId,
          @vUPC             TUPC,
          @vUnitVolume      TVolume,
          @vUnitWeight      TWeight,
          @vUnitLength      TLength,
          @vUnitWidth       TWidth,
          @vUnitHeight      THeight,
          @vReference       TReference;

  /* Temp table to hold all the SKUs to be updated */
  declare @ttSKUs   TEntityKeysTable;

begin
  SET NOCOUNT ON;

  select @ReturnCode    = 0,
         @MessageName   = null,
         @CreatedBy     = @UserId;

  /* If the given TransType is not active then do nothing and exit.
     Not all clients or installs use or are interested in all transaction types */
  if not exists (select * from vwEntityTypes
                 where ((TypeCode = @TransType) and
                        (Entity   = 'Transaction')))
    goto Exithandler;

  /* insert input skus into the temp table */
  if (@SKUId is not null)
    insert into @ttSKUs(EntityId) select @SKUId
  else
    insert into @ttSKUs(EntityId)
      select EntityId
      from @SKUsToExport;

  while (exists (select * from @ttSKUs))
    begin
      /* Get the next one here in the loop */
      select top 1 @vSKUId  = EntityId
      from @ttSKUs;

      /* Get SKU details here */
      select @vSKUId       = SKUId,
             @vUPC         = UPC,
             @vUnitVolume  = UnitVolume,
             @vUnitWeight  = UnitWeight,
             @vUnitLength  = UnitLength,
             @vUnitWidth   = UnitWidth,
             @vUnitHeight  = UnitHeight
      from SKUs
      where (SKUId = @vSKUId);

      if (coalesce(@vSKUId, 0) = 0)
       goto Exithandler;

      if (@TransType in ('SKUCh', 'UPC+', 'UPC-'))
        begin
          /* Export the SKU details here  */
          select @TransEntity = coalesce(@TransEntity, 'SKU' /* SKU Details */),
                 @vReference  = case when @TransType in ('UPC+', 'UPC-') then @UPC else null end;

          /* Post the Order header transaction */
          exec @ReturnCode = pr_Exports_AddOrUpdate
                                @TransType, @TransEntity, @TransQty, @BusinessUnit,
                                @SKUId         = @vSKUId,
                                @RecordId      = @RecordId,
                                @Weight        = @vUnitWeight,
                                @Volume        = @vUnitVolume,
                                @Length        = @vUnitLength,
                                @Width         = @vUnitWidth,
                                @Height        = @vUnitHeight,
                                @Reference     = @vReference,
                                @TransDateTime = @ModifiedDate,
                                @ModifiedBy    = @ModifiedBy;
        end

      /* Delete from the temp table once we export the sku to host  */
      delete from @ttSKUs
      where (EntityId = @vSKUId);
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_SKUData */

Go
