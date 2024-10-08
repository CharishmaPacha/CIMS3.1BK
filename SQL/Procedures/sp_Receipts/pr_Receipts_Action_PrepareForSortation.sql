/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/09  MS      pr_Receipts_Action_PrepareForSortation: Code optimized and cleanup (JL-286, JL-287)
                      pr_Receipts_Action_ActivateRouting: Changes to create receivers (JL-286, JL-287)
                      pr_Receipts_CreateReceivers: Added new proc to create receivers for given LPNs (JL-286, JL-287)
                      pr_Receipts_UnPalletize: Corrections to send RouteLPN aswell, to be in consistent with #RouterLPNs activated earlier
                      pr_ReceivedCounts_AddOrUpdate: Changes to update ReceiverNumber on existing ReceivedCounts (JL-286, JL-287)
  2020/09/13  MS      Renamed pr_Receipts_PrepareForSortation as pr_Receipts_Action_PrepareForSortation
                      pr_Receipt_Actions_PrepareForSortation, pr_Receipts_UnPalletize: Enhanced changes to consider ReceiptDetails for Sortation (JL-236)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_Action_PrepareForSortation') is not null
  drop Procedure pr_Receipts_Action_PrepareForSortation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_Action_PrepareForSortation:
    This proc will get all in transit LPNs of selected Receipt OR ReceiptDetails
    and then palletize & sort those LPNs on selected Lanes

  PalletGroup: Is an indicator on each LPN to determine how they have to be palletized.
    All LPNs on a particular Pallet would always have the same PalletGroup. So, if
    we intend to have only Solid SKU Pallets, then PalletGroup would be SKU.
    If we can have multiple sizes but not Styles on a Pallet, then PalletGroup would
    be Style.

  @xmlData
    <Root>
      <Entity>Receipt</Entity>
      <Action>Receipts_PrepareforSorting</Action>
      <SelectedRecords>
        <RecordDetails><EntityId>32</EntityId><EntityKey>2266</EntityKey></RecordDetails>
      </SelectedRecords>
      <Data>
        <Lane>L02,L03,L04</Lane>
        <PalletSize>RS</PalletSize>
        <SendRI>Y</SendRI>
      </Data>
      <SessionInfo>
        <UserId>cimsadmin</UserId>
        <BusinessUnit>JL</BusinessUnit>
      </SessionInfo>
    </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_Action_PrepareForSortation
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vRecordId           TRecordId,
          @vDebug              TFlags,

          @vEntity             TEntity,
          @vAction             TAction,
          /* Pallets Info */
          @vFirstPalletId      TRecordId,
          @vLastPalletId       TRecordId,
          @vPalletType         TTypeCode,
          @vPalletFormat       TDescription,
          @vPalletVolume       TFloat,
          @vStdLPNsPerPallet   TCount,
          @vNumPalletToCreate  TCount,
          /* Inputs */
          @vPalletSize         TDescription,
          @vLanes              TDescription,
          @vActivateRI         TFlag,
          /* Others */
          @vControlCategory    TCategory,
          @vTotalRecords       TCount,
          @vRecordsProcessed   TCount,

          @vxmlRulesData       TXml;

  declare @ttEntityKeys        TEntityKeysTable;
  declare @ttEntityValues      TEntityValuesTable;

  declare @ttLPNstoSort table(RecordId      TRecordId identity (1,1),
                              ReceiptId     TRecordId,
                              LPNId         TRecordId,
                              PalletId      TRecordId,
                              Pallet        TPallet,
                              SKUId         TRecordId,
                              SKU           TSKU,
                              InnerPacks    TInnerPacks,
                              Quantity      TQuantity,
                              CartonVolume  TFloat,
                              SumVolume     TFloat,

                              PalletGroup   TCategory,
                              PalletNumber  TInteger,
                              Palletized    TFlag,
                              Processed     TFlag,
                              SeqIndex      TInteger)

  declare @ttPalletGroups table (RecordId            TRecordId identity (1,1),
                                 PalletGroup         TCategory,

                                 SKUId               TRecordId,
                                 SKU                 TSKU,
                                 PalletTie           TInteger,
                                 PalletHigh          TInteger,
                                 NumLPNsPerPallet    TCount,
                                 NumLPNsInGroup      TCount,
                                 NumPalletsPerGroup  TCount,
                                 TotalCartonVolume   TFloat,
                                 PalletTieHigh       TFlag,
                                 PalletVolume        TFloat,
                                 Processed           TFlag);

  declare @ttLanes table (RecordId    TRecordId identity(1,1),
                          Lane        TLocation,
                          MaxPallets  TInteger,
                          LaneId      TRecordId,
                          Status      TFlags); -- E Enabled, F - Full, D - Disabled

begin /* pr_Receipts_Action_PrepareForSortation */

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  /* Create temp tables */
  select * into #Receipts       from @ttEntityKeys;
  select * into #ReceiptDetails from @ttEntityKeys;
  select * into #LPNsInTransit  from @ttEntityValues;
  select * into #LPNsToSort     from @ttLPNsToSort;
  select * into #PalletGroups   from @ttPalletGroups;
  select * into #Pallets        from @ttEntityValues;
  select * into #Lanes          from @ttLanes;

  /* Get required info from Xml */
  select @vEntity     = Record.Col.value('Entity[1]',             'TEntity'),
         @vAction     = Record.Col.value('Action[1]',             'TAction'),
         @vPalletSize = Record.Col.value('(Data/PalletSize)[1]',  'TDescription'),
         @vLanes      = Record.Col.value('(Data/Lanes)[1]',       'TDescription'),
         @vActivateRI = Record.Col.value('(Data/ActivateRI)[1]',  'TFlag')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  select @vControlCategory = 'Pallet_' + @vPalletSize;

  /* Get the PalletVolume & StdLPNsPerPallet */
  select @vPalletVolume     = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'PalletVolume', '80' /* default */, @BusinessUnit, @UserId),
         @vStdLPNsPerPallet = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'StdLPNsPerPallet', '50' /* default */, @BusinessUnit, @UserId);

  /* Buildxml to use in Rules */
  select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Entity',            @vEntity) +
                            dbo.fn_XMLNode('PalletVolume',      @vPalletVolume * 1728 /* into Cuin */) +
                            dbo.fn_XMLNode('StdLPNsPerPallet',  @vStdLPNsPerPallet) +
                            dbo.fn_XMLNode('Lanes',             @vLanes) +
                            dbo.fn_XMLNode('BusinessUnit',      @BusinessUnit) +
                            dbo.fn_XMLNode('UserId',            @UserId));

  /* Get the total count of selected records from #ttSelectedEntities */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Users could sort from RH or RD views, so select the associated LPNs based upon the Entity */
  if (@vEntity = 'Receipt')
    begin
      /* Insert all InTransit LPNs of the selected Receipts */
      insert into #LPNsInTransit (RecordId, EntityId, EntityKey, UDF1)
        select row_number() over (order by L.LPNId) , min(L.LPNId), min(L.LPN), min(L.ReceiptId)
        from LPNs L
          join #ttSelectedEntities SE on (L.ReceiptId = SE.EntityId)
        where (L.Status = 'T' /* InTransit*/)
        group by L.LPNId, L.LPN

      /* Get all the selected Receipt Details to update SortStatus later(If required) */
      insert into #ReceiptDetails (EntityId, EntityKey) -- ReceiptDetailId, ReceiptId
        select distinct LD.ReceiptDetailId, LT.UDF1
        from #LPNsInTransit LT join LPNDetails LD on (LT.EntityId = LD.LPNId);

      /* Get all the Receipts which are ready to process, to know how many receipts are
         eligible among selected receipts, also  use it to get all Lanes of the receipt later */
      insert into #Receipts (EntityId) select distinct UDF1 from #LPNsInTransit;

      /* Get how many receipts are eligible to process for Sortation */
      select @vRecordsProcessed = @@rowcount;
    end
  else
  if (@vEntity = 'ReceiptDetails')
    begin
      /* Insert all InTransit LPNs of the selected Receipt Details - Sortation by Receipt Details
         would only work when an LPN has only one line */
      insert into #LPNsInTransit (RecordId, EntityId, EntityKey, UDF1, UDF2)
        select row_number() over (order by L.LPNId), min(L.LPNId), min(L.LPN), min(L.ReceiptId), min(LD.ReceiptDetailId)
        from LPNs L
          join LPNDetails          LD on (L.LPNId            = LD.LPNId)
          join #ttSelectedEntities SE on (LD.ReceiptDetailId = SE.EntityId)
        where (L.Status   = 'T' /* InTransit*/) and
              (L.NumLines = 1)
        group by L.LPNId, L.LPN;

      /* Get all the selected Receipts and use it to get all Lanes of the receipt later */
      insert into #Receipts (EntityId) select distinct UDF1 from #LPNsInTransit;

      /* Get all the selected Receipt Details to know how many records are eligible
         among selected records and also to update SortStatus aswell later(If required) */
      insert into #ReceiptDetails (EntityId, EntityKey) -- ReceiptDetailId, ReceiptId
        select distinct UDF2, UDF1 from #LPNsInTransit;

      /* Get how many receiptdetails are eligible to process for Sortation */
      select @vRecordsProcessed = @@rowcount;
    end

  if (charindex('D' /* Display */, @vDebug) > 0) select '#LPNsInTransit', * from #LPNsInTransit

  /* UnPalletize & Make it ready the LPNs for Palletization only if those are in InTransit else raise error */
  if exists (select * from #LPNsInTransit)
    exec pr_Receipts_UnPalletize @BusinessUnit, @UserId;
  else
    set @vMessageName = 'Receipt_NoLPNsInTransit';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /*********************** Palletization **********************/

  /* The Palletization rules determine the LPNsToSort, the PalletGroups and segregate the
     LPNs in each group with a SeqIndex. So, in each group we may have LPNs with SeqIndex
     of 1, 2, 3... and we would create a pallet for each index. The result of the
     palletizaton process would be populating #LPNsToSort and #PalletGroups */
  exec pr_RuleSets_ExecuteAllRules 'PalletizationUpdates', @vxmlRulesData, @BusinessUnit;

  /* Calculate the total number of Pallets to Create for each Pallet Group */
  with PalletGroupMaxNumber (PalletGroup, MaxPalletNumber) as
  (
   select PalletGroup, max(PalletNumber) from #LPNsToSort group by PalletGroup
  )
  update PG
  set NumPalletsPerGroup = PGMN.MaxPalletNumber
  from #PalletGroups PG join PalletGroupMaxNumber PGMN on (PG.PalletGroup = PGMN.PalletGroup);

  select @vNumPalletToCreate = sum(NumPalletsPerGroup) from #PalletGroups;

  /*------ Create required number of Pallets -------*/
  if (@vNumPalletToCreate > 0)
    begin
      exec @vReturnCode = pr_Pallets_GeneratePalletLPNs 'I'                  /* PalletType */,
                                                        @vNumPalletToCreate  /* NumPalletsToCreate */,
                                                        null                 /* PalletFormat */,
                                                        0                    /* NUMLPNs */ ,
                                                        null                 /* LPNType */,
                                                        null                 /* LPNFormat */ ,
                                                        null                 /* DestWarehouse */,
                                                        @BusinessUnit        /* BusinessUnit */,
                                                        @UserId              /* UserId */,
                                                        @vFirstPalletId output,
                                                        null                 /* FirstPallet */,
                                                        @vLastPalletId output,
                                                        null                 /* LastPallet */,
                                                        null;
    end

  /* Insert all created Pallets into a #temp table, we will later update UDF1 with Lane */
  insert into #Pallets (RecordId, EntityId, EntityKey)
    select row_number() over (order by PalletId), PalletId, Pallet
    from Pallets
    where PalletId between @vFirstPalletId and @vLastPalletId;

  /* Establish record ids for each pallet needed */
  select PalletGroup, PalletNumber, row_number() over (order by PalletGroup, PalletNumber) as PalletRecordId
  into #PalletNumbers
  from #LPNsToSort
  group by PalletGroup, PalletNumber;

  /* Update PalletId & PalletNumber on #LPNsToSort table */
  update LTS
  set PalletId = P.EntityId,
      Pallet   = P.EntityKey
  from #LPNsToSort LTS join #PalletNumbers PN on (LTS.PalletGroup = PN.PalletGroup) and (LTS.PalletNumber = PN.PalletNumber)
    join #Pallets P on (P.RecordId = PN.PalletRecordId);

  /* Update PalletId & PalletNumber on LPNs */
  update L
  set PalletId = LTS.PalletId,
      Pallet   = LTS.Pallet
  from LPNs L join #LPNsToSort LTS on (L.LPNId = LTS.LPNId);

  if (charindex('D', @vDebug) > 0)
    begin
      select '#LPNsToSort', PalletGroup, SeqIndex, SumVolume, PalletNumber, * from #LPNsToSort order by 1, 2;
      select '#PalletGroups', *  from #PalletGroups;
      select '#Pallets', *       from #Pallets;
      select '#PalletNumbers', * from #PalletNumbers;
    end;

  /* Prepare temp table to recount all pallets */
  insert into @ttEntityKeys (EntityId, EntityKey)
    select EntityId, EntityKey from #Pallets;

  /* Recount all Pallets */
  exec pr_Pallets_Recount @ttEntityKeys, @BusinessUnit, @UserId;

  /*********************** Sortation **********************/

  /* Get selected lanes into a table */
  insert into #Lanes (Lane, Status) select Value, 'D' from fn_ConvertStringToDataSet(@vLanes, ',');

  /* Location.Max Pallets determines pallets to be sorted to those lanes */
  update LN
  set LN.MaxPallets = LOC.MaxPallets
  from #Lanes LN join Locations LOC on (LN.Lane = LOC.Location) and (LOC.BusinessUnit = @BusinessUnit);

  /* The RecvSortation rules sort the Pallets to given Lanes, depending upon the defined rules */
  exec pr_RuleSets_ExecuteAllRules 'RecvSortation_Updates', @vxmlRulesData, @BusinessUnit;

  /*********************** Summarize Lanes Info **********************/
  select distinct LD.ReceiptId, LD.ReceiptDetailId, L.DestLocation
  into #LanesInfo
  from LPNs L
    join LPNDetails LD on (LD.LPNId   = L.LPNId)
    join #Receipts  R  on (R.EntityId = L.ReceiptId)
  where (L.Status in ('T' /* InTransit */, 'R' /* Received */)) and
        (coalesce(L.DestLocation, '') <> ''); -- Get only if DestLocation exists on LPN

  /*------- ReceiptDetails: Update Lanes info on ReceiptDetails ------*/
  ;with LanesInfo (ReceiptDetailId, Lanes) as
  (
    select LI.ReceiptdetailId,
           DestLocations = stuff((select N', ' + LIF.DestLocation
                                  from #LanesInfo LIF
                                  where (LIF.ReceiptdetailId = LI.ReceiptdetailId)
                                  group by LIF.DestLocation
                                  order by LIF.DestLocation
                                  for XML path, type).value(N'.[1]', N'nvarchar(max)'), 1, 2, N'')
    from #LanesInfo LI
    group by LI.ReceiptdetailId
  )
  update RD
  set RD.SortLanes   = LI.Lanes,
      RD.SortOptions = @vPalletSize
  from ReceiptDetails RD
    join LanesInfo LI on (RD.ReceiptDetailId = LI.ReceiptDetailId);

  /*------- ReceiptHeaders: Update Lanes info on ReceiptHeaders ------*/
  ;with LanesInfo (ReceiptId, Lanes) as
  (
   select LI.ReceiptId,
          DestLocations = stuff((select N', ' + LIF.DestLocation
                                 from #LanesInfo LIF
                                 where (LIF.ReceiptId = LI.ReceiptId)
                                 group by LIF.DestLocation
                                 order by LIF.DestLocation
                                 for XML path, type).value(N'.[1]', N'nvarchar(max)'), 1, 2, N'')
   from #LanesInfo LI
   group by LI.ReceiptId
  )
  update RH
  set RH.SortLanes   = LI.Lanes,
      RH.SortOptions = @vPalletSize
  from ReceiptHeaders RH
    join LanesInfo LI on (RH.ReceiptId = LI.ReceiptId);

  if (charindex('D', @vDebug) > 0)
    begin
      select 'Lanes',        * from #Lanes;
      select 'LanesInfo',    * from #LanesInfo;
      select 'PalletGroups', * from #PalletGroups;
      select 'Pallets',      * from #Pallets;
    end;

  /* Display msg in UI, if process completed successfully */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsProcessed, @vTotalRecords;

  /*********************** Routing **********************/
  /* If atleast one record is processed and If users wants to Activate RI aswell,
     then activate else notify to use ActivateForRouting */
  if (@vRecordsProcessed > 0) and (@vActivateRI = 'Y')
    exec pr_Receipts_Action_ActivateRouting @xmlData, @BusinessUnit, @UserId, null;
  else
  if (@vRecordsProcessed > 0) and (coalesce(@vActivateRI, '') <> 'Y')
    insert into #ResultMessages (MessageType, MessageName) select 'I' /* Info */, 'Receipts_UseActivateRouting'

  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_Action_PrepareForSortation */

Go
