/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_KPI_ReceiversClosed_Daily') is not null
  drop Procedure pr_KPI_ReceiversClosed_Daily;
Go
/*------------------------------------------------------------------------------
  Proc pr_KPI_ReceiversClosed_Daily: Gather the daily statistics for Receiving
    based upon the Receivers closed for the given date.
------------------------------------------------------------------------------*/
Create Procedure pr_KPI_ReceiversClosed_Daily
  (@ActivityDate       TDate,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin /* pr_KPI_Receiving */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get all the Receiving Exports transactions for the day */
  select distinct ReceiverId, ReceiverNumber, ReceiptId, ReceiptDetailId, Ownership, Warehouse, TransDate
  into #ReceiveExportTransactions
  from Exports
  where (TransDate = @ActivityDate) and (TransType = 'Recv');

  /* Log received details  */
  insert into KPIs (Operation, SubOperation2, ActivityDate, Warehouse, Ownership,
                    NumLocations, NumPallets, NumLPNs, NumInnerPacks, NumUnits,
                    NumReceipts, NumLines, NumSKUs, Count1,
                    BusinessUnit, CreatedBy)
    select 'Receiving', R.VendorName, RET.TransDate, RET.Warehouse, RET.Ownership,
           count(distinct LocationId), count(distinct PalletId), count(distinct LPNId), sum(Innerpacks), sum(Quantity),
           count(distinct RET.ReceiptId), count(distinct RET.ReceiptId), count(distinct SKUId), count(distinct R.ContainerNo),
           @BusinessUnit, @UserId
    from ReceivedCounts RC
      join ReceiptHeaders R on (RC.ReceiptId = R.ReceiptId)
      join #ReceiveExportTransactions RET on (RC.ReceiptId       = RET.ReceiptId) and
                                             (RC.ReceiptDetailId = RET.ReceiptDetailId) and
                                             (RC.ReceiverId      = RET.ReceiverId)
    group by RET.Warehouse, RC.ReceiverId, RET.Ownership, RET.TransDate, R.VendorName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_KPI_ReceiversClosed_Daily */

Go
