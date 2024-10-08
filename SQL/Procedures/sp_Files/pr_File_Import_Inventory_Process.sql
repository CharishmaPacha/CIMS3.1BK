/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  TK      pr_File_Import_Inventory_Process: Trim trailing spaces for inventory class (HA-GoLive)
  2021/03/19  TK      pr_File_Import_Inventory_Process: Bug fix to update pallet info on the LPNs that are created in the run (HA-2341)
  2021/03/15  RKC/TK  pr_File_Import_Inventory_Process: Made changes to update the pallet & locations on the newly created LPNs (HA-2285)
  2021/03/13  RKC     pr_File_Import_Inventory_Process: Made changes to get the correct values (HA-2276)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_File_Import_Inventory_Process') is not null
  drop Procedure pr_File_Import_Inventory_Process;
Go
/*------------------------------------------------------------------------------
  Proc pr_File_Import_Inventory_Process: Procedure to process the data for Import
    Inventory file type import.
------------------------------------------------------------------------------*/
Create Procedure pr_File_Import_Inventory_Process
  (@TempTableName    TName,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vOwnership               TOwnership,
          @vSQL                     TSQL,
          @vRecordId                TRecordId,
          /* Pallet */
          @vNumPalletsToCreate      TCount,
          @vFirstPalletId           TRecordId,
          @vFirstPallet             TPallet,
          @vLastPalletId            TRecordId,
          @vLastPallet              TPallet,
          /* LPNs */
          @vFirstLPNId              TRecordId,
          @vLastLPNId               TRecordId,
          @vFirstLPN                TLPN,
          @vLastLPN                 TLPN,
          @vLPNId                   TRecordId,
          @vLPN                     TLPN,

          @vNumCartons              TCount,
          @vInputXML                TXML,
          @vOutputXML               TXML,
          @vXMLOutPut               xml,
          @vxmlInput                xml;

  declare @ttSelectedEntities       TEntityValuesTable,
          @ttSelectedEntityKeys     TEntityKeysTable,
          @ttLPNsCreated            TEntityKeysTable,
          @ttPalletsCreated         TRecountKeysTable,
          @ttLocations              TRecountKeysTable,
          @ttResultMessages         TResultMessagesTable,
          @ttResultData             TNameValuePairs,
          @ttLPNsToCreate           TLPNDetails,
          @ttCreateLPNDetails       TLPNDetails;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Create temp tables */
  select * into #ttSelectedEntities from @ttSelectedEntities;
  select * into #ResultMessages     from @ttResultMessages;      -- to hold the results of the action
  select * into #ResultData         from @ttResultData;          -- to hold the data to be returned to UI
  select * into #LPNsCreated        from @ttLPNsCreated;
  select * into #PalletsCreated     from @ttPalletsCreated;
  select * into #LPNsToCreate       from @ttLPNsToCreate;
  select * into #CreateLPNDetails   from @ttCreateLPNDetails;

  /* Get default Ownership */
  select @vOwnership = LookUpCode from LookUps where LookUpCategory = 'Owner' and BusinessUnit = @BusinessUnit;

  /* Populate the given data into temp table for manipulation before import */
  create table #ImportInv (InvRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable @TempTableName, '#ImportInv';

  select @vSQL = 'insert into #ImportInv select * from ' + @TempTableName + ' where SKU is not null and Validated = ''Y''';

  /* Execute the dynamic SQL to create inventory for the SKUs given in the import file */
  exec sp_executesql @vSQL;

  /* Added required column to the table */
  alter table #ImportInv add LPNId  int,
                             LPN    varchar(100);

  /* Prepare the required data */
  update #ImportInv
  set NumLPNsToCreate = coalesce(NumLPNsToCreate, 1),
      Location        = case when Warehouse = '60' then 'INTRANSIT-' + Location else Location end;

  /* Fetch details of LPNs to be created */
  insert into #LPNsToCreate (InventoryClass1, Ownership, Warehouse, InputRecordId)
    select II.InventoryClass1, @vOwnership, II.Warehouse, II.RecordId
    from #ImportInv II
      cross apply dbo.fn_GenerateSequence(1, II.NumLPNsToCreate , null); -- execute select statements as many as number of cartons to create

  /* Get the num cartons to be generated */
  select @vNumCartons = count(*) from #LPNsToCreate;

  /* Generate required number of Ship Cartons */
  exec pr_LPNs_Generate 'C' /* LPNType */, @vNumCartons, null /* @LPNFormat */, null /* Warehouse */,
                        @BusinessUnit, @UserId,
                        @vFirstLPNId out, @vFirstLPN out,
                        @vLastLPNId out, @vLastLPN out;

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
                                 Quantity, Warehouse, BusinessUnit, CreatedBy)
    select LTC.LPNId, LTC.LPN, II.SKUId,
           /* OnhandStatus */
           case when II.Warehouse = '60' then 'A' /* Available */ else 'U' /* Unavailable */ end,
           II.UnitsPerLPN, II.Warehouse, @BusinessUnit, @UserId
    from #ImportInv II
      join #LPNsToCreate LTC on (II.RecordId = LTC.InputRecordId);

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
      UDF4            = coalesce(II.ShipmentDate, ''),
      Reference       = rtrim(II.Reference),
      ReasonCode      = coalesce(nullif(II.ReasonCode, ''), 'WCC')
  from LPNs L
    join #LPNsToCreate LTC on (L.LPNId = LTC.LPNId)
    join #ImportInv II on (LTC.InputRecordId = II.RecordId)
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

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_File_Import_Inventory_Process */

Go
