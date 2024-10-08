/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_LPNs_SetStatus: Updating the LPNDetails OnhandStatus as Available for the In-Transit status LPNs (HA-1246).
  pr_LPNs_SetStatus: removed the chnage (FB-1874)
  pr_LPNs_SetStatus: Ported back from Stag onsite (FB-992)
  2015/06/10  AY      pr_LPNs_SetStatus: Changed to not revert LPN Status from F to N on Temp labels
  2015/05/12  AY      pr_LPNs_SetStatus: Changed to not transition from Intransit to
  pr_LPNs_SetStatus: Bug Fix for not updating reserve line.
  2103/05/22  TD      pr_LPNs_SetStatus: Set status to New when LPN type is 'TO' and qty = 0.
  2012/10/01  AA      pr_LPNs_Unallocate: fixed passing incorrect variable to pr_LPNs_SetStatus procedure
  2012/06/04  AY      pr_LPNs_SetStatus: Corrected to not move status from New to
  2012/05/28  AY      pr_LPNs_SetStatus: Code optimization
  2011/11/01  VM      pr_LPNs_Recount, pr_LPNs_SetStatus:
  pr_LPNs_SetStatus: Update Modified Date.
  pr_LPNs_SetStatus: Set LPNPutawayDate for Putaway LPN
  2011/03/11  VM      pr_LPNs_SetStatus: Consider the progression from InTransit
  pr_LPNs_SetStatus:
  pr_LPNs_SetStatus: Returns the new Onhand Status
  2011/01/21  VM      pr_LPNs_SetStatus: Modified to udpate OnhandStatus and correction made to set stuatus.
  2010/12/10  VM      Added pr_LPNs_SetStatus.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_SetStatus') is not null
  drop Procedure pr_LPNs_SetStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_SetStatus:
    This procedure is used to change/set the 'Status' of the LPN and also calculates
    the 'OnhandStatus' of the LPN based on LPNDetails 'OnhandStatus'.

    Status:
     . If status is provided, it updates directly with the given status
     . If status is not provided - it calculates the status updates.

    OnhandStatus:
     . If OnhandStatus of '-' is given then it is not changed
     . If any of the LPNDetails 'OnhandStatus' is '(A)vailable'   - '(A)vailable'
     . If all of the LPNDetails 'OnhandStatus' is '(R)eserved'    - '(R)eserved'
     . If all of the LPNDetails 'OnhandStatus' is '(U)navailable' - '(U)navailable'
     . If any of the LPNDetails 'OnhandStatus' is '(R)eserved' in case
                                                  '(R)eserved' and '(U)navailable' LPNDetails
                                                                  - '(R)eserved'
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_SetStatus
  (@LPNId        TRecordId,
   @Status       TStatus = null output,
   @OnhandStatus TStatus = null output)
as
  declare @ReturnCode                  TInteger,
          @MessageName                 TMessageName,
          @Message                     TDescription,

          @vLPNType                    TTypeCode,
          @vLPNDetailsAvailableCount   TCount,
          @vLPNDetailsReservedCount    TCount,
          @vLPNDetailsUnavailableCount TCount,
          @vQuantity                   TQuantity,
          @vOldStatus                  TStatus,
          @vReceivedUnits              TQuantity,
          @vUnavailableUnits           TQuantity;
begin
  SET NOCOUNT ON;

  select @ReturnCode = 0,
         @MessageName = null;

  /* Calculate Onhand status if not already determined by caller */
  if (@OnhandStatus is null)
    begin
      /* Calculate the Onhandstatus counts of each status */
      select @vLPNDetailsAvailableCount   = sum(case when OnhandStatus = 'A' then 1 else 0 end),
             @vLPNDetailsReservedCount    = sum(case when OnhandStatus = 'R' then 1 else 0 end),
             @vLPNDetailsUnavailableCount = sum(case when OnhandStatus = 'U' then 1 else 0 end)
      from LPNDetails
      where (LPNId = @LPNId);

      /* Compute the LPNs' OnhandStatus based upon the OnhandStatus of the Details */
      select @OnhandStatus = case
                               when (@vLPNDetailsAvailableCount > 0) then
                                 'A' /* Available */
                               when (@vLPNDetailsReservedCount > 0) then
                                 'R' /* Reserved */
                               else
                                 'U' /* Unavailable */
                             end;
    end
  else
    /* If caller passed in - then there is no change requested by caller, so null it
       so that the current status is retained */
    select @OnhandStatus = nullif(@OnhandStatus, '-');

  ----------------------------------------------------------------------------

  /* Calculate Status, if not provided */
  if (@Status is null)
    begin
      select @vOldStatus = Status,
             @vQuantity  = Quantity,
             @vLPNType   = LPNType
      from LPNs
      where (LPNId = @LPNId);

      select @vReceivedUnits    = sum(ReceivedUnits),
             @vUnavailableUnits = sum(case when OnhandStatus = 'U' then Quantity else 0 end)
      from LPNDetails
      where (LPNId = @LPNId);

      set @Status = Case @OnhandStatus
                      when ('A' /* Available */) then 'P' /* Putaway */
                      when ('R' /* Reserved */) then
                        case when (@vOldStatus in ('F' /* New Temp */, 'P' /* Putaway */)) then
                          'A' /* Allocated */
                        else
                          coalesce(@Status, @vOldStatus) /* No Change */
                        end
                      when ('U' /* Unavailable */) then
                        Case
                          when (@vQuantity = 0) and
                               (@vLPNType in ('A' /* Cart */, 'TO' /* Tote */))  then 'N' /* New */
                          when (@vQuantity  = 0) and
                               (@vLPNType <> 'L' /* Logical */) then 'C' /* Consumed */
                          when (@vQuantity  = 0) and
                               (@vLPNType =  'L' /* Logical */) then 'P' /* Putaway */
                          when (@vOldStatus = 'F' /* Temp label */) and
                               (@vQuantity = @vUnavailableUnits) then 'F' /* No change when Temp labels are created with Unavailable lines */
                          when (@vQuantity  > 0) and
                               (@vOldStatus = 'F' /* Temp Label */) then 'N' /* New */
                          /* The received units is updated when the LPN is created in Intransit status and so this should
                             arbitrarily consider it received as LPN may be updated while still in transit */
                          --when (coalesce(@vReceivedUnits, 0) > 0) and
                          --     (@vOldStatus = 'T' /* InTransit */) then 'R' /* Received */
                          --when (@vQuantity  > 0)              then 'O' /* Lost */
                        end
                    end
    end
  else
  if (@Status = 'P' /* Putaway */) and (coalesce(@vLPNDetailsReservedCount, 0) = 0)
    begin
      /* set all detail lines and LPN's OnhandStatus to 'Available' */
      update LPNDetails
      set OnhandStatus    = 'A' /* Available */,
          LastPutawayDate = current_timestamp
      where (LPNId = @LPNId);

      set @OnhandStatus = 'A' /* Available */;
    end
  else
  if (@Status in ('A' /* Allocated */, 'K' /* Picked */))
    begin
      /* This is not right place to do this, when the Detail is updated with
         OrderId and OrderDetailId, OnhandStatus also should be updated.
         I've now changed to do so, but will leave this code until after demo - AY */
      /* set all detail lines and LPN's OnhandStatus to 'Reserved' */
      update LPNDetails
      set OnhandStatus = 'R' /* Reserved */
      where (LPNId = @LPNId);

      set @OnhandStatus = 'R' /* Reserved */;
    end
  else
  if (@Status in ('C' /* Consumed */, 'S' /* Shipped */, 'O' /* Lost */))
    begin
      /* set all detail lines and LPN's OnhandStatus to 'Unavailable' */
      update LPNDetails
      set OnhandStatus = 'U' /* Unavailable */
      where (LPNId = @LPNId);

      set @OnhandStatus = 'U' /* Unavailable */;
    end
  else
  if (@Status in ('T'/* In-Transit */) and (@OnhandStatus = 'A'/* Available */))
    begin
      /* Update LPNDetails OnhandStatus as Available */
      update LPNDetails
      set OnhandStatus = 'A' /* Available */
      where (LPNId = @LPNId);
    end

  /* Update LPN */
  update LPNs
  set OnhandStatus = coalesce(@OnhandStatus, OnhandStatus),
      @Status      =
      Status       = coalesce(@Status, Status),
      Archived     = case when coalesce(@OnhandStatus, OnhandStatus) in ('A', 'R') and Archived = 'Y' then 'N' else Archived end,
      ModifiedDate = current_timestamp
  where (LPNId = @LPNId);

ErrorHandler:
  exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_SetStatus */

Go
