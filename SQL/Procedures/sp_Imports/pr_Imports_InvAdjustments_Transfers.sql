/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  TK      pr_Imports_InvAdjustments_Transfers: Trim trailing spaces for inventory class (HA-GoLive)
                      pr_Imports_InvAdjustments_Transfers: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_InvAdjustments_Transfers') is not null
  drop Procedure pr_Imports_InvAdjustments_Transfers;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_InvAdjustments_Transfers: This procedure imports the inventory from the input xml
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_InvAdjustments_Transfers
  (@RecordType                TRecordType,
   @DocumentHandle            TInteger        = null,
   @BusinessUnit              TBusinessUnit   = null,
   @UserId                    TUserId         = null)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vNumPalletsToCreate      TCount,
          @vFirstPalletId           TRecordId,
          @vFirstPallet             TPallet,
          @vLastPalletId            TRecordId,
          @vLastPallet              TPallet,

          @vNumLPNsToCreate         TCount,
          @vFirstLPNId              TRecordId,
          @vLastLPNId               TRecordId,
          @vFirstLPN                TLPN,
          @vLastLPN                 TLPN;

  declare @ttLPNsCreated                TEntityKeysTable,
          @ttPalletsCreated             TRecountKeysTable,
          @ttLocations                  TRecountKeysTable,
          @ttLPNsToCreate               TLPNDetails,
          @ttCreateLPNDetails           TLPNDetails,
          @ttInvAdjustmentValidations   TImportValidationType;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @UserId       = coalesce(@UserId, system_user);

  /* Create temp tables */
  select * into #LPNsCreated        from @ttLPNsCreated;
  select * into #PalletsCreated     from @ttPalletsCreated;
  select * into #LPNsToCreate       from @ttLPNsToCreate;
  select * into #CreateLPNDetails   from @ttCreateLPNDetails;

  /* Populate the given data into temp table for manipulation before import */
  create table #ImportInv (InvRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'TImportInvAdjustments', '#ImportInv';

  /* Added required column to the table */
  alter table #ImportInv add NumLPNsToCreate  int,
                             ExchangeStatus   varchar(2);

  /* If DocumentHandle is null then retrun */
  if (@DocumentHandle is not null)
    begin
      /* insert into Hash Table to process the xml */
      insert into #ImportInv (RecordType, Warehouse, Location, LPN, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
                              InventoryClass1, InventoryClass2, InventoryClass3, UpdateOption, InnerPacks, Quantity,
                              ReceiptNumber, ReasonCode, TransactionDateTime, Reference, Ownership, SortSeq,
                              UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, BusinessUnit, CIMSRecId)
      select *
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="TRFINV"]', 2) -- condition forces to read only Records with RecordType TRFINV
      with (RecordType                    TRecordType,
            Warehouse                     TWarehouse,
            Location                      TLocation,
            LPN                           TLPN,
            SKU                           TSKU,
            SKU1                          TSKU,
            SKU2                          TSKU,
            SKU3                          TSKU,
            SKU4                          TSKU,
            SKU5                          TSKU,
            InventoryClass1               TInventoryClass,
            InventoryClass2               TInventoryClass,
            InventoryClass3               TInventoryClass,

            UpdateOption                  TFlag,
            InnerPacks                    TInnerPacks,
            Quantity                      TQuantity,

            ReceiptNumber                 TReceiptNumber,
            ReasonCode                    TReasonCode,

            TransactionDateTime           TDateTime,
            Reference                     TVarchar,
            Ownership                     TOwnership,
            SortSeq                       TSortSeq,

            UDF1                          TUDF,
            UDF2                          TUDF,
            UDF3                          TUDF,
            UDF4                          TUDF,
            UDF5                          TUDF,
            UDF6                          TUDF,
            UDF7                          TUDF,
            UDF8                          TUDF,
            UDF9                          TUDF,
            UDF10                         TUDF,

            BusinessUnit                  TBusinessUnit,
            RecordId                      TRecordId);
    end
  else
    begin
      insert into #ImportInv (RecordType, Warehouse, Location, LPN, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
                              InventoryClass1, InventoryClass2, InventoryClass3, UpdateOption, InnerPacks, Quantity,
                              ReceiptNumber, ReasonCode, TransactionDateTime, Reference, Ownership, SortSeq,
                              UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, ExchangeStatus, BusinessUnit, CIMSRecId)
        select RecordType, Warehouse, Location, LPN, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
               InventoryClass1, InventoryClass2, InventoryClass3, UpdateOption, InnerPacks, Quantity,
               ReceiptNumber, coalesce(nullif(ReasonCode, ''), 'WCC'), TransactionDateTime, Reference, Ownership, SortSeq,
               UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10, ExchangeStatus, BusinessUnit, RecordId
        from CIMSDE_ImportInvAdjustments
        where (RecordType = 'TRFINV') and
              (ExchangeStatus = 'N');
    end

  /* Validations */
  update II
  set ExchangeStatus = 'E' /* Erorr */,
      Result         = dbo.fn_Imports_AppendError(Result, 'SKUDoesNotExist', II.SKU)
  from #ImportInv II
    left outer join SKUs S on (II.SKU = S.SKU) and
                              (II.BusinessUnit = S.BusinessUnit)
  where (S.SKUId is null);

  /* Prepare the required data */
  update #ImportInv
  set NumLPNsToCreate = coalesce(NumLPNsToCreate, 1),
      Location        = case when Warehouse = '60' then 'INTRANSIT-' + Location else Location end;

  /* Load the details of LPNs to be created */
  insert into #LPNsToCreate (InventoryClass1, Ownership, Warehouse, InputRecordId)
    select II.InventoryClass1, II.Ownership, II.Warehouse, II.InvRecordId
    from #ImportInv II
      cross apply dbo.fn_GenerateSequence(1, II.NumLPNsToCreate , null)
    where II.ExchangeStatus = 'N'; -- execute select statements as many as number of cartons to create

  /* Get the num cartons to be generated */
  select @vNumLPNsToCreate = count(*) from #LPNsToCreate;

  /* Generate required number of Ship Cartons */
  exec pr_LPNs_Generate 'C' /* LPNType */, @vNumLPNsToCreate, null /* @LPNFormat */, null /* Warehouse */,
                        @BusinessUnit, @UserId,
                        @vFirstLPNId out, @vFirstLPN out, @vLastLPNId out, @vLastLPN out;

  /* Get all the LPNs that are generated above */
  insert into #LPNsCreated (EntityId, EntityKey)
    select LPNId, LPN
    from LPNs
    where (LPNId between @vFirstLPNId and @vLastLPNId) and
          (LPNType      = 'C' /* Carton */) and
          (BusinessUnit = @BusinessUnit)  and
          (CreatedBy    = @UserId)
    order by LPN;

  /* Assign each LPN to a carton recordId */
  update LTC
  set LTC.LPNId = L.EntityId,
      LTC.LPN   = L.EntityKey
  from #LPNsToCreate LTC
    join #LPNsCreated L on (LTC.RecordId = L.RecordId);

  /* Add details to all cartons created above */
  insert into #CreateLPNDetails (LPNId, LPN, SKUId, OnhandStatus,
                                 Quantity, Warehouse, Ownership, BusinessUnit, CreatedBy)
    select LTC.LPNId, LTC.LPN, S.SKUId,
           /* OnhandStatus */
           case when II.Warehouse = '60' then 'A' /* Available */ else 'U' /* Unavailable */ end,
           II.Quantity, II.Warehouse, II.Ownership, @BusinessUnit, @UserId
    from #ImportInv II
      join #LPNsToCreate LTC on (II.InvRecordId = LTC.InputRecordId)
      join SKUs S on (II.SKU = S.SKU) and (II.BusinessUnit = S.BusinessUnit);

  /* If there exists records in CreateLPNDetails then just invoke CreateLPNs procedure
     which will create/insert Details for generated ship cartons */
  if exists (select * from #CreateLPNDetails)
    exec pr_LPNs_CreateLPNs;

  /* Update necessary fields and Parse reference field Trailer#.LotRef.Pallet.ShipmentDate */
  update L
  set LocationId      = LOC.LocationId,
      Location        = LOC.Location,
      Ownership       = LTC.Ownership,
      DestWarehouse   = LTC.Warehouse,
      InventoryClass1 = rtrim(LTC.InventoryClass1),
      UDF1            = dbo.fn_SubstringBetweenSeparator(rtrim(II.Reference), '.', 0, 1),
      UDF2            = dbo.fn_SubstringBetweenSeparator(rtrim(II.Reference), '.', 1, 2),
      UDF3            = dbo.fn_SubstringBetweenSeparator(II.Reference, '.', 2, 3),
      UDF4            = cast(coalesce(II.TransactionDateTime, '') as date),
      Reference       = rtrim(II.Reference),
      ReasonCode      = II.ReasonCode
  from LPNs L
    join #LPNsToCreate LTC on (L.LPNId = LTC.LPNId)
    join #ImportInv II on (LTC.InputRecordId = II.InvRecordId)
    left outer join Locations LOC on (II.Location     = LOC.Location) and
                                     (II.BusinessUnit = LOC.BusinessUnit)

  /* Get the Number of pallets to create counts based on the distinct Pallet info from the #ImportInv table */
  select @vNumPalletsToCreate = count(distinct L.Reference + L.UDF4)
  from LPNs L
    join #LPNsToCreate LTC on (L.LPNId = LTC.LPNId)

  /* Generate Pallets */
  if (@vNumPalletsToCreate > 0 )
    begin
      exec pr_Pallets_GeneratePalletLPNs 'I' /* Inventory */, @vNumPalletsToCreate, null /* PalletFormat */,
                                         0 /* LPNsPerPallet */, null /* LPN Type */, null /* LPN Format */,
                                         '04', @BusinessUnit, @UserId,
                                         @FirstPalletId = @vFirstPalletId output, @FirstPallet = @vFirstPallet output,
                                         @LastPalletId = @vLastPalletId output, @LastPallet = @vLastPallet output;

      /* Capture pallets generated to palletize LPNs */
      insert into #PalletsCreated (EntityId, EntityKey)
        select PalletId, Pallet
        from Pallets
        where (PalletId between @vFirstPalletId and @vLastPalletId) and
              (PalletType   = 'I' /* Inventory */) and
              (BusinessUnit = @BusinessUnit) and
              (CreatedBy    = @UserId);
    end

  /* Update pallet info on the created LPNs */
  ;with LPNsGrouping as
  (
    select L.Reference, L.UDF4,
           row_number() over(order by L.Reference, L.UDF4) as PalletRecordId
    from LPNs L
      join #LPNsToCreate LTC on (L.LPNId = LTC.LPNId)
    group by L.Reference, L.UDF4
  )
  update L
  set PalletId = P.EntityId,
      Pallet   = P.EntityKey
  from LPNs L
    join #LPNsToCreate   LTC on (L.LPNId = LTC.LPNId)
    join LPNsGrouping    LG  on (L.Reference = LG.Reference) and
                                (L.UDF4 = LG.UDF4)
    join #PalletsCreated P   on (LG.PalletRecordId = P.RecordId)

  /*------------- Recalc Pallets -------------*/
  if exists (select * from #PalletsCreated)
    begin
      /* Get all the Pallets to Recount */
      insert into @ttPalletsCreated (EntityId, EntityKey) select EntityId, EntityKey from #PalletsCreated;
      exec pr_Pallets_Recalculate @ttPalletsCreated, default, @BusinessUnit, @UserId;
    end

  /*------------- Recalc Locations  -------------*/
  insert into @ttLocations (EntityId, EntityKey)
    select distinct L.LocationId, L.Location
    from LPNs L
      join #LPNsToCreate LTC on (L.LPNId = LTC.LPNId);

  if exists (select * from @ttLocations)
    exec pr_Locations_Recalculate @ttLocations, '*' /* Recount */, @BusinessUnit;

  /* Successfully processed the adjustment, so mark the record */
  update IIA
  set ExchangeStatus = case when II.Result is not null then 'E' /* Error */ else 'Y' /* Processed */ end,
      Result         = II.Result,
      ProcessedTime  = current_timestamp
  from CIMSDE_ImportInvAdjustments IIA
    join #ImportInv II on (IIA.RecordId = II.CIMSRecId);

ExitHandler:
  return(coalesce(@vReturnCode, 0));

end /* pr_Imports_InvAdjustments_Transfers */

Go
