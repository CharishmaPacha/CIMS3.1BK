/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/21  TK      pr_LPNs_Action_BulkMove & pr_LPNs_Action_PalletizeLPNs: Changes to update ReasonCode & Reference on LPNs
  2020/07/11  TK      pr_LPNs_Action_PalletizeLPNs, pr_LPNs_Palletize & pr_LPNs_DePalletize:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_PalletizeLPNs') is not null
  drop Procedure pr_LPNs_Action_PalletizeLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_PalletizeLPNs: Generates required number of pallets and palletizes
    LPNs by grouping them by grouping criteria specified and prints labels of generated pallets
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_PalletizeLPNs
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vDebug                   TFlags,

          @Entity                   TEntity,
          @Action                   TAction,
          @LPNsPerPallet            TCount,
          @GroupBy                  TVarchar,
          @MaxPalletsPerGroup       TCount,
          @RePalletize              TFlags,
          @ReasonCode               TReasonCode,
          @Reference                TReference,
          @LabelFormatName          TName,
          @PrinterName              TName,
          @Warehouse                TWarehouse,

          @vGroupByValue            TVarchar,

          @vNumLPNsSelected         TCount,
          @vMaxPalletRecordId       TCount,
          @vLPNsPalletized          TCount,
          @vLPNsIgnored             TCount,

          @vNumPalletsCreated       TCount,
          @vFirstPallet             TPallet,
          @vLastPallet              TPallet,
          @vSQL                     TNVarchar;

  declare @ttEntityKeysTable        TEntityKeysTable;
  declare @ttEntitiesToPrint        TEntitiesToPrint;
  declare @ttLPNsToPalletize  table (LPNId             TRecordId,
                                     LPN               TLPN,
                                     GroupByValue      TVarchar,

                                     GroupByRecordId   TRecordId,
                                     PalletRecordId    TRecordId  default 0,

                                     RecordId          TRecordId identity(1, 1));
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vLPNsIgnored  = 0,
         @vGroupByValue = '';

  /* Create temp tables */
  select * into #EntitiesToPrint from @ttEntitiesToPrint;
  select * into #LPNsToPalletize from @ttLPNsToPalletize;
  select * into #Pallets from @ttEntityKeysTable;

  /* Read input XML */
  select @Entity = Record.Col.value('Entity[1]',           'TEntity'),
         @Action = Record.Col.value('Action[1]',           'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  option(optimize for(@xmlData = null));

  select @LPNsPerPallet      = Record.Col.value('LPNsPerPallet[1]',       'TInteger'),
         @GroupBy            = Record.Col.value('GroupingCriteria[1]',    'TVarchar'),
         @MaxPalletsPerGroup = coalesce(nullif(Record.Col.value('MaxPalletsPerGroup[1]',  'TInteger'), ''), 9999999),
         @RePalletize        = Record.Col.value('RePalletize[1]',         'TFlags'),
         @ReasonCode         = Record.Col.value('ReasonCode[1]',          'TReasonCode'),
         @Reference          = Record.Col.value('Reference[1]',           'TReference'),
         @LabelFormatName    = Record.Col.value('LabelFormatName[1]',     'TName'),
         @PrinterName        = Record.Col.value('LabelPrinterName[1]',    'TName')
  from @xmlData.nodes('/Root/Data') as Record(Col)
  option (optimize for (@xmlData = null));

  /* Get all the selected LPNs */
  insert into #LPNsToPalletize (LPNId, LPN)
    select EntityId, EntityKey from #ttSelectedEntities;

  select @vNumLPNsSelected = @@rowcount;

  /* If LPNsPerPallet is not specified or it is zero then DePalletize selected LPNs */
  if (coalesce(nullif(@LPNsPerPallet, ''), 0) = 0) and (@vNumLPNsSelected > 0)
    begin
      select * into #LPNsToDePalletize from #LPNsToPalletize;

      /* invoke proc to depalletize selected LPNs */
      exec pr_LPNs_DePalletize default /* Operation */, @BusinessUnit, @UserId;

      goto ExitHandler;
    end

  /* If user is not asking to re-palletize and if selected LPNs are already on pallet then ignore them */
  if (@RePalletize = 'N' /* No */)
    begin
      delete LTP
      from #LPNsToPalletize LTP
        join LPNs L on (L.LPNId = LTP.LPNId) and (L.PalletId is not null);

      select @vLPNsIgnored = @@rowcount;

      /* Show how many LPNs were ignored to user */
      if (@vLPNsIgnored > 0)
        insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
          select 'I' /* Info */, 'LPNs_Palletize_LPNsAlreadyOnPallet', @vLPNsIgnored, @vNumLPNsSelected;
    end

  if not exists(select * from #LPNsToPalletize) goto BuildMessage;

  /* Update group by value column with selected value */
  select @vSQL = 'Update #LPNsToPalletize
                  set GroupByValue = ' + @GroupBy +
                 ' from #LPNsToPalletize LTP
                     join LPNs L on (LTP.LPNId = L.LPNId)
                     left outer join OrderHeaders OH on (L.OrderId = OH.OrderId);'
  exec sp_executesql @vSQL;

  /* Loop thru each group and identify the number of pallets to be generated for each group, let's take a look at below
     example on how do we generate pallets

     Let's say we need to palletize 3 LPNs per pallet & we have LPNs L1..L10 with GroupByValue as specified below
     L1-A, L2-A, L3-A, L4-A, L5-B, L6-B, L7-B, L8-C, L9-D, L10-D

     So for each  group we will generate PalletRecordId as below

     PalletRecordId    LPNs   GroupByValue
     1                 L1     A
     1                 L2     A
     1                 L3     A
     2                 L4     A -- First 3 LPNs to one pallet, 4th LPN will be added to new pallet

     3                 L5     B -- New pallet will be generated for new group
     3                 L6     B
     3                 L7     B

     4                 L8     C -- New pallet will be generated for new group

     5                 L9     D -- New pallet will be generated for new group
     5                 L10    D
  */
  while exists (select * from #LPNsToPalletize where GroupByValue > @vGroupByValue)
    begin
      select top 1 @vGroupByValue = GroupByValue
      from #LPNsToPalletize
      where (GroupByValue > @vGroupByValue)
      order by GroupByValue;

      /* Get the max pallet RecordId */
      select @vMaxPalletRecordId = max(PalletRecordId) from #LPNsToPalletize;

      /* Update Pallet Record Id for each group, each RecordId is a pallet here */
      ;with LPNsGrouping as
      (
       select LPNId,
              ceiling(row_number() over(partition by GroupByValue order by GroupByValue, LPNId) * 1.0 / @LPNsPerPallet) as PalletRecordId
       from #LPNsToPalletize
       where (GroupByValue = @vGroupByValue)
      )
      update LTP
      set PalletRecordId = coalesce(@vMaxPalletRecordId, 0) + LG.PalletRecordId
      from #LPNsToPalletize LTP
        join LPNsGrouping LG on (LTP.LPNId = LG.LPNId)
      where (LG.PalletRecordId <= @MaxPalletsPerGroup);  -- Do not exceed max pallets per group
    end

  if (charindex('D', @vDebug) > 0) select * from #LPNsToPalletize;

  /* Invoke Proc to palletize LPNs */
  exec pr_LPNs_Palletize default /* Operation */, @BusinessUnit, @UserId;

  /* Update Reference on the LPNs that are successfully palletized */
  update L
  set ReasonCode = @ReasonCode,
      Reference  = @Reference
  from LPNs L
    join #LPNsToPalletize LTP on (L.LPNId = LTP.LPNId)
  where (LTP.PalletRecordId is not null);

  /* If Label format name and printer name is selected then print newly generated pallet labels */
  if (@LabelFormatName is not null) and (@PrinterName is not null)
    begin
      insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, DocumentFormat, LabelPrinterName)
        select 'Pallet', EntityId, EntityKey, 'GeneratePallets', @LabelFormatName, @PrinterName
        from #Pallets;

      /* Invoke proc to print labels */
      exec pr_Printing_EntityPrintRequest 'Pallets', 'PalletizeLPNs', 'Pallet', null /* EntityId */, null /* EntityKey */,
                                          @BusinessUnit, @UserId,
                                          @RequestMode = 'IMMEDIATE', @LabelPrinterName = @PrinterName;
    end

BuildMessage:
  /* Get the Pallet counts and pallets to build message */
  select @vNumPalletsCreated = count(*),
         @vFirstPallet       = min(EntityKey),
         @vLastPallet        = max(EntityKey)
  from #Pallets;

  /* Get the Palletized LPN count */
  select @vLPNsPalletized = count(*) from #LPNsToPalletize where PalletRecordId is not null

  /* Build response to display to user */
  exec pr_Messages_BuildActionResponse @Entity, @Action, @vLPNsPalletized, @vNumLPNsSelected, @vNumPalletsCreated, @vFirstPallet, @vLastPallet;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_PalletizeLPNs */

Go
