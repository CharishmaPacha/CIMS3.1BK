/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/19  TK      pr_LPNs_CreateLPNs & pr_LPNs_SplitLPN: Changes to update ReceiverId on LPNs
                      pr_LPNs_Delete & pr_LPNs_UndoReceipt: Clear ReceiverId on LPNs (S2GMI-140)
  2015/12/28  VM      pr_LPNs_Delete: Archive the deleted LPN to not to show in UI (FB-583)
  2015/04/25  VM      pr_LPNs_Delete: Clear Receipt/Order/PB info on deleted LPN
  2015/04/14  VM      pr_LPNs_Delete: Clear Receipt/Order info on LPNDetails as well
  2011/10/14  PK/AY   pr_LPNs_Delete: Use LPNId only for Deletes as there could be
  2011/10/10  AY      pr_LPNs_Delete: Mark LPNDetails unavailable as well.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Delete') is not null
  drop Procedure pr_LPNs_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Delete:
    Parameter LPN has been removed on purpose as just the LPN is not sufficient
    to uniquely identify the LPN to Delete - like in a Picklane with mulitple
    SKUs, there could be several records with same LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Delete
  (@LPNId     TRecordId)
as
begin
  SET NOCOUNT ON;

  /* Change the LPN so that many selection which select by Location do not
     fetch this LPN */
  update LPNs
  set @LPNId         = LPNId,
      LPN            = LPN +'.',
      LocationId     = null,
      Location       = null,
      ReceiptId      = null,
      ReceiptNumber  = null,
      ReceiverId     = null,
      ReceiverNumber = null,
      OrderId        = null,
      PickTicketNo   = null,
      SalesOrder     = null,
      PickBatchId    = null,
      PickBatchNo    = null,
      Status         = 'I' /* Inactive */,
      OnhandStatus   = 'U' /* Unavailable */,
      UniqueId       = '$' + cast(LPNId as varchar),
      Archived       = 'Y' /* Yes */
  where (LPNId = @LPNId);

  /* Update LPNDetails as unavailable as well - LPNDetails are sometimes used
     independently and so it is prudent to make them unavailable as well and
     also clear Receipt and Order info on them */
  update LPNDetails
  set  ReceiptId       = null,
       ReceiptDetailId = null,
       OrderId         = null,
       OrderDetailId   = null,
       OnhandStatus    = 'U' /* unavailable */
  where (LPNId = @LPNId);

end /* pr_LPNs_Delete */

Go
