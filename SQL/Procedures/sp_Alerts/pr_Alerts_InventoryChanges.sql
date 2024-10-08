/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/12  KBB     pr_Alerts_InventoryChanges: Added DefaultEmail when Soucre value Missing (BK-642)
  2021/09/09  MS      pr_Alerts_InventoryChanges: Added (BK-546)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_InventoryChanges') is not null
  drop Procedure pr_Alerts_InventoryChanges;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_InventoryChanges:

  This procedure checks for any inventory discrepancy for that day
  and sends out an email alert if there are any variances.

  EmailIfNoAlert - N: Would not send any email if there is nothing to alert
                   Y: Would send an email even if there is nothing to alert.
                      A job could be setup to do this once a month so that we know
                      that the job is active and running
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_InventoryChanges
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @ReturnDataSet   TFlags    = 'N',
   @EmailIfNoAlert  TFlags    = 'N')
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vAlertCategory     TCategory,
          @vSKUCategory       TCategory,
          @vCurrentDate       TDate,
          @vDefaultEmail      TVarChar,
          @vReasonCodes       TDescription,
          @vEmail             TVarchar;

  declare @ttEmailGroups      table (SKUCategory TCategory,
                                     Email       TVarchar /* There may be multiple emailid's to be sent, hence used varchar */,
                                     RecordId    TRecordId identity(1,1));

begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAlertCategory = object_name(@@ProcId),
         @vCurrentDate   = getdate();

  select @vReasonCodes  =  dbo.fn_Controls_GetAsString(@vAlertCategory, 'ReasonCodes', '', @BusinessUnit, @UserId);

  /* get the default email to be used when there is no mapping for the SKU category */
  exec pr_Email_GetConfiguration @vAlertCategory, @BusinessUnit, @UserId, @Recipients = @vDefaultEmail output;

  /* Get the records */
  select E.SKU, E.ReasonCode as 'Reason Code', L.LookupDescription as 'Reason', E.TransQty as '+/- Quantity', E.LPN, E.Location,
         E.CreatedBy as 'User', ('$'+ cast(E.MonetaryValue as varchar)) as Cost,
         substring(E.SKU, 1, 3) as SKUCategory
  into #InventoryChanges
  from vwExports E with (nolock)
    join Lookups L with (nolock) on (L.Lookupcode = E.ReasonCode)
  where (E.TransType = 'INVCH') and
        (E.TransDate = @vCurrentDate)
  order by E.RecordId;

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #InventoryChanges;
      return(0);
    end

  /* Get distinct SKU categories */
  insert into @ttEmailGroups(SKUCategory)
    select distinct SKUCategory from #InventoryChanges;

  /* Get the email of each group */
  update EG
  set EG.Email = coalesce (M.TargetValue, @vDefaultEmail)
  from @ttEmailGroups EG
    join dbo.fn_GetMappedSet ('CIMS', 'CIMS', 'AlertInvChanges', null, @BusinessUnit) M on (EG.SKUCategory = M.SourceValue);

  /* Loop through each emailgroup and send alerts */
  while exists(select * from @ttEmailGroups where RecordId > @vRecordId)
    begin
      /* process one email group at a time */
      select top 1 @vRecordId    = RecordId,
                   @vEmail       = Email,
                   @vSKUCategory = SKUCategory
      from @ttEmailGroups
      where (RecordId > @vRecordId)
      order by RecordId;

      if object_id('tempdb..#AlertInventoryChanges') is not null
        drop table #AlertInventoryChanges

      /* Insert record of specific email group to send alert */
      select *
      into #AlertInventoryChanges
      from #InventoryChanges
      where (SKUCategory = @vSKUCategory);

      delete from @ttEmailGroups where RecordId = @vRecordId

      /* Proceed to email only if the table has entries */
      if exists(select * from #AlertInventoryChanges)
        exec pr_Email_SendQueryResults @vAlertCategory, '#AlertInventoryChanges', null /* order by */, @BusinessUnit,
                                       @UserId, null/* EmailSubject */, @vEmail;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Alerts_InventoryChanges */

Go
