/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/31  AY      pr_Alerts_InventoryVariance: Renamed proc and sorted by KeyValue (HA-3048)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_InventoryVariance') is not null
  drop Procedure pr_Alerts_InventoryVariance;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_InventoryVariance:

  This procedure checks for any inventory discrepancy for that day
  and sends out an email alert if there are any variances.

  EmailIfNoAlert - N: Would not send any email if there is nothing to alert
                   Y: Would send an email even if there is nothing to alert.
                      A job could be setup to do this once a month so that we know
                      that the job is active and running
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_InventoryVariance
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @DateGiven       TDate     = null,
   @ReturnDataSet   TFlags    = 'N',
   @EmailIfNoAlert  TFlags    = 'N')
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vAlertCategory     TCategory;

  declare @vDateGiven         TDate;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vAlertCategory  = object_name(@@ProcId),
         @vDateGiven      = coalesce(@DateGiven, getdate());

  /* Get the records subset that has variance */
  select RecordId, KeyValue, InventoryClass1, InventoryClass2, InventoryClass3,
         SS1Id, SS1Date, SS1AvailableQty, SS1ReservedQty, SS1ToShipQty, SS1OnhandQty,
         SS2Id, SS2Date, SS2OnhandQty, ExpReceivedQty, ExpInvChanges, ExpShippedQty,
         Variance
  into #AlertInventoryVariance
  from InvComparison with (nolock)
  where (CreatedOn = @vDateGiven) and (Variance <> 0)
  order by KeyValue;

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #AlertInventoryVariance;
      return(0);
    end

  /* Proceed to email only if the table has entries that has variance */
  if (@EmailIfNoAlert = 'Y') or (exists(select * from #AlertInventoryDiscrepancy))
    exec pr_Email_SendQueryResults @vAlertCategory, '#AlertInventoryVariance', null /* order by */, @BusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Alerts_InventoryVariance */

Go
