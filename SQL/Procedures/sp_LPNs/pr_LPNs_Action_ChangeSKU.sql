/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  VS      pr_LPNs_Action_ChangeSKU: Made changes to Print the Labels in ModifySKU action (HA-2673)
  2021/05/06  VS      pr_LPNs_Action_ChangeSKU: Include the InventoryClasses in UniqueId (HA-2727)
  2021/03/16  MS      pr_LPNs_Action_ChangeSKU: Bug fix to Insert Pallet Recount, only if LPN's are on Pallets (HA-2290)
  2020/11/03  AJM     pr_LPNs_Action_ChangeSKU : Made changes to log AT message appropriately (HA-615)
  2020/06/12  OK      pr_LPNs_Action_ChangeSKU, pr_LPNs_Action_ModifyLPNs: Changes to inlude SourceSystem in exports (HA-898)
  2020/05/15  RKC     pr_LPNs_Action_ChangeSKU:Change SKU on LPNs which do not have Rserved/Directed Qty (HA-546)
  2020/05/13  MS      pr_LPNs_Action_ChangeSKU, pr_LPNs_Action_ModifyLPNs: Use pr_PrepareHashTable for #ExportRecords (HA-350)
                      pr_LPNs_Action_ChangeSKU: Initial Revision (HA-475)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_ChangeSKU') is not null
  drop Procedure pr_LPNs_Action_ChangeSKU;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_ChangeSKU: This procedures performs all the necessary changes
   that change SKU action from UI is expected to do.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_ChangeSKU
  (@xmlData            xml,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @AuditRecordId      TRecordId = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          /* Local variables */
          @vValidStatuses              TControlValue,
          @vNewSKUId                   TRecordId,
          @vNewSKU                     TSKU,
          @vNewSKU1                    TSKU,
          @vNewSKU2                    TSKU,
          @vNewSKU3                    TSKU,
          @vNewSKU4                    TSKU,
          @vNewSKU5                    TSKU,
          @vInventoryClass1            TInventoryClass,
          @vInventoryClass2            TInventoryClass,
          @vInventoryClass3            TInventoryClass,
          @vReasonCode                 TReasonCode,
          @vReference                  TReference,
          @vLabelFormatName            TName,
          @vLabelPrinterName           TName,

          @vNewValues                  TDescription;

  declare @ttLPNsUpdated         TEntityKeysTable,
          @ttPalletsToRecount    TRecountKeysTable,
          @ttEntitiesToPrint     TEntitiesToPrint;

  declare @ttLPNsInfo table (LPNId                TRecordId,
                             LPN                  TLPN,

                             PalletId             TRecordId,

                             OldSKU               TSKU,
                             NewSKU               TSKU,
                             OldSKUId             TSKU,
                             NewSKUId             TSKU,

                             OldInventoryClass1   TInventoryClass,
                             NewInventoryClass1   TInventoryClass,
                             OldInventoryClass2   TInventoryClass,
                             NewInventoryClass2   TInventoryClass,
                             OldInventoryClass3   TInventoryClass,
                             NewInventoryClass3   TInventoryClass,

                             PrevValues           TVarchar default '',
                             RecordId             TRecordId identity(1,1));
begin /* pr_LPNs_Action_ChangeSKU */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vRecordId      = 0,
         @vMessageName   = null,
         @vAuditActivity = 'AT_LPNSKUChanged',
         @vNewValues     = '';

  /* Create temp tables */
  select * into #EntitiesToPrint from @ttEntitiesToPrint;

  /* Get the Action from the xml */
  select @vEntity = Record.Col.value('Entity[1]',             'TEntity'),
         @vAction = Record.Col.value('Action[1]',             'TAction')
  from @XMLData.nodes('/Root') as Record(Col);

  /* Fetching required data from XML
     InventoryClass1-2-3: future use, if xml has following values then those will be considered,
     if not it will just update the New SKU only */
  select @vNewSKU           = nullif(Record.col.value('SKU[1]',              'TSKU'), ''),
         @vInventoryClass1  = nullif(Record.Col.value('InventoryClass1[1]',  'TInventoryClass'), ''),
         @vInventoryClass2  = nullif(Record.Col.value('InventoryClass2[1]',  'TInventoryClass'), ''),
         @vInventoryClass3  = nullif(Record.Col.value('InventoryClass3[1]',  'TInventoryClass'), ''),
         @vReasonCode       = nullif(Record.Col.value('ReasonCode[1]',       'TReasonCode'), ''),
         @vReference        = nullif(Record.Col.value('Reference[1]',        'TReference'), ''),
         @vLabelFormatName  = nullif(Record.Col.value('LabelFormatName[1]',  'TName'), ''),
         @vLabelPrinterName = nullif(Record.Col.value('LabelPrinterName[1]', 'TName'), '')
  from @XMLData.nodes('/Root/Data') as Record(col);

  /* Get the Total LPNs counts */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get SKU Info */
  select @vNewSKUId = SKUId,
         @vNewSKU   = SKU,
         @vNewSKU1  = SKU1,
         @vNewSKU2  = SKU2,
         @vNewSKU3  = SKU3,
         @vNewSKU4  = SKU4,
         @vNewSKU5  = SKU5
  from dbo.fn_SKUs_GetScannedSKUs (@vNewSKU, @BusinessUnit)
  where (Status = 'A'/* Active */)

  /* Validations */
  if (@vNewSKU is null)
    set @vMessagename = 'SKUIsRequired';
  else
  if (@vNewSKUId is null)
    set @vMessageName = 'SKUIsInvalid';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get Controls */
  select @vValidStatuses = dbo.fn_Controls_GetAsString('ChangeSKU', 'ValidStatuses', 'NPRT' /* InTransit, Received, New, Putaway */, @BusinessUnit, @UserId);

  /* Get all the required info from LPNs for validations to avoid hitting the LPNs
     table again and again */
  select L.LPNId, L.LPN, L.SKUId, L.ReservedQty, L.DirectedQty, cast(L.Status as varchar(30)) as LPNStatus,
  case when L.SKUId is null                                then 'LPNs_ChangeSKU_MultiSKULPN'
       when L.ReservedQty > 0                              then 'LPNs_ChangeSKU_ReservedLPN'
       when L.DirectedQty > 0                              then 'LPNs_ChangeSKU_HasDirectedQty'
       when (dbo.fn_IsInList(Status, @vValidStatuses) = 0) then 'LPNs_ChangeSKU_InvalidStatus'
  end ErrorMessage
  into #InvalidLPNs
  from #ttSelectedEntities SE join LPNs L on SE.EntityId = L.LPNId;

  /* Get the status description for the error message */
  update #InvalidLPNs
  set LPNStatus = dbo.fn_Status_GetDescription('LPN', LPNStatus, @BusinessUnit);

  /* Exclude the LPNs that are not putaway as we cannot change Ownership of LPNs that are
     assigned to any Orders */
  delete from SE
  output 'E', IL.LPNId, IL.LPN, IL.ErrorMessage, IL.LPNStatus
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE join #InvalidLPNs IL on SE.EntityId = IL.LPNId
  where (IL.ErrorMessage is not null);

  /* Update new SKU on the selected LPNs */
  update L
  set SKUId           = @vNewSKUId,
      SKU             = @vNewSKU,
      SKU1            = @vNewSKU1,
      SKU2            = @vNewSKU2,
      SKU3            = @vNewSKU3,
      SKU4            = @vNewSKU4,
      SKU5            = @vNewSKU5,
      InventoryClass1 = coalesce(@vInventoryClass1, InventoryClass1),
      InventoryClass2 = coalesce(@vInventoryClass2, InventoryClass2),
      InventoryClass3 = coalesce(@vInventoryClass3, InventoryClass3),
      ReasonCode      = @vReasonCode,
      Reference       = @vReference,
      UniqueId        = case when LPNType = 'L' /* Picklane */ then
                               concat_ws('-', L.Location, @vNewSKU, coalesce(@vInventoryClass1, InventoryClass1), coalesce(@vInventoryClass2, InventoryClass2), coalesce(@vInventoryClass3, InventoryClass3), L.Lot)
                             else null
                        end,
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @UserId
  output Inserted.LPNId, Inserted.LPN, Inserted.PalletId, Deleted.SKU, Deleted.SKUId, Inserted.SKU, Inserted.SKUId, Deleted.InventoryClass1, Inserted.InventoryClass1,
         Deleted.InventoryClass2, Inserted.InventoryClass2, Deleted.InventoryClass3, Inserted.InventoryClass3
  into @ttLPNsInfo (LPNId, LPN, PalletId, OldSKU, OldSKUId, NewSKU, NewSKUId, OldInventoryClass1, NewInventoryClass1, OldInventoryClass2,
                    NewInventoryClass2, OldInventoryClass3, NewInventoryClass3)
  from LPNs L
    join #ttSelectedEntities ttSE on (ttSE.EntityId = L.LPNId) and
                             (L.SKUId is not null) and -- Cannot be a multi-SKU LPN/picklane
                             (L.ReservedQty = 0) and -- Can't change on LPN/Picklane with ReservedQty
                             (L.DirectedQty = 0) and -- Can't change on Picklane with DirectedQty
                             (dbo.fn_IsInList(Status, @vValidStatuses) > 0) -- Can't change on LPN/picklane with invalid status

  set @vRecordsUpdated = @@rowcount;

  /* If no LPNs updated then return */
  if (@vRecordsUpdated = 0) goto BuildMessage;

  /* Update new SKU on the details of LPNs updated above */
  update LD
  set SKUId        = ttLI.NewSKUId,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  from LPNDetails LD
    join @ttLPNsInfo ttLI on (LD.LPNId = ttLI.LPNId);

  /* if there is any change in SKU or inventory class then export InvCh transactions to host */
  if exists(select *
            from @ttLPNsInfo
            where (OldSKUId <> NewSKUId) or
                  ((OldInventoryClass1 <> NewInventoryClass1) or
                   (OldInventoryClass2 <> NewInventoryClass2) or
                   (OldInventoryClass3 <> NewInventoryClass3)))
    begin
      /* Build temp table with the Result set of the procedure */
      create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'Exports', '#ExportRecords';

      /* Generate the transactional changes for all LPNs */
      insert into #ExportRecords (TransType, TransQty, LPNId, SKUId, PalletId, LocationId, Warehouse, Ownership, ReasonCode,
                                  Lot, InventoryClass1, InventoryClass2, InventoryClass3, Reference, SourceSystem)
        /* Generate negative InvCh transactions for the Old SKU or Inventory Class(es) */
        select 'InvCh', -1 * LD.Quantity, L.LPNId, ttLI.OldSKUId, L.PalletId, L.LocationId, L.DestWarehouse, L.Ownership, @vReasonCode,
               L.Lot, ttLI.OldInventoryClass1, ttLI.OldInventoryClass2, ttLI.OldInventoryClass3, @vReference, LD.SourceSystem
        from @ttLPNsInfo ttLI
          join LPNs L on ttLI.LPNId = L.LPNId and L.OnhandStatus = 'A'/* Available */
          join LPNDetails LD on L.LPNId = LD.LPNId
        /* Generate positive InvCh transactions for the New SKU or Inventory Class(es) */
        union
        select 'InvCh', LD.Quantity, L.LPNId, ttLI.NewSKUId, L.PalletId, L.LocationId, L.DestWarehouse, L.Ownership, @vReasonCode,
               L.Lot, ttLI.NewInventoryClass1, ttLI.NewInventoryClass2, ttLI.NewInventoryClass3, @vReference, LD.SourceSystem
        from @ttLPNsInfo ttLI
          join LPNs L on ttLI.LPNId = L.LPNId and L.OnHandStatus = 'A'/* Available */
          join LPNDetails LD on L.LPNId = LD.LPNId

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'InvCh', 'LPN' /* TransEntity - LPN */, @BusinessUnit;
    end

  /* Get the Pallets, if selected LPN's are on Pallet */
  insert into @ttPalletsToRecount (EntityId) select distinct PalletId from @ttLPNsInfo;

  /* Recount Pallets */
  if exists (select * from @ttPalletsToRecount where EntityId > 0)
    exec pr_Pallets_Recalculate @ttPalletsToRecount, '$C'/* Counts-only */, @BusinessUnit, @UserId;

  /* On changing the SKU, Need to print the LPN labels if PrinterName is given */
  if (coalesce(@vLabelPrinterName, '') <> '')
    begin
      insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, DocumentFormat, LabelPrinterName)
        select distinct 'LPN', LPNId, LPN, @vAction, @vLabelFormatName, @vLabelPrinterName
        from @ttLPNsInfo;

      /* Invoke proc to print labels */
      exec pr_Printing_EntityPrintRequest 'LPNs', @vAction, 'LPN', null /* EntityId */, null /* EntityKey */,
                                          @BusinessUnit, @UserId, @RequestMode = 'IMMEDIATE', @LabelPrinterName = @vLabelPrinterName;
    end

  /* Build Note to display to user */
  select @vNewValues = dbo.fn_AppendCSV(@vNewValues, 'SKU',        @vNewSKU);
  select @vNewValues = dbo.fn_AppendCSV(@vNewValues, 'Inv Class1', @vInventoryClass1);
  select @vNewValues = dbo.fn_AppendCSV(@vNewValues, 'Inv Class2', @vInventoryClass2);
  select @vNewValues = dbo.fn_AppendCSV(@vNewValues, 'Inv Class3', @vInventoryClass3);

  /* Build the previous value */
  update @ttLPNsInfo set PrevValues = dbo.fn_AppendCSV(PrevValues, 'SKU',        OldSKU);
  update @ttLPNsInfo set PrevValues = dbo.fn_AppendCSV(PrevValues, 'Inv Class1', nullif(OldInventoryClass1, ''));
  update @ttLPNsInfo set PrevValues = dbo.fn_AppendCSV(PrevValues, 'Inv Class2', nullif(OldInventoryClass2, ''));
  update @ttLPNsInfo set PrevValues = dbo.fn_AppendCSV(PrevValues, 'Inv Class3', nullif(OldInventoryClass3, ''));

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'LPN', LPNId, LPN, @vAuditActivity, @BusinessUnit, @UserId,
           dbo.fn_Messages_Build(@vAuditActivity, @vNewValues, PrevValues, null, null, null) /* Comment */
    from @ttLPNsInfo;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

BuildMessage:
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  /* Build success message */
  insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, 'Update: (' + @vNewValues + ')';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_ChangeSKU */

Go
