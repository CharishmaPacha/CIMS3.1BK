/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  AY      pr_Alerts_LPNDiscrepancies: Changes to only report LPNs modified recently (CIMSV3-1293)
  2020/10/22  SK      pr_Alerts_LPNDiscrepancies: Added step to include negative inventorys (HA-1598)
  2020/07/28  VS      pr_Alerts_LPNDiscrepancies: Added New procedure to get the Invalid Ownership LPNs and Invalid NumCases (S2GCA-666 & S2GCA-791)
  2019/05/16  VS      pr_Alerts_LPNDiscrepancies: Added New procedure to get the Invalid Ownership LPNs and Invalid NumCases (S2GCA-666 & S2GCA-791)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_LPNDiscrepancies') is not null
  drop Procedure pr_Alerts_LPNDiscrepancies;
Go
/*------------------------------------------------------------------------------
  pr_Alerts_LPNDiscrepancies: This procedure is used to identify LPN discrepancies
    and send an alert if there are any. Currently it evaluates Invalid Ownership
    and LPN.NumCases being inconsistent with SKU.InventoryUoM, Negative inventory

  Job is scheduled to run at every 60 mins, so just to be safe that we don't miss
  any alerts, the default time is set to 65 mins.
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_LPNDiscrepancies
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 65 /* Works for entities which are modified in 65 mins */,
   @ReturnDataSet               TFlags    = 'N',
   @EntityId                    TRecordId = null)
as
  declare @vInvalidOwnerLPNs TVarchar,
          @vInvalidUoMLPNs   TVarchar,
          @vInvalidQtyLPNs   TVarchar,
          @vEmailBody        TVarchar;
begin
  SET NOCOUNT ON;

  /*------------------------------------------------------------------------*/
  /* Get the Invalid Ownership LPNs */
  select L.LPN, OH.PickTicket, L.Ownership LPNOwnership, OH.Ownership OrderOwnership,
         L.Status LPNStatus, OH.Status OrderStatus, 'Ownership mismatch between LPN and PickTicket' ErrorMessage
         into #InvalidOwnershipLPNs
  from LPNs L            with (nolock)
    join OrderHeaders OH with (nolock) on (L.OrderId = OH.OrderId)
  where (L.Archived = 'N') and (L.Status not in ('S')) and (L.Ownership <> OH.Ownership) and
        (datediff(mi, L.ModifiedDate, getdate()) <= @ShowModifiedInLastXMinutes);

  if exists (select top 1 * from #InvalidOwnershipLPNs)
    exec pr_HashTableToHTML '#InvalidOwnershipLPNs', null, @vInvalidOwnerLPNs out;

  /*------------------------------------------------------------------------*/
  /* Get the Invalid NumCases LPNs */
  select L.LPN, L.SKU, L.Quantity, L.InnerPacks, coalesce(S.InventoryUoM, ' ') InventoryUoM,
         'Invalid NumCases' ErrorMessage
  into #InvalidUoMLPNs
  from LPNs L   with (nolock)
    join SKUs S with (nolock) on L.SKUId = S.SKUId
  where (L.Archived = 'N') and (charindex('CS', coalesce(S.InventoryUoM, '')) = 0) and
        (L.InnerPacks > 0) and (L.OnhandStatus = 'A') and
        (datediff(mi, L.ModifiedDate, getdate()) <= @ShowModifiedInLastXMinutes);

  if exists (select top 1 * from #InvalidUoMLPNs)
    exec pr_HashTableToHTML '#InvalidUoMLPNs', null, @vInvalidUoMLPNs out;

  /*------------------------------------------------------------------------*/
  /* Get LPNs with negative inventory */
  select L.LPN, L.SKU, L.Status, L.OnhandStatus, L.Quantity, L.CreatedDate, L.ModifiedDate, L.ModifiedBy,
         'Negative Inventory' ErrorMessage
  into #InvalidQtyLPNs
  from LPNs L with (nolock)
  where (L.Archived = 'N') and
        (L.Status not in ('C', 'V', 'O', 'I' /* Consumed, Voided, Lost, Inactive */)) and
        (L.Quantity < 0) and
        (datediff(mi, L.ModifiedDate, getdate()) <= @ShowModifiedInLastXMinutes);

  if exists (select top 1 * from #InvalidQtyLPNs)
    exec pr_HashTableToHTML '#InvalidQtyLPNs', null, @vInvalidQtyLPNs out;

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #InvalidOwnershipLPNs;
      select * from #InvalidUoMLPNs;
      select * from #InvalidQtyLPNs;

      return(0);
    end

  /*------------------------------------------------------------------------*/
  /* Consolidate all htmls and send one email */
  select @vEmailBody = coalesce(@vInvalidOwnerLPNs, '') + coalesce(@vInvalidUoMLPNs, '') + coalesce(@vInvalidQtyLPNs, '');

  if (@vEmailBody <> '')
    exec pr_Email_SendQueryResults  @AlertCategory = 'LPNDiscrepancies', @TableName = null, @EmailBody = @vEmailBody, @BusinessUnit = @BusinessUnit;

end /* pr_Alerts_LPNDiscrepancies */

Go
