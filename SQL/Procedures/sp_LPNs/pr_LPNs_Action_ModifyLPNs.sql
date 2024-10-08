/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/30  MS      pr_LPNs_Action_ModifyLPNs: Added validation to avoid updating Labelcode on Reserved LPNs (HA-1807)
  2020/12/10  RV      pr_LPNs_Action_ModifyLPNs: Made changes to update the UniqueId (HA-1752)
  2020/06/12  OK      pr_LPNs_Action_ChangeSKU, pr_LPNs_Action_ModifyLPNs: Changes to inlude SourceSystem in exports (HA-898)
  2020/05/13  MS      pr_LPNs_Action_ChangeSKU, pr_LPNs_Action_ModifyLPNs: Use pr_PrepareHashTable for #ExportRecords (HA-350)
                      pr_LPNs_Action_ModifyLPNs: Initial Revision (HA-422)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_ModifyLPNs') is not null
  drop Procedure pr_LPNs_Action_ModifyLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_ModifyLPNs: This procedures performs all the necessary changes
   that modify LPN action from UI is expected to do.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_ModifyLPNs
  (@XMLData            xml,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @AuditRecordId      TRecordId = null output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TMessage,

          @vAction               TAction,
          @vInvExpDate           TDate,
          @vExpDate              TVarchar,
          @vLotNumber            TLot,
          @vInventoryClass1      TInventoryClass,
          @vInventoryClass2      TInventoryClass,
          @vInventoryClass3      TInventoryClass,
          @vReasonCode           TReasonCode,
          @vReference            TReference,

          @vLPNCount             TCount,
          @vLPNsUpdated          TCount,

          @vActivityType         TActivityType,
          @vAuditRecordId        TRecordId,
          @vNote1                TDescription;

  declare @ttLPNsUpdated         TEntityKeysTable;
  declare @ttLPNsInfo table (LPNId                TRecordId,
                             LPN                  TLPN,

                             OldInventoryClass1   TInventoryClass,
                             NewInventoryClass1   TInventoryClass,
                             OldInventoryClass2   TInventoryClass,
                             NewInventoryClass2   TInventoryClass,
                             OldInventoryClass3   TInventoryClass,
                             NewInventoryClass3   TInventoryClass,

                             RecordId             TRecordId identity(1,1));
begin /* pr_LPNs_Action_ModifyLPNs */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vNote1        = '';

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'varchar(100)')
  from @xmlData.nodes('/ModifyLPNs') as Record(Col);

  /* Fetching of LPN Lot and Expiry Date from XML */
  select @vInvExpDate       = nullif(Record.Col.value('InvExpDate[1]',      'TDate'), ''),
         @vLotNumber        = nullif(Record.Col.value('LotNumber[1]',       'TLot'), ''),
         @vInventoryClass1  = nullif(Record.Col.value('InventoryClass1[1]', 'TInventoryClass'), ''),
         @vInventoryClass2  = nullif(Record.Col.value('InventoryClass2[1]', 'TInventoryClass'), ''),
         @vInventoryClass3  = nullif(Record.Col.value('InventoryClass3[1]', 'TInventoryClass'), ''),
         @vReasonCode       = nullif(Record.Col.value('ReasonCode[1]',      'TReasonCode'), ''),
         @vReference        = nullif(Record.Col.value('Reference[1]',       'TReference'), '')
  from @xmlData.nodes('/ModifyLPNs/Data') as Record(Col);

  /* Converting Date Format to dd/mm/yyyy for logging Audit Trail */
  select @vExpDate      = convert(varchar, @vInvExpDate, 101),
         @vActivityType = @vAction;
  select @vLPNCount     = count(*) from #LPNsToUpdate;

  /* Do not update InventoryClasses of LPNs with Reserved Lines */
  if ((coalesce(@vInventoryClass1, '') <> '') or (coalesce(@vInventoryClass2, '') <> '') or
      (coalesce(@vInventoryClass3, '') <> ''))
    delete SE
    output 'E', Deleted.EntityId, Deleted.EntityKey, 'LPN_ModifyLPNs_LPNIsReserved'
    into #ResultMessages (MessageType, EntityId, EntityKey, MessageName)
    from #LPNsToUpdate SE
      join LPNs L on (SE.EntityId = L.LPNId)
      left outer join OrderHeaders OH on (L.OrderId = OH.OrderId)
    where (L.ReservedQty > 0) and (OH.OrderType <> 'B' /* Bulk */);

  /* Update Expiry Date, Lot & InventoryClasses on the selected LPNs */
  update L
  set ExpiryDate      = coalesce(@vInvExpDate, ExpiryDate),
      Lot             = coalesce(@vLotNumber, Lot),
      InventoryClass1 = coalesce(@vInventoryClass1, InventoryClass1),
      InventoryClass2 = coalesce(@vInventoryClass2, InventoryClass2),
      InventoryClass3 = coalesce(@vInventoryClass3, InventoryClass3),
      ReasonCode      = @vReasonCode,
      Reference       = @vReference,
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @UserId,
      UniqueId        = case when LPNType = 'L' then
                               L.LPN + '-' + coalesce(L.SKU, '') + '-' + coalesce(@vInventoryClass1, InventoryClass1, '') + '-' +
                               coalesce(@vInventoryClass2, InventoryClass2, '') + '-' + coalesce(@vInventoryClass3, InventoryClass3, '') + '-' + coalesce(Lot, '')
                             else LPN
                        end /* UniqueId */
  output Inserted.LPNId, Inserted.LPN, Deleted.InventoryClass1, Inserted.InventoryClass1,
         Deleted.InventoryClass2, Inserted.InventoryClass2, Deleted.InventoryClass3, Inserted.InventoryClass3
  into @ttLPNsInfo (LPNId, LPN, OldInventoryClass1, NewInventoryClass1, OldInventoryClass2,
                    NewInventoryClass2, OldInventoryClass3, NewInventoryClass3)
  from LPNs L
    join #LPNsToUpdate LP on (LP.EntityId = L.LPNId)
    left outer join OrderHeaders  OH on (L.OrderId   = OH.OrderId)
  where (((L.OnhandStatus <> 'R'/* Cannot modify Reserved LPNs */)) or
         ((L.OnhandStatus = 'R' /* Reserved */) and (OH.OrderType = 'B' /* Bulk */))) and
        (L.Status not in ('S', 'C', 'V', 'O' /* Shipped, Consumed, Voided, Lost */));

  set @vLPNsUpdated = @@rowcount;

  /* If no LPNs updated then return */
  if (@vLPNsUpdated = 0) goto BuildMessage;

  /* if there is any change in inventory class then export InvCh transactions to host */
  if exists(select *
            from @ttLPNsInfo
            where (OldInventoryClass1 <> NewInventoryClass1) or
                  (OldInventoryClass2 <> NewInventoryClass2) or
                  (OldInventoryClass3 <> NewInventoryClass3))
    begin
      /* Build temp table with the Result set of the procedure */
      create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'Exports', '#ExportRecords';

      /* Generate the transactional changes for all LPNs */
      insert into #ExportRecords (TransType, TransQty, LPNId, SKUId, PalletId, LocationId, Warehouse, Ownership, ReasonCode,
                                  Lot, InventoryClass1, InventoryClass2, InventoryClass3, Reference, SourceSystem)
        /* Generate negative InvCh transactions for the Old Inventory Class(es) */
        select 'InvCh', -1 * LD.Quantity, L.LPNId, LD.SKUId, L.PalletId, L.LocationId, L.DestWarehouse, L.Ownership, @vReasonCode,
               L.Lot, ttLI.OldInventoryClass1, ttLI.OldInventoryClass2, ttLI.OldInventoryClass3, @vReference, LD.SourceSystem
        from @ttLPNsInfo ttLI
          join LPNs L on ttLI.LPNId = L.LPNId and L.OnhandStatus in ('A'/* Available */, 'R'/* Reserved */)
          join LPNDetails LD on L.LPNId = LD.LPNId
        /* Generate positive InvCh transactions for the New Inventory Class(es) */
        union
        select 'InvCh', LD.Quantity, L.LPNId, LD.SKUId, L.PalletId, L.LocationId, L.DestWarehouse, L.Ownership, @vReasonCode,
               L.Lot, ttLI.NewInventoryClass1, ttLI.NewInventoryClass2, ttLI.NewInventoryClass3, @vReference, LD.SourceSystem
        from @ttLPNsInfo ttLI
          join LPNs L on ttLI.LPNId = L.LPNId and L.OnHandStatus in ('A'/* Available */, 'R'/* Reserved */)
          join LPNDetails LD on L.LPNId = LD.LPNId

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'InvCh', 'LPN' /* TransEntity - LPN */, @BusinessUnit;
    end

  /* Log AT on LPNs */
  insert into @ttLPNsUpdated (EntityId, EntityKey) select distinct LPNId, LPN from @ttLPNsInfo;

  /* Build Note to log AT */
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Expiry Date', @vInvExpDate);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Lot', @vLotNumber);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Inv Class1', @vInventoryClass1);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Inv Class2', @vInventoryClass2);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Inv Class3', @vInventoryClass3);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1,
                            @AuditRecordId = @vAuditRecordId output;

  if (@vAuditRecordId is not null)
    exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttLPNsUpdated, @BusinessUnit;

BuildMessage:
  exec @vMessage = dbo.fn_Messages_BuildActionResponse 'LPN', @vAction, @vLPNsUpdated, @vLPNCount;

  /* Build success message & show AT of the changes */
  insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @vMessage;
  insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, Comment from AuditTrail where AuditId = @vAuditRecordId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_ModifyLPNs */

Go
