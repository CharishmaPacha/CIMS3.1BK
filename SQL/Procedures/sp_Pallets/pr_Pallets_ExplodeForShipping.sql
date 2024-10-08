/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/04  YJ      pr_Pallets_ExplodeForShipping: Migrated from Prod (S2GCA-98)
  2019/04/24  OK      pr_Pallets_ExplodeForShipping: introduced to explode LPNs on pallet for amazon labelling (S2GCA-634)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_ExplodeForShipping') is not null
  drop Procedure pr_Pallets_ExplodeForShipping;
Go

/*------------------------------------------------------------------------------
  Proc pr_Pallets_ExplodeForShipping:
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_ExplodeForShipping
  (@PalletId         TRecordId,
   @Pallet           TPallet,
   @PalletsToExplode TEntityKeysTable readonly,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vRecordId            TRecordId,
          @vPalletId            TRecordId,
          @vPallet              TPallet,
          @vOwnership           TOwnership,
          @vWarehouse           TWarehouse,
          @xmlRulesData         TXML,
          @vIsPalletExplodeRequired
                                TControlValue;

declare @ttPalletsToExplode     TEntityKeysTable,
        @ttLPNsToExportToPanda  TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode = 0,
         @vRecordId   = 0;

  /* Get the pallets to be process */
  if (exists (select * from @PalletsToExplode)) /* If caller passed list of Pallets to explode */
    insert into @ttPalletsToExplode (EntityId, EntityKey)
      select EntityId, Entitykey
      from @ttPalletsToExplode;
  else
    /* If user passed specific pallet then process that pallet only else process all the unprocessed pallets */
    insert into @ttPalletsToExplode (EntityId, EntityKey)
      select @PalletId, @Pallet

  /* Loop through all the pallets */
  while exists (select * from @ttPalletsToExplode where RecordId > @vRecordId)
    begin
      /* get the top pallet to process */
      select top 1 @vPalletId  = TP.EntityId,
                   @vRecordId  = TP.RecordId,
                   @vOwnership = P.Ownership,
                   @vWarehouse = P.Warehouse
      from @ttPalletsToExplode TP
        join Pallets P on (P.Pallet = TP.EntityKey)
      where (TP.RecordId > @vRecordId)
      order by TP.RecordId;

      /* Verify if Pallet is needs to be exploded or not through rules */
      /* Build the data for rule evaluation */
      select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                             dbo.fn_XMLNode('Entity',       'Pallet'   ) +
                             dbo.fn_XMLNode('PalletId',     @vPalletId ) +
                             dbo.fn_XMLNode('Ownership',    @vOwnership) +
                             dbo.fn_XMLNode('Warehouse',    @vWarehouse) +
                             dbo.fn_XMLNode('Operation',    @Operation ));

      exec pr_RuleSets_Evaluate 'OnShipping_ExplodeLPN', @xmlRulesData, @vIsPalletExplodeRequired output;

      /* If Exploding is required for the pallet then explod here. This will explode each innerpack into one LPN */
      if (@vIsPalletExplodeRequired = 'Y' /* Yes */)
        exec pr_LPNs_ExplodeLPNs null /* LPNId */, default /* ttLPNs */,
                                 @vPalletId, null /* OrderId */, null /* Options */,
                                 @BusinessUnit, @UserId;

      /* Get all the LPNs on the Pallet to insert into the PandaLabels table to process in PandA */
      insert into @ttLPNsToExportToPanda(EntityId, EntityKey)
        select LPNId, LPN
        from LPNs
        where (PalletId = @vPalletId);

      /* Generate UCC Barcodes for LPNs that require it */
      exec pr_LPNs_SetUCCBarcode null /* LPNId */, @ttLPNsToExportToPanda, null /* Order Id */, @xmlRulesData /* xmlRulesdata */,
                                 @BusinessUnit, @UserId;

      /* delete the records from the temp table or else system will send the duplicate records to DCMS */
      delete from @ttLPNsToExportToPanda;
    end
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_ExplodeForShipping */

Go
