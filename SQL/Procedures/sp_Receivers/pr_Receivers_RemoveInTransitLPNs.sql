/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/02  MS      pr_Receivers_AutoCreateReceiver: Changes to send ContainerNo in Rules (JL-287)
                      pr_Receivers_Close, pr_Receivers_RemoveInTransitLPNs: Changes to Send RI in Receiver Close
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_RemoveInTransitLPNs') is not null
  drop Procedure pr_Receivers_RemoveInTransitLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_RemoveInTransitLPNs: When a Receiver is closed, we may want
    to remove the Intransit LPNs from the Receiver and alo send REJECT RIs to
    WCS as those LPNs wouldn't be received anymore and even if they were received
    in future, they may not be for the same lane.
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_RemoveInTransitLPNs
  (@BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vRecordId        TRecordId;

begin
  SET NOCOUNT ON;

  /* Get all Intransit LPNs of selected Receipts */
  select L.LPNId, L.LPN, L.LPN RouteLPN, L.DestLocation
  into #RouterLPNs
  from LPNs L join #Receivers R on (L.ReceiverNumber = R.ReceiverNumber)
  where (L.Status = 'T' /* InTransit */)

  /* Clear Receivers Info on InTransit LPNs */
  update L
  set L.ReceiverNumber = null,
      L.ReceiverId     = null
  from LPNs L join #RouterLPNs RL on (L.LPNId = RL.LPNId)

  /* Clear Receivers Info on ReceivedCounts */
  update RC
  set ReceiverNumber = null,
      ReceiverId     = null
  from ReceivedCounts RC join #RouterLPNs RL on (RC.LPNId = RL.LPNId)

  /* Update existing RouterInstructions for the LPNs that are not yet processed */
  update RI
  set ExportStatus = 'I'
  from RouterInstruction RI join #RouterLPNs L on (RI.LPNId = L.LPNId)
  where (RI.ExportStatus = 'N' /* Not Processed */);

  /* Send REJECT for all InTransit LPNs */
  exec pr_Router_SendRouteInstruction null, null, default, 'REJECT' /* Destination */, @BusinessUnit = @BusinessUnit, @UserId = @UserId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_RemoveInTransitLPNs */

Go
