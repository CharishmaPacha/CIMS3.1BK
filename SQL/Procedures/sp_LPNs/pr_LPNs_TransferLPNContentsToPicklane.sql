/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

                      pr_LPNs_TransferLPNContentsToPicklane: Clearing output variables (HA-1246).
  2020/07/26  TK      pr_LPNs_Action_BulkMove, pr_LPNs_BulkMove & pr_LPNs_TransferLPNContentsToPicklane:
                      pr_LPNs_TransferLPNContentsToPicklane: Initial Revision (HA-1182)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_TransferLPNContentsToPicklane') is not null
  drop Procedure pr_LPNs_TransferLPNContentsToPicklane;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_TransferLPNContentsToPicklane:Transer the LPN Contents to the picklane
  Location
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_TransferLPNContentsToPicklane
  (@FromLPNId          TRecordId,
   @ToLocationId       TRecordId,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,
          @vRecordId                TRecordId,
          @vSKUId                   TRecordId,
          @vLPNId                   TRecordId,
          @vToLPNId                 TRecordId,
          @vToLPNDetailId           TRecordId,
          @vPAInnerPacks            TInnerPacks,
          @vPAQuantity              TQuantity;

  declare @ttLPNDetails             TLPNDetails;

begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId     = 0;

  /* Create temp tables */
  select * into #LPNDetailsToXFer from @ttLPNDetails

  /* Get all the LPN Details for the given LPN */
  insert into #LPNDetailsToXFer (LPNDetailId, LPNId, LPN, SKUId, InnerPacks, Quantity, ProcessedFlag)
    select LPNDetailId, LD.LPNId, L.LPN, LD.SKUId, LD.InnerPacks, LD.Quantity, 'N'
    from LPNDetails LD
      join LPNs L on (LD.LPNId = L.LPNId)
    where (L.LPNId = @FromLPNId);

  /* Loop thru each LPNDetails and putaway LPNDetail to new location */
  while exists (select * from #LPNDetailsToXFer where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId      = RecordId,
                   @vLPNId         = LPNId,
                   @vSKUId         = SKUId,
                   @vPAInnerPacks  = InnerPacks,
                   @vPAQuantity    = Quantity
      from #LPNDetailsToXFer
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Invoke proc to move each LPN Detail to the corresponding new pick lane location */
      exec @vReturnCode = pr_Putaway_LPNContentsToPicklane @vLPNId,
                                                           @vSKUId,
                                                           @vPAInnerPacks,
                                                           @vPAQuantity,
                                                           @ToLocationId,
                                                           @BusinessUnit,
                                                           @UserId,
                                                           @vToLPNId output,
                                                           @vToLPNDetailId output;

      /* Clear output variables */
      select @vToLPNId = null, @vToLPNDetailId = null;
    end /* Loop end */

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_TransferLPNContentsToPicklane */

Go
