/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/11  RKC     pr_Alerts_ListOfOrdersToShip, pr_Alerts_OrdersMissingDetailLines,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_ListOfOrdersToShip') is not null
  drop Procedure pr_Alerts_ListOfOrdersToShip;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_ListOfOrdersToShip: This procedure is used get the list of
    Orders which are yet to be shipped/Closed. Because Users need to know which
    are the orders remaining to ship/Close. So we sending alerts to the relevant
    clients to find out about orders that have not yet been closed/shipped.

  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only

  EmailIfNoAlert - N: Would not send any email if there is nothing to alert
                   Y: Would send an email even if there is nothing to alert.
                      A job could be setup to do this once a month so that we know
                      that the job is active and running

  exec pr_Alerts_ListOfOrdersToShip 'BK','cimsadmin','7200','Y','N'
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_ListOfOrdersToShip
  (@BusinessUnit                TBusinessUnit,
   @UserId                      TUserId,
   @ShowModifiedInLastXMinutes  TInteger  = 7200 /* Works for entities which are modified in 5 days */,
   @ReturnDataSet               TFlags    = 'N',
   @EmailIfNoAlert              TFlags    = 'N')
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessage,
          @vRecordId        TRecordId;

  declare @vAlertCategory   TCategory;
begin /* pr_Alerts_ListOfOrdersToShip */
  SET NOCOUNT ON;

  /* Initialize */
  select @vAlertCategory = object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0;

  /* Get the list of Orders which are yet to Ship/Close */
  select PickTicket, OrderType, Status OrderStatus, SalesOrder, CustPO, AccountName, OrderDate, ShipFrom, ShipToName
  into #OrdersToShip
  from OrderHeaders with (nolock)
  where (OrderType not in ('B', 'R', 'RU', 'RP') /* Exclude the Bulk & Replenish orders */) and
        (Archived = 'N') and
        (Status <> 'S' /* Shipped */) and
        (datediff(mi, CreatedDate, getdate()) > @ShowModifiedInLastXMinutes);

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #OrdersToShip;
      return(0);
    end

  /* Email the results, if there are any values captured */
  if (@EmailIfNoAlert = 'Y') or (exists (select * from #OrdersToShip))
    exec pr_Email_SendQueryResults @vAlertCategory, '#OrdersToShip', null /* order by */, @BusinessUnit;
end /* pr_Alerts_ListOfOrdersToShip */

Go
