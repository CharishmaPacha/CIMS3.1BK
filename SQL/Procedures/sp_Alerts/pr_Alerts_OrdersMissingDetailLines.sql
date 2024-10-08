/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/11  RKC     pr_Alerts_ListOfOrdersToShip, pr_Alerts_OrdersMissingDetailLines,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_OrdersMissingDetailLines') is not null
  drop Procedure pr_Alerts_OrdersMissingDetailLines;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_OrdersMissingDetailLines: This procedure is used to retrieve
    a list of orders that have missed Orderdetails lines for more than an hour
    after being imported from CIMSDE.For this reason the order is not processed
    and still shows download status.
    We cannot process the further further with those orders. So we are sending
    an alert about this so that can find out if there is anything like that and fix it.

  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only

  EmailIfNoAlert - N: Would not send any email if there is nothing to alert
                   Y: Would send an email even if there is nothing to alert.
                      A job could be setup to do this once a month so that we know
                      that the job is active and running

  exec pr_Alerts_OrdersMissingDetailLines 'BK','cimsadmin','5','Y','N'
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_OrdersMissingDetailLines
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 5 /* Orders not off download in 5 mins */,
   @ReturnDataSet               TFlags    = 'N',
   @EmailIfNoAlert              TFlags    = 'N')
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessage,
          @vRecordId        TRecordId;

  declare @vAlertCategory   TCategory;
begin /* pr_Alerts_OrdersMissingDetailLines */
  SET NOCOUNT ON;

  /* Initialize */
  select @vAlertCategory = object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0;

  /* Get the list of Orders which are missing the detail lines or not imported the OD lines */
  select PickTicket, OrderType, SalesOrder, CustPO, Account, AccountName, ShipFrom, ShipToName
  into #OrdersMissingDetilLines
  from OrderHeaders with (nolock)
  where (Status = 'O' /* Downloaded */) and
        (Archived = 'N') and
        ((NumLines = 0 ) or ((HostNumLines > 0) and (HostNumLines <> Numlines))) and
        (datediff(mi, CreatedDate, getdate()) > @ShowModifiedInLastXMinutes)

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #OrdersMissingDetilLines;
      return(0);
    end

  /* Email the results, if there are any values captured */
  if (@EmailIfNoAlert = 'Y') or (exists (select * from #OrdersMissingDetilLines))
    exec pr_Email_SendQueryResults @vAlertCategory, '#OrdersMissingDetilLines', null /* order by */, @BusinessUnit;
end /* pr_Alerts_OrdersMissingDetailLines */

Go
