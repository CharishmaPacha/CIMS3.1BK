/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/09  MS      pr_Receipts_Action_PrepareForSortation: Code optimized and cleanup (JL-286, JL-287)
                      pr_Receipts_Action_ActivateRouting: Changes to create receivers (JL-286, JL-287)
                      pr_Receipts_CreateReceivers: Added new proc to create receivers for given LPNs (JL-286, JL-287)
                      pr_Receipts_UnPalletize: Corrections to send RouteLPN aswell, to be in consistent with #RouterLPNs activated earlier
                      pr_ReceivedCounts_AddOrUpdate: Changes to update ReceiverNumber on existing ReceivedCounts (JL-286, JL-287)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_CreateReceivers') is not null
  drop Procedure pr_Receipts_CreateReceivers;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_CreateReceivers:
   Proc will create receivers for the given LPNs and will update Receiverinfo
   on LPNs. Expecation is caller will send #LPNsPalletized table with list of LPNs
   which are already Palletized

  #LPNsPalletized - TEntityValuesTable
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_CreateReceivers
  (@BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vRecordId       TRecordId,

          @vReceiptId      TRecordId,
          @vCustPO         TCustPO,
          @vLocationId     TRecordId,
          @vReceiverId     TRecordId,
          @vReceiverNumber TReceiverNumber;

begin /* pr_Receipts_CreateReceivers */
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordId     = 0;

  /* Get selected Receipts info */
  select RD.ReceiptId, RD.CustPO, row_number() over (order by RD.ReceiptId) RecordId
  into #ReceiptsInfo
  from #LPNsPalletized LP
    join LPNDetails     LD on (LD.LPNId           = LP.EntityId)
    join ReceiptDetails RD on (RD.ReceiptDetailId = LD.ReceiptDetailId)
  group by RD.ReceiptId, RD.CustPO;

  /* Create receivers for selected Receipts if receiver does not exist */
  while (exists (select * from #ReceiptsInfo where RecordId > @vRecordId))
    begin
      select top 1 @vReceiptId = ReceiptId,
                   @vCustPO    = CustPO,
                   @vRecordId  = RecordId
      from #ReceiptsInfo
      where (RecordId > @vRecordId);

      exec pr_Receivers_AutoCreateReceiver @vReceiptId, @vCustPO, @vLocationId, @BusinessUnit, @UserId,
                                           @vReceiverId output, @vReceiverNumber output;

      /* ReceivedCounts: Update respective LPNs of the Receipts with Receiver info */
      update RC
      set RC.ReceiverId     = @vReceiverId,
          RC.ReceiverNumber = @vReceiverNumber
      from ReceivedCounts RC
        join #LPNsPalletized LP on (RC.LPNId = LP.EntityId)
      where (RC.ReceiptId = @vReceiptId);

      /* LPNs: Update respective LPNs of the Receipts with Receiver info */
      update L
      set L.ReceiverId     = @vReceiverId,
          L.ReceiverNumber = @vReceiverNumber
      from LPNs L
        join #LPNsPalletized LP on (L.LPNId = LP.EntityId)
      where (L.ReceiptId = @vReceiptId); -- should really use CustPO as well
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_CreateReceivers */

Go
