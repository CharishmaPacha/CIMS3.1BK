/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/09  MS      pr_Receipts_Action_PrepareForSortation: Code optimized and cleanup (JL-286, JL-287)
                      pr_Receipts_Action_ActivateRouting: Changes to create receivers (JL-286, JL-287)
                      pr_Receipts_CreateReceivers: Added new proc to create receivers for given LPNs (JL-286, JL-287)
                      pr_Receipts_UnPalletize: Corrections to send RouteLPN aswell, to be in consistent with #RouterLPNs activated earlier
                      pr_ReceivedCounts_AddOrUpdate: Changes to update ReceiverNumber on existing ReceivedCounts (JL-286, JL-287)
  2020/09/22  MS      pr_Receipt_Actions_PrepareForSortation: Made changes to Send RI only if user selected
                      pr_Receipts_UnPalletize: Made changes to send REJECT RI, only if there are active RI
                      pr_Receipts_Action_ActivateForRouting: Added proc to Activate Cartons for Routing (JL-251)
  2020/09/13  MS      Renamed pr_Receipts_PrepareForSortation as pr_Receipts_Action_PrepareForSortation
                      pr_Receipt_Actions_PrepareForSortation, pr_Receipts_UnPalletize: Enhanced changes to consider ReceiptDetails for Sortation (JL-236)
  2020/03/06  MS      pr_Receipts_UnPalletize: Added new proc to clear the existing pallets of receipt
                      pr_Receipts_PrepareForSortation: Made changes to call pr_Receipts_UnPalletize (JL-128)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_UnPalletize') is not null
  drop Procedure pr_Receipts_UnPalletize;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_UnPalletize: This proc is to clear all Empty and InTransit
  pallets of the given LPNs (#LPNsInTransit)

  #LPNInTransit: TEntityKeysTable
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_UnPalletize
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vRecordId     TRecordId;

  declare @ttPallets     TEntityKeysTable;

  declare @ttLPNsInfo table(LPNId        TRecordId,
                            LPN          TLPN,
                            RouteLPN     TLPN,
                            PalletId     TRecordId,
                            DestLocation TVarchar);
begin /* pr_Receipts_UnPalletize */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Create structure for #ClearLPNs */
  select * into #ClearLPNs  from @ttLPNsInfo;
  select * into #RouterLPNs from @ttLPNsInfo;

  /* Clear the Pallet on LPNs, if LPN has PalletId */
  update L
  set PalletId = null,
      Pallet   = null
  output Deleted.LPNId, Deleted.LPN, Deleted.LPN, Deleted.PalletId, Deleted.DestLocation into #ClearLPNs
  from LPNs L
    join #LPNsInTransit LIT on (L.LPNId = LIT.EntityId)
  where (coalesce(L.PalletId, 0) <> 0);

  /* Insert all the pallets which are empty and InTransit */
  insert into @ttPallets (EntityId)
    select distinct CL.PalletId
    from #ClearLPNs CL;

  /* Recount all Pallets */
  exec pr_Pallets_Recount @ttPallets, @BusinessUnit, @UserId;

  /* Delete the pallets */
  delete P from Pallets P join @ttPallets TP on (P.PalletId = TP.EntityId)
  where (P.Status in ('E' /* Empty */, 'T' /* InTransit */))

  /* Update existing RouterInstructions for the LPNs that are not yet processed */
  update RI
  set ExportStatus = 'I'
  /*------------------------------------------*/
  output L.LPNId, L.LPN, L.LPN, L.DestLocation
  into #RouterLPNs (LPNId, LPN, RouteLPN, DestLocation)
  /*------------------------------------------*/
  from RouterInstruction RI join #ClearLPNs L on (RI.LPNId = L.LPNId)
  where (RI.ExportStatus = 'N' /* Not Processed */);

  /* Send REJECT for all the LPNs, they could very well be new instructions sent right after */
  exec pr_Router_SendRouteInstruction null, null, default, 'REJECT' /* Destination */, @BusinessUnit = @BusinessUnit, @UserId = @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_UnPalletize */

Go
