/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/09  MS      pr_Receipts_Action_PrepareForSortation: Code optimized and cleanup (JL-286, JL-287)
                      pr_Receipts_Action_ActivateRouting: Changes to create receivers (JL-286, JL-287)
                      pr_Receipts_CreateReceivers: Added new proc to create receivers for given LPNs (JL-286, JL-287)
                      pr_Receipts_UnPalletize: Corrections to send RouteLPN aswell, to be in consistent with #RouterLPNs activated earlier
                      pr_ReceivedCounts_AddOrUpdate: Changes to update ReceiverNumber on existing ReceivedCounts (JL-286, JL-287)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_Action_ActivateRouting') is not null
  drop Procedure pr_Receipts_Action_ActivateRouting;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_Action_ActivateRouting: When the Container is ready to be
    sorted on WCS, users would Activate the Routing by selecting the Receipts
    or the Receipt Details. All associated InTransit LPNs have to be sent to WCS.
  -- Receiver(s) are created and LPNs linked to them as well.
  -- Receipt Details' is updated to reflect that the Sortation has been activated

  #LPNsIntransit: TEntityValuesTable

  @xmlData
      <Root>
        <Entity>ReceiptDetails</Entity>
        <Action>ReceiptDetails_ActivateRouting</Action>
        <SelectedRecords>
          <RecordDetails><EntityId>190</EntityId></RecordDetails>
          <RecordDetails><EntityId>191</EntityId></RecordDetails>
        </SelectedRecords>
        <SessionInfo>
          <UserId>cimsadmin</UserId>
          <BusinessUnit>JL</BusinessUnit>
          <UserFilter_Warehouse>*</UserFilter_Warehouse>
        </SessionInfo>
      </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_Action_ActivateRouting
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
          @vTotalRecords       TCount,
          @vRecordsToProcess   TCount,
          @vRecordshavingRI    TCount;

  declare @ttEntityValues      TEntityValuesTable;
  declare @ttEntityKeys        TEntityKeysTable;

begin /* pr_Receipts_Action_ActivateRouting */

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  /* Create temp tables */
  select * into #LPNsPalletized  from @ttEntityValues;
  select * into #RecordshavingRI from @ttEntityValues;
  select * into #ReceiptDetails  from @ttEntityKeys;

  /* Get required info from Xml */
  select @vEntity = Record.Col.value('Entity[1]',   'TEntity'),
         @vAction = Record.Col.value('Action[1]',   'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Get the total count of selected records from #ttSelectedEntities */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* If #LPNsInTransit table is sent in caller then use those LPNs */
  if object_id(N'tempdb..#LPNsInTransit') is not null
    begin
      insert into #LPNsPalletized select * from #LPNsInTransit

      /* To Build Success msg for Activate Routing, change the actionname */
      select @vAction = replace(@vAction, dbo.fn_SubstringBetweenSeparator(@vAction, '_', 1, 1), 'ActivateRouting')
    end
  else
  /* Users could activate routing from RH or RD views, so select the associated
     LPNs based upon the Entity */
  if (@vEntity = 'Receipt')
    begin
      /* Insert all Intransit-Palletized LPNs of the selected Receipts */
      insert into #LPNsPalletized (RecordId, EntityId, EntityKey, UDF1)
        select row_number() over (order by L.LPNId) , L.LPNId, L.LPN, min(L.ReceiptId)
        from LPNs L
          join #ttSelectedEntities SE on (L.ReceiptId = SE.EntityId)
        where (L.Status = 'T' /* InTransit*/) and
              (coalesce(L.PalletId, 0) <> 0)
        group by L.LPNId, L.LPN;
    end
  else
  if (@vEntity = 'ReceiptDetails')
    begin
      /* Insert all Intransit-Palletized LPNs of the selected Receipt Details */
      insert into #LPNsPalletized (RecordId, EntityId, EntityKey, UDF1, UDF2)
        select row_number() over (order by L.LPNId), L.LPNId, L.LPN, min(L.ReceiptId), min(LD.ReceiptDetailId)
        from LPNs L
          join LPNDetails          LD on (L.LPNId            = LD.LPNId)
          join #ttSelectedEntities SE on (LD.ReceiptDetailId = SE.EntityId)
        where (L.Status = 'T' /* InTransit*/) and
              (coalesce(L.PalletId, 0) <> 0)
        group by L.LPNId, L.LPN;
    end

  /* Get all the selected Receipt Details to update SortStatus */
  insert into #ReceiptDetails (EntityId, EntityKey) -- ReceiptDetailId, ReceiptId
    select distinct LD.ReceiptDetailId, LD.ReceiptId
    from #LPNsPalletized LT join LPNDetails LD on (LT.EntityId = LD.LPNId);

  -- /* Delete the LPNs which are already sent RI's and yet to be processed */
  -- delete LP
  -- output deleted.RecordId, deleted.EntityId /* LPNId */, deleted.EntityKey /* LPN */, deleted.UDF1 /* ReceiptId/ReceiptDetailId */
  -- into #RecordshavingRI (RecordId, EntityId, EntityKey, UDF1)
  -- from #LPNsPalletized LP
  --   join RouterInstruction RI on (LP.EntityKey = RI.LPN)
  -- where (RI.ExportStatus = 'N' /* Not yet Processed*/) and
  --       (RI.Destination <> 'REJECT')

  /* We are deleting few records above, so get the counts after deletion
     Get how many records are eligible to Activate RI & how many records already have RI */
  if (@vEntity = 'Receipt')
    begin
      select @vRecordsToProcess = count(distinct(UDF1)) from #LPNsPalletized
      select @vRecordshavingRI  = count(distinct(UDF1)) from #RecordshavingRI
    end
  else
  if (@vEntity = 'ReceiptDetails')
    begin
      select @vRecordsToProcess = count(distinct(UDF2)) from #LPNsPalletized
      select @vRecordshavingRI  = count(distinct(UDF2)) from #RecordshavingRI
    end

  if (charindex('D' /* Display */, @vDebug) > 0)
    begin
      select '#LPNsPalletized',  * from #LPNsPalletized;
      select '#RecordshavingRI', * from #RecordshavingRI;
    end

  /* If all selected records already have active RI, then raise error */
  if (@vRecordshavingRI = @vTotalRecords) and (not exists (select * from #LPNsPalletized))
    set @vMessageName = 'Receipts_ActivateRouting_AllRecordshaveRI';
  else
  /* If there are no LPNs are eligible to Activate RI, then raise error */
  if (not exists (select * from #LPNsPalletized))
    set @vMessageName = 'Receipts_ActivateRouting_NoLPNstoActivateRI';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Create receiver for the selected LPNs, if receiver(s) does(do) not exist */
  exec pr_Receipts_CreateReceivers @BusinessUnit, @UserId;

  /* Build the list of LPNs to be sent to router */
  select L.LPNId, L.LPN, L.LPN RouteLPN, L.DestLocation
  into #RouterLPNs
  from #LPNsPalletized LP join LPNs L on (LP.EntityId = L.LPNId);

  /* Send Router Instructions for the selected LPNs - #RouterLPNs */
  exec pr_Router_SendRouteInstruction null, null, default, @BusinessUnit = @BusinessUnit, @UserId = @UserId;

  /* Update RD.SortStatus as activated for selected records and so users can see
     which RD are already activated */
  update RD
  set RD.SortStatus = 'Activated'
  from ReceiptDetails RD
    join #ReceiptDetails TRD on (RD.ReceiptDetailId = TRD.EntityId);

  /* Send response to user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsToProcess, @vTotalRecords;

  if (@vRecordshavingRI > 0)
    insert into #ResultMessages (MessageType, MessageName, Value1, Value2)
      select 'I' /* Info */, 'Receipts_ActivateRouting_SomeRecordshaveRI', @vRecordshavingRI, @vTotalRecords

  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_Action_ActivateRouting */

Go
