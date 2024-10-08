/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/23  VS      pr_OrderHeaders_AutoCancel: Do not cancel the Order until Order is PreProcessed (CID-1400)
  2018/04/16  SV      pr_OrderHeaders_AutoCancel: Added new procedure (HPI-1849)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_AutoCancel') is not null
  drop Procedure pr_OrderHeaders_AutoCancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_AutoCancel: Procedure to be used to cancel all the Orders
    which are downloaded 5 mins ago and still having unequal HostNumLines and
    NumLines over it. This is being called in a sql named HPI_cIMSStaging_OrderAutoCancel
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_AutoCancel
  (@BusinessUnit  TBusinessUnit,
   @Operation     TOperation = null)
as
  declare @ttOrdersToCancel table
          (RecordId     Integer Identity(1,1),
           OrderId      TRecordId,
           PickTicket   TPickTicket,
           ReasonCode   TReasonCode);

  declare @vRecordId         TRecordId,
          @vOrderId          TRecordId,
          @vPickTicket       TPickTicket,
          @vRulesDataXML     TXml,
          @vActivityDateTime TDateTime,
          @vReasonCode       TReasonCode;
begin
  select @vRecordId   = 0;

  /* Create Temp table */
  select * into #OrdersToCancel from @ttOrdersToCancel;

  /* Build the data for rule evaluation */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                             dbo.fn_XMLNode('Operation',                 @Operation));

  /* Use the rules to determine which orders have to be cancelled and for what reason */
  exec pr_RuleSets_ExecuteRules 'Orders_AutoCancel' /* RuleSetType */, @vRulesDataXML;

  /* Loop thru the temp table to pass the Order info which needs to be cancelled */
  while (exists(select * from #OrdersToCancel where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId   = RecordId,
                   @vOrderId    = OrderId,
                   @vPickTicket = PickTicket,
                   @vReasonCode = ReasonCode
      from #OrdersToCancel
      where (RecordId > @vRecordId)
      order by RecordId;

      exec pr_OrderHeaders_CancelPickTicket @vOrderId, @vPickTicket, @vReasonCode /* System Canceled - ReasonCode */,
                                            @BusinessUnit, 'CIMSAgent' /* UserId */;

      /* Both Exports and AT is being logged in the pr_OrderHeaders_AfterClose which
         gets subsequently called in pr_OrderHeaders_CancelPickTicket */
    end

end /* pr_OrderHeaders_AutoCancel */

Go
