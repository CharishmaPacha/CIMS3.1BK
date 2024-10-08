/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/06  RKC     pr_Alerts_Orders_StuckInDownload, pr_Alerts_OrdersMissingDetailLines, pr_Alerts_OrdersMissingShipToInfo: Consider PreProcessError status as well (OBV3-1559)
                      pr_Alerts_OrdersMissingShipToInfo: Initial revision (BK-638)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_OrdersMissingShipToInfo') is not null
  drop Procedure pr_Alerts_OrdersMissingShipToInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_OrdersMissingShipToInfo: This procedure is used to retrieve a
    list of orders which are missing the ShipTo information and send an alert
    to a specific client. So that client can correct them and re-process them.

  @ReturnDataSet
    - Can be set to 'Y' when called EXCLUSIVELY from TSQL.
    - Ignores sending Alert
    - Returns dataset only

  EmailIfNoAlert - N: Would not send any email if there is nothing to alert
                   Y: Would send an email even if there is nothing to alert.
                      A job could be setup to do this once a month so that we know
                      that the job is active and running

  exec pr_Alerts_OrdersMissingShipToInfo 'BK','cimsadmin','5','Y','N'
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_OrdersMissingShipToInfo
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
begin /* pr_Alerts_OrdersMissingShipToInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vAlertCategory = object_Name(@@ProcId), -- pr_ will be trimmed by pr_Email_SendDBAlert
         @vRecordId      = 0;

  /* Get the list of Orders which are missing the ShipTo informations */
  select PickTicket, OrderType, SalesOrder, CustPO, Account, AccountName, ShipFrom, ShipToName, Message as ErrorMessage
  into #OrdersMissingShipToInfo
  from OrderHeaders OH    with (nolock)
     join Notifications N with (nolock) on (OH.OrderId   = N.EntityId) and
                                           (N.EntityType = 'Order') and
                                           (N.Operation  = 'OrderPreprocess')
  where (OH.Status = 'O' /* Downloaded */) and
        (OH.Archived = 'N') and
        (N.Status     = 'A') and
        (N.Message like '%Ship%') and /* Get the missing ShipTo information orders */
        (datediff(mi, OH.CreatedDate, getdate()) > @ShowModifiedInLastXMinutes)

  /* Return dataset, if @ReturnDataSet set 'Y' - EXCLUSIVE for TSQL */
  if (@ReturnDataSet = 'Y')
    begin
      select * from #OrdersMissingShipToInfo;
      return(0);
    end

  /* Email the results, if there are any values captured */
  if (@EmailIfNoAlert = 'Y') or (exists (select * from #OrdersMissingShipToInfo))
    exec pr_Email_SendQueryResults @vAlertCategory, '#OrdersMissingShipToInfo', null /* order by */, @BusinessUnit;
end /* pr_Alerts_OrdersMissingShipToInfo */

Go
