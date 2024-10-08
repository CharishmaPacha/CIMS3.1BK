/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/12/29  TD      Added new procedure pr_Exports_PalletData.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_PalletData') is not null
  drop Procedure pr_Exports_PalletData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_PalletData:
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_PalletData
  (@TransType        TTypeCode,
   @PalletsToExport  TEntityKeysTable ReadOnly,
   @PalletId         TRecordId  = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,

   @RecordId         TRecordId = null output,
   @TransDateTime    TDateTime = null output,
   @CreatedDate      TDateTime = null output,
   @ModifiedDate     TDateTime = null output,
   @CreatedBy        TUserId   = null output,
   @ModifiedBy       TUserId   = null output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vRecordId              TRecordId,

          @vPalletId              TRecordId,
          @vPallet                TPallet,
          @vPalletOrderId         TRecordId,
          @vReference             TReference,
          @vControlCategory       TCategory,

          /* LPNs related  */
          @vLPNId                 TRecordId,
          @vLPNDetailId           TRecordId,
          @LPNId                  TRecordId,
          @LPNDetailId            TRecordId,
          @Weight                 TWeight,
          @Volume                 TVolume,
          @Lot                    TLot,

          @Reference              TReference,

          @TransEntity            TEntity    = null,
          @TransQty               TQuantity  = null,
          @Status                 TStatus    = 'N',
          @vExportPalletDetails   TControlValue,
          @vExportPalletHeaders   TControlValue,
          @vOwnership             TOwnership,
          @vWarehouse             TWarehouse,
          @vSKUId                 TRecordId,
          @vShipmentId            TRecordId,
          @vLoadId                TRecordId,
          @vOrderId               TRecordId,
          @vSoldToId              TCustomerId,
          @vShipToId              TShipToId;

  /* Temp table to hold all the Pallets to be updated */
  declare @ttPallets     TEntityKeysTable;

begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vRecordId         = 0,
         @CreatedBy         = @UserId,
         @vControlCategory  = 'Export.' + @TransType;

  /* If the given TransType is not active then do nothing and exit.
     Not all clients or installs use or are interested in all transaction types */
  if not exists (select * from vwEntityTypes
                 where ((TypeCode = @TransType) and
                        (Entity   = 'Transaction')))
    goto Exithandler;

  /* Get the control value to determine if we want to export Order Details also or not */
  select @vExportPalletDetails = dbo.fn_Controls_GetAsString(@vControlCategory, 'PalletDetails', 'Y' /* yes */, @BusinessUnit, @UserId),
         @vExportPalletHeaders = dbo.fn_Controls_GetAsString(@vControlCategory, 'PalletHeaders', 'Y' /* yes */, @BusinessUnit, @UserId);

  /* insert Pallets into the temp table */
  if (@PalletId is not null)
    insert into @ttPallets(EntityId) select @PalletId
  else
    insert into @ttPallets(EntityId)
      select EntityId from @PalletsToExport;

  while (exists (select * from @ttPallets where RecordId > @vRecordId))
    begin
      /* Get the next one here in the loop */
      select top 1
             @vPalletId = EntityId,
             @vRecordId = RecordId
      from @ttPallets
      where (RecordId > @vRecordId)
      order by RecordId;

      if (coalesce(@vPalletId, 0) = 0)
       goto Exithandler;

      /* get PalletDetails here */
      select  @vOwnership     = Ownership,
              @vWarehouse     = Warehouse,
              @BusinessUnit   = BusinessUnit,
              @vShipmentId    = ShipmentId,
              @vLoadId        = LoadId,
              @vPalletOrderId = OrderId
      from Pallets
      where (PalletId = @vPalletId);

      /* Fetch the SoldToId & ShipToId from OrderHeaders */
      if (@vPalletOrderId is not null)
        select @vSoldToId  = SoldToId,
               @vShipToId  = ShipToId
        from OrderHeaders
        where (OrderId = @vPalletOrderId);

      if (@TransType in ('Ship'))
        begin
          if (@vExportPalletDetails = 'Y' /* Yes */)
            begin
              /* Get all Pallet details .. if the pallet has same sku then send that as
                 one transaction instead of two transactions */
              declare PalletDetailsToExport Cursor Local Forward_Only Static Read_Only
              For select SKUId, LoadId, ShipmentId, OrderId, sum(Quantity)
              from vwLPNDetails
              where (PalletId  = @vPalletId) -- and
                    --(LPNStatus <> 'S' /* Shipped */)
              group by SKUId, ShipmentId, LoadId, OrderId;

              Open PalletDetailsToExport;
              Fetch next from PalletDetailsToExport into @vSKUId, @vLoadId, @vShipmentId, @vOrderId, @TransQty;

              while (@@fetch_status = 0)
                begin
                  /* Post the Pallet Details transaction */
                  exec @vReturnCode = pr_Exports_AddOrUpdate
                                        @TransType, 'PALD', @TransQty, @BusinessUnit,
                                        Default /* Status */,
                                        @PalletId   = @vPalletId,
                                        @SKUId      = @vSKUId,
                                        @Warehouse  = @vWarehouse,
                                        @Ownership  = @vOwnership,
                                        @OrderId    = @vOrderId,
                                        @ShipmentId = @vShipmentId,
                                        @LoadId     = @vLoadId;

                  Fetch next from PalletDetailsToExport into @vSKUId, @vLoadId, @vShipmentId, @vOrderId, @TransQty;
                end

              Close PalletDetailsToExport;
              Deallocate PalletDetailsToExport;
            end

            /* Now go for Pallet Headers */
            if (@vExportPalletHeaders = 'Y' /* Yes */)
              begin
                /* Post the Pallet header transaction */
                exec @vReturnCode = pr_Exports_AddOrUpdate
                                      @TransType, 'PAL', null, @BusinessUnit,
                                      @PalletId   = @vPalletId,
                                      @Ownership  = @vOwnership,
                                      @Warehouse  = @vWarehouse,
                                      @ShipmentId = @vShipmentId,
                                      @LoadId     = @vLoadId,
                                      @SoldToId   = @vSoldToId,
                                      @ShiptoId   = @vShipToId;
              end
        end /* TransType = Ship */

    end /* Next Pallet */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_PalletData */

Go
