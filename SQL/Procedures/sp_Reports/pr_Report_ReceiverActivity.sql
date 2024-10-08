/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/10  SK      pr_Report_ReceiverActivity: Remove BusinessUnit append as the calling procedure handles that (CIMSV3-1464)
  2020/11/05  SK      pr_Report_ReceiverActivity: New procedure to track Receivers activity (JL-288)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Report_ReceiverActivity') is not null
  drop Procedure pr_Report_ReceiverActivity;
Go
/*------------------------------------------------------------------------------
  Proc pr_Report_ReceiverActivity:

    This motivation for this procedure is to return Receiver data.
    This procedure should return a new Receiver each time it gets called.
    Hence it will do the following steps
      o ReportActivity table is used to monitor which receiver is sent
      o Inactive receivers that are closed or Update all records as Active to be Processed
      o A record is considered as Processed when its report is sent
------------------------------------------------------------------------------*/
Create Procedure pr_Report_ReceiverActivity
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vRecordId         TRecordId,

          @vRecordCount      TCount,
          @vSequenceName     TName,
          @vSequenceNumber   TInteger,
          @vBusinessUnit     TBusinessUnit,
          @vUserId           TUserId,
          @vReceiverId       TRecordId;

  declare @ttReceivers       TEntityKeysTable;

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get all open receivers list */
  select ReceiverId, ReceiverNumber, row_number() over (order by ReceiverId) as RecordId
  into #Receivers
  from Receivers
  where (Status = 'O' /* Open */)

  /* Get the record count of open Receivers fetched */
  select @vRecordCount = @@rowcount;

  /* Get BusinessUnit value */
  select Top 1 @vBusinessUnit = BusinessUnit,
               @vUserId       = 'cimsadmin',
               @vSequenceName = 'Seq_DaB_TrackReceiver'
  from vwBusinessUnits;

  /* Get the next sequence */
  exec pr_Sequence_GetNext @vSequenceName, default, @vUserId, @vBusinessUnit, @vSequenceNumber output;

  /* Reset if the sequence exceeds the number of open receivers */
  if (@vSequenceNumber > @vRecordCount)
    exec pr_Sequence_RestartGetNext @vSequenceName, null, @vUserId, @vBusinessUnit, @vSequenceNumber output;

  /* Find the Receiver based on the sequence number */
  select @vReceiverId = ReceiverId
  from #Receivers
  where (RecordId = @vSequenceNumber);

  /* Send out the data set */
  select R.ReceiverId                 as ReceiverId,
         min(R.ReceiverNumber)        as ReceiverNumber,
         min(R.Container)             as Container,
         min(R.CreatedDate)           as StartTime,
         datediff(hh, min(R.CreatedDate), getdate())
                                      as TimeElapsedInHours,
         datediff(mi, min(R.CreatedDate), getdate())
                                      as TimeElapsedInMinutes,
         datediff(ss, min(R.CreatedDate), getdate())
                                      as TimeElapsedInSeconds,
         /* Aggregate data */
         coalesce(L.ReceiptNumber, '')
                                      as ReceiptNumber,
         coalesce(L.Status, '')       as LPNStatus,
         coalesce(dbo.fn_Status_GetDescription('LPN', L.Status, L.BusinessUnit), '')
                                      as LPNStatusDesc,
         coalesce(count(L.LPNId), 0)  as NumCartons,
         coalesce(sum(case when L.Status = 'T' then 1 else 0 end), 0)
                                      as NumCartonsInTransit,
         coalesce(sum(case when L.Status in ('J', 'R', 'Z', 'P') then 1 else 0 end), 0)
                                      as NumCartonsScanned
    from Receivers R
      left join LPNs L on R.ReceiverId = L.ReceiverId
    where (R.ReceiverId = @vReceiverId) and
          (coalesce(L.Status, '') in ('N', 'T', 'J', 'R', 'Z', 'P', '')) /* New, InTransit, Receiving, Received, Palletized, Putaway */
    group by R.ReceiverId, L.ReceiptNumber, L.Status, L.BusinessUnit;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Report_ReceiverActivity */

Go
