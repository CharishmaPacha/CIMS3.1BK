/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/17  TK      pr_Imports_ASNLPNDtl_AddSKUsToPicklane & pr_Imports_InventoryAdjustments:
              AY      pr_Imports_InventoryAdjustments: Change to only process LOCADJ transactions (HA-2341)
  2019/10/11  YJ      pr_Imports_InventoryAdjustments: Ported changes from Prod Onsite (S2GCA-98) (Ported from Prod)
  2019/09/24  TK      pr_Imports_InventoryAdjustments: Bug fix in overriding SKUId on adjusting LPN Quantity (S2GCA-979)
  2019/07/13  PK      pr_Imports_InventoryAdjustments: Enhanced to generate LPN and Move to the location if the location is of reserve or bulk (S2GCA-863).
  2019/05/06  SV      pr_Imports_InventoryAdjustments: Correction done to show the appropriate message on Inv adjustments (S2GCA-718)
  2018/10/04  YJ      pr_Imports_InventoryAdjustments: Reset variable in loop (S2GCA-98)
  2018/09/14  TK      pr_Imports_InventoryAdjustments, pr_Imports_ASNLPNs & pr_Imports_ASNLPNDetails:
  2018/06/07  OK      pr_Imports_InventoryAdjustments: Changes to update the Ownership of inventory on LPN adjusted (S2G-329)
  2018/01/24  RV      pr_Imports_InventoryAdjustments: Added new procedure to adjust inventory adjustments from
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_InventoryAdjustments') is not null
  drop Procedure pr_Imports_InventoryAdjustments;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_InventoryAdjustments:
    This procedure will call in a job to Adjust the inventory from CIMSDE database to CIMS database.
    This procedure gets the unprocessed records (Exchanges status as 'N') from [CIMSDE] DB and adjust the invenotry in [CIMS] DB
    with respect to the Warehouse, BusinessUnit and Ownership. Adjustments are depends upon the UpdateOption.
    UpdateOpions: + -- Add Inventory to the LPN/Location
                  - -- Reduce Inventory from the LPN/Location
                  = -- Adjust Inventory with Quantity to adjust
    Once the Inventory adjust in CIMS, Update Exchange status as 'Y'. If the inventory is unable adjust in CIMS then
    Exchange status update as 'E' (Error) and error message also update in result field in the InventoryAdjustments table
    in CIMSDE DB.
    This does not required to send exports. why because these adjustments are done in host system.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_InventoryAdjustments
  (@UserId  TUserId = 'CIMSDE')
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @vRecordId          TRecordId,
          @vInvAdjustmentId   TRecordId,
          @vSKUId             TRecordId,
          @vSKU               TSKU,
          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vLPNStatus         TStatus,
          @vLPNDetailId       TRecordId,
          @vLPNSKUId          TRecordId,
          @vLPNLocationId     TRecordId,
          @vLocationId        TRecordId,
          @vLocation          TLocation,
          @vLocationToAdjust  TLocation,
          @vLocationType      TLocationType,
          @vUpdateOption      TFlag,
          @vQuantityToAdjust  TQuantity,
          @vPrevQuantity      TQuantity,
          @vNewLPNQuantity    TQuantity,
          @vPrevInnerPacks    TQuantity,
          @vInnerPacksToAdjust
                              TQuantity,
          @vNewInnerPacks     TQuantity,
          @vReceiptNumber     TReceiptNumber,
          @vReasonCode        TReasonCode,
          @vOperation         TOperation,
          @vReference         TVarchar,
          @vAuditActivity     TActivityType,
          @vOwnership         TOwnership,
          @vWarehouse         TWarehouse,
          @vLPNOwnership      TOwnership,
          @vLPNWarehouse      TWarehouse,
          @vCreatedDateTime   TDateTime = current_timestamp,
          @vBusinessUnit      TBusinessUnit;

  declare @ttInventoryToAdjust table (RecordId          TRecordId Identity(1,1),
                                      InvAdjustmentId  TRecordId,
                                      Warehouse         TWarehouse,
                                      Location          TLocation,
                                      LPN               TLPN,
                                      SKU               TSKU,
                                      UpdateOption      TFlag,
                                      InnerPacks        TQuantity,
                                      QuantityToAdjust  TQuantity,
                                      ReceiptNumber     TReceiptNumber,
                                      ReasonCode        TReasonCode,
                                      Reference         TVarchar,
                                      Ownership         TOwnership,
                                      SortSeq           TSortSeq,
                                      BusinessUnit      TBusinessUnit,
                                      Result            TVarchar);
begin
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Get the un-processed records from the other Data Exchange DB by using synonym */
  insert into @ttInventoryToAdjust (InvAdjustmentId, Warehouse, Location, LPN, SKU, UpdateOption, InnerPacks, QuantityToAdjust,
                                    ReceiptNumber, ReasonCode, Reference, Ownership, SortSeq, BusinessUnit, Result)
    select RecordId, Warehouse, Location, LPN, SKU, UpdateOption, InnerPacks, Quantity,
           ReceiptNumber, ReasonCode, Reference, Ownership, SortSeq, BusinessUnit, Result
    from CIMSDE_ImportInvAdjustments
    where (ExchangeStatus = 'N' /* No */) and (RecordType = 'LOCADJ')
    order by SortSeq;

  /* Process each individual records untill all the records are processed */
  while (exists (select * from @ttInventoryToAdjust where RecordId > @vRecordId))
    begin
      begin try
        /* Reset the variables */
        select @vLPNId            = null,
               @vLPN              = null,
               @vLPNSKUId         = null,
               @vLPNDetailId      = null,
               @vSKUId            = null,
               @vSKU              = null,
               @vLocation         = null,
               @vQuantityToAdjust = 0,
               @vPrevQuantity     = 0,
               @vNewLPNQuantity   = 0,
               @vMessageName      = null;

        /* fetch the next record to adjust inventory */
        select top 1 @vRecordId           = RecordId,
                     @vInvAdjustmentId    = InvAdjustmentId,
                     @vWarehouse          = Warehouse,
                     @vLocationToAdjust   = Location,
                     @vLPN                = LPN,
                     @vSKU                = SKU,
                     @vUpdateOption       = UpdateOption,
                     @vInnerPacksToAdjust = InnerPacks,
                     @vQuantityToAdjust   = QuantityToAdjust,
                     @vReceiptNumber      = ReceiptNumber,
                     @vReasonCode         = ReasonCode,
                     @vReference          = Reference,
                     @vOwnership          = Ownership,
                     @vBusinessUnit       = BusinessUnit
        from @ttInventoryToAdjust
        where (RecordId > @vRecordId)
        order by RecordId;

        /* First we identify the LPN if the LPN is given */
        if (coalesce(@vLPN, '') <> '')
          select @vLPNId         = LPNId,
                 @vLPNLocationId = LocationId
          from vwLPNs
          where (LPN           = @vLPN) and
                (Status        = 'P' /* Putaway */) and
                (LPNType      <> 'L' /* Logical LPN */) and
                (BusinessUnit =  @vBusinessUnit);

        /* Identify the picklane using SKU and Location */
        if (coalesce(@vLPNId, 0) = 0) and (coalesce(@vLocationToAdjust, '') <> '')
          select @vLPNId         = LPNId,
                 @vLPNLocationId = LocationId
          from vwLPNs
          where (LPN           = @vLocationToAdjust) and
                (LPNType       = 'L' /* Logical LPN */) and
                (SKU           = @vSKU) and
                (Ownership     = @vOwnership) and
                (DestWarehouse = @vWarehouse) and
                (BusinessUnit  = @vBusinessUnit);

        /* Identify the Picklane using SKU and Warehouse if not yet identified */
        if (coalesce(@vLPNId, 0) = 0) and (coalesce(@vSKU, '') <> '') and (coalesce(@vLocationToAdjust, '') = '')
          select top 1 @vLPNId         = LPNId,
                       @vLPNLocationId = LocationId
          from vwLPNs
          where (SKU           = @vSKU) and
                (LPNType       = 'L' /* Logical LPN */) and
                (Ownership     = @vOwnership) and
                (DestWarehouse = @vWarehouse) and
                (BusinessUnit  = @vBusinessUnit);

        /* Get the Location details */
        if (coalesce(@vLocationToAdjust, '') <> '')
          select @vLocationId   = LocationId,
                 @vLocationType = LocationType
          from Locations
          where (Location     = @vLocationToAdjust) and
                (BusinessUnit = @vBusinessUnit);

        /* Get LPN and LPN Details info */
        if (coalesce(@vLPNId, 0) <> 0)
          begin
            select @vLPNWarehouse = DestWarehouse,
                   @vLPNOwnership = Ownership,
                   @vLPNStatus    = Status
            from vwLPNs
            where (LPNId = @vLPNId);

            select @vLPNSKUId          = SKUId,
                   @vPrevQuantity      = Quantity,
                   @vPrevInnerPacks    = InnerPacks
            from vwLPNDetails
            where (LPNId = @vLPNId) and
                  (SKU   = @vSKU);
          end

        /* If there is no Picklane found for specified SKU then setup new Picklane for the SKU */
        if (coalesce(@vLPNId, 0) = 0) and (coalesce(@vLocationType, '') = 'K' /* Picklane */) and (coalesce(@vLPNSKUId, 0) = 0) and (@vUpdateOption in ('+', '='))
          select @vOperation = 'AddSKUToPicklane';
        else
        if (@vLocationType in ('R'/* Reserve */, 'B'/* Bulk */)) and (coalesce(@vLPNId, 0) = 0) and (@vUpdateOption in ('+'))
          select @vOperation = 'AddSKUToLPN';
        else
          select @vOperation = 'AdjustLPNQuantity';

        /* Get the SKUId, if there is no Picklane setup against SKU */
        if (coalesce(@vSKUId, 0) = 0)
          select @vSKUId = SKUId
          from SKUs
          where (SKU          = @vSKU) and
                (BusinessUnit = @vBusinessUnit);

        if (coalesce(@vWarehouse, '') = '')
          select @vMessageName = 'ImportInvAdj_WarehouseIsRequired';
        else
        if (coalesce(@vOwnership, '') = '')
          select @vMessageName = 'ImportInvAdj_OwnershipIsRequired';
        else
        if (coalesce(@vBusinessUnit, '') = '')
          select @vMessageName = 'ImportInvAdj_BusinessUnitIsRequired';
        else
        if (coalesce(@vSKUId, 0) = 0)
          select @vMessageName = 'SKUIsInvalid';
        else
        if (coalesce(@vLPNId, 0) = 0) and (@vOperation not in ('AddSKUToPicklane', 'AddSKUToLPN'))
          select @vMessageName = 'LPNDoesNotExist';
        else
        /* There will be a case that a pickLane location which needs to be adjusted for a SKU might not be associated/configured
           to that location. In this case @vLPNWarehouse and @vLPNOwnership will be null and we need to add the SKU to that pickLane
           location and then adjust the inventory. So we need to skip both the below conditions if @vOperation = 'AddSKUToPicklane'. */
        if ((@vOperation not in ('AddSKUToPicklane', 'AddSKUToLPN')) and
            (@vLPNWarehouse <> @vWarehouse))
          select @vMessageName = 'WarehouseMismatch';
        else
        if ((@vOperation not in ('AddSKUToPicklane', 'AddSKUToLPN')) and
            (@vLPNOwnership <> @vOwnership))
          select @vMessageName = 'OwnershipMismatch';
        else
        if (@vUpdateOption not in ('+', '-', '='))
          select @vMessageName = 'ImportInvAdj_InvalidOperation';
        else
        if (coalesce(@vLPNId, 0) <> 0) and (@vLocationId <> @vLPNLocationId)
          select @vMessageName = 'ImportInvAdj_LPNDoesNotExistInLocation';
        else
        if (coalesce(@vLPNId, 0) = 0) and (@vUpdateOption = '-')
          select @vMessageName = 'ImportInvAdj_LPNDoesNotExistToReduce';
        else
        if (@vLPNId <> 0) and (@vUpdateOption = '-') and (@vPrevQuantity < @vQuantityToAdjust)
          select @vMessageName = 'ImportInvAdj_InsufficientQtyinLPN';

        if (coalesce(@vMessageName, '') <> '')
          goto ErrorHandler;

        /* Calculate the new LPN quantity for AT log */
        select @vNewLPNQuantity = case
                                    when (@vUpdateOption = '+')
                                      then (@vPrevQuantity + @vQuantityToAdjust)
                                    when (@vUpdateOption = '-')
                                      then (@vPrevQuantity - @vQuantityToAdjust)
                                    when (@vUpdateOption = '=')
                                      then @vQuantityToAdjust
                                  end,
               @vNewInnerPacks  = case
                                    when (@vUpdateOption = '+')
                                      then (@vPrevInnerPacks + @vInnerPacksToAdjust)
                                    when (@vUpdateOption = '-')
                                      then (@vPrevInnerPacks - @vInnerPacksToAdjust)
                                    when (@vUpdateOption = '=')
                                      then @vInnerPacksToAdjust
                                  end;

        if (@vOperation = 'AdjustLPNQuantity')
          begin
            /* Get the LPN Detail to adjust */
            select @vLPNDetailId = LPNDetailId
            from LPNDetails
            where (LPNId        = @vLPNId) and
                  (SKUId        = @vSKUId) and
                  (OnhandStatus = 'A' /* Available */);

            exec pr_LPNs_AdjustQty @vLPNId, @vLPNDetailId output, @vSKUId, null /* SKU */, @vInnerPacksToAdjust output,
                                   @vQuantityToAdjust output, @vUpdateOption, 'N' /* ExportOption - No */, @vReasonCode,
                                   @vReference, @vBusinessUnit, @UserId;

            /* If LPN Ownership is different than inventory then update as per the inventory adjusted */
            if (@vLPNStatus = 'N' /* New */) and (@vLPNOwnership <> @vOwnership)
              update LPNs
              set Ownership     = @vOwnership,
                  DestWarehouse = @vWarehouse
              where (LPNId = @vLPNId);
          end
        else /* If there is no SKU exists in the location to adjust then setup a picklane and adjust */
        if (@vOperation = 'AddSKUToPicklane')
          begin
            exec pr_Locations_AddSKUToPicklane @vSKUId, @vLocationId, @vInnerPacksToAdjust, @vQuantityToAdjust, null /* Lot */, @vOwnership,
                                               @vUpdateOption /* UpdateOption */, 'N' /* Export Option */,
                                               @UserId, @vReasonCode, @vLPNId output, @vLPNDetailId output;
          end
        else /* Create Inventory LPNs and Move to the Location */
        if (@vOperation = 'AddSKUToLPN')
          begin
            exec pr_LPNs_CreateInvLPN 'C'/* Carton */, @vSKUId, @vInnerPacksToAdjust, @vQuantityToAdjust, null /* CoO */, null /* PalletId */,
                                          null /* Lot */, null /* ExpiryDate */, @vOwnership, @vWarehouse, @vReasonCode, @vReference, @vBusinessUnit,
                                          @UserId, @vCreatedDateTime /* CreatedDate */, @vLPNId output, @vLPN output, @vLPNDetailId output, @vMessage output;

            /* If Inventory LPN has created successfully then Move the LPN to the desitnation location */
            if (coalesce(@vLPNId, 0) <> 0)
              begin
                update LPNs
                set LocationId   = @vLocationId,
                    OnhandStatus = 'A' /* Available */
                where LPNId = @vLPNId;

                update LPNDetails
                set OnhandStatus = 'A' /* Available */
                where LPNId = @vLPNId;

                /* Recount the LPNs to update the counts properly */
                exec pr_LPNs_Recount @vLPNId
              end
          end

        select @vAuditActivity = case
                                   when (@vOperation = 'AddSKUToPicklane') then 'AddSKUAndInventory'
                                   when (@vOperation = 'AddSKUToLPN') then 'CreateInvLPN'
                                   else 'LPNAdjustQty'
                                 end;

        exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                                  @LPNId          = @vLPNId,
                                  @SKUId          = @vSKUId,
                                  @LPNDetailId    = @vLPNDetailId,
                                  @LocationId     = @vLocationId,
                                  @InnerPacks     = @vNewInnerPacks,
                                  @Quantity       = @vNewLPNQuantity,
                                  @PrevInnerPacks = @vPrevInnerPacks,
                                  @PrevQuantity   = @vPrevQuantity,
                                  @ReasonCode     = @vReasonCode;

ErrorHandler:
        if (@vMessageName is not null)
          exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

        /* Successfully processed the adjustment, so mark the record */
        update CIMSDE_ImportInvAdjustments
        set ExchangeStatus = 'Y',
            ProcessedTime  = current_timestamp
        where (RecordId = @vInvAdjustmentId);

      end try
      begin catch
        /* There is an error in processing the record, flag the record and error message */
        update CIMSDE_ImportInvAdjustments
        set ExchangeStatus = 'E',
            Result         = Error_Message(),
            ProcessedTime  = current_timestamp
        where (RecordId = @vInvAdjustmentId);
      end catch

    end /* End of while, Process the next record */

end /* pr_Imports_InventoryAdjustments */

Go
