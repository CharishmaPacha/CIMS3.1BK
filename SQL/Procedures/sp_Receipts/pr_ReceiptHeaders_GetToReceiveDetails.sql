/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/16  AY      pr_ReceiptHeaders_GetToReceiveDetails: Changes to support Receive ASN LPN (CIMSV3-741)
  2019/09/26  TK      pr_ReceiptHeaders_GetToReceiveDetails: Changes to consider InventoryUoM while computing display quantity and UoM (S2GCA-969)
  2018/06/14  TK      pr_ReceiptHeaders_GetToReceiveDetails & pr_ReceiptHeaders_ROClose:
                        Changes to validate SKU Attributes (S2GCAN-26)
  2018/03/06  SV      pr_ReceiptHeaders_GetToReceiveDetails, pr_Receipts_ReceiveInventory, pr_Receipts_ReceiveExternalLPN:
                        Changes to receive the LPN into default loc (S2G-337)
  2018/03/05  AY      pr_ReceiptHeaders_GetToReceiveDetails: Default Qty should be string as it is an option (S2G-338)
  2018/03/01  SV      pr_ReceiptHeaders_GetToReceiveDetails: Calculating the DefaultQty based the UnitsPerInnerPack of the scanned SKU (S2G-316)
  2018/01/17  TK      pr_ReceiptHeaders_GetToReceiveDetails: Return SKU.UPC, SKU.CaseUPC and refractored code (S2G-41)
                      pr_Receipts_ReceiveExternalLPN & pr_Receipts_ValidateExternalLPN: Initial Revision (S2G-20
  2014/07/03  NY      pr_ReceiptHeaders_GetToReceiveDetails: Added coalesce to supress issue from RF.
  2014/03/20  PKS     pr_ReceiptHeaders_GetToReceiveDetails: ReceivingPallet value set in coalesce in return data set.
  2013/09/10  PK      pr_ReceiptHeaders_GetToReceiveDetails: Fix to display Eaches and Cases.
  2013/09/06  PK      pr_ReceiptHeaders_GetToReceiveDetails: Passing DisplayQtyToReceive field by computing based on UoM.
  2013/09/02  PK      Added new procedure pr_ReceiptHeaders_ROClose, pr_ReceiptHeaders_ROReopen to close and reopen
                        receipts and generating exports.
                      pr_ReceiptHeaders_Modify: Modified to call pr_ReceiptHeaders_ROCloseReopen.
              TD      pr_ReceiptHeaders_GetToReceiveDetails:Send QtyToreceive =0 lines as response, but those are
                         end of the result.
  2013/08/27  TD      pr_ReceiptHeaders_GetToReceiveDetails:Sending Warning Message in UDF5, UPC in UDF6.
                      pr_ReceiptHeaders_Modify: Do not allow close of ROs that are not completely received.
  2013/08/24  PK      pr_ReceiptHeaders_GetToReceiveDetails: Added UnitsPerInnerPack.
  2013/08/23  AY      pr_ReceiptHeaders_GetToReceiveDetails: New procedure to return the
                         RO details to be shown on RF.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ReceiptHeaders_GetToReceiveDetails') is not null
  drop Procedure pr_ReceiptHeaders_GetToReceiveDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_ReceiptHeaders_GetToReceiveDetails: This is procedure that is used to show
    the lines to receive for the selected RO. The details shown are based upon the
    Operation. If Operation is 'ReceiveToLPN' then we would use QtyToLabel and
    for ASN Receiving, we would use QtyInTransit as the remaining units.
------------------------------------------------------------------------------*/
Create Procedure pr_ReceiptHeaders_GetToReceiveDetails
  (@ReceiptId          TRecordId,
   @CustPO             TCustPO,
   @PackingSlip        TPackingSlip,
   @ReceivingPallet    TPallet,
   @ReceivingLocation  TLocation,
   @Operation          TOperation,
   @Options            TFlags,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReceiptType           TReceiptType,
          @vDefaultQtyStr         TControlValue,
          @vDefaultQty            TQuantity,
          @vEnableQty             TFlag,

          @vControlCategory       TCategory,
          @vConsiderExtraQty      TControlValue;

  /* We need both QtyToReceive and QtyToLabel. They would be used appropriately
     based upon the RO Type and operation
     QtyToReceive includes IntransitQty
     QtyToLabel   excludes IntransitQty */
  declare @ttReceiptDetails  TReceiptDetails;

begin
  /* Get Receipt info */
  select @vReceiptType = ReceiptType
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  /* set the control category based on the control type */
  select @vControlCategory = 'Receiving_' + @vReceiptType;

  /* if ConsiderExtraQty = N then we only show lines with QtyToLabel > 0  followed by QtyToLabel = 0 lines.
     if ConsiderExtraQty = Y then we show lines where MaxQtyAllowedToReceive > 0 */
  select @vEnableQty        = dbo.fn_Controls_GetAsBoolean(@vControlCategory, 'QtyEnabled',            'N', @BusinessUnit, @UserId),
         @vDefaultQtyStr    = dbo.fn_Controls_GetAsString(@vControlCategory,  'DefaultQty',            'STD', @BusinessUnit, @UserId),
         @vConsiderExtraQty = dbo.fn_Controls_GetAsString(@vControlCategory,  'ConsiderExtraQtyToReceive', 'N' /* No */,@BusinessUnit, @UserId);

  /* DisplayQtyToLabel : Display QtyToLabel and Uom in either or both Inner Packs (CS) and Eaches (EA) */
  insert into @ttReceiptDetails (ReceiptId, ReceiptNumber, ReceiptDetailId, SKU, SKUDescription, DisplaySKU,
                                 UoMDesc, UPC, CaseUPC, UnitsPerInnerPack, InventoryUoM,
                                 QtyOrdered, QtyIntransit, QtyReceived, QtyToReceive, QtyToLabel,
                                 ExtraQtyAllowed, MaxQtyAllowedToReceive, LPNsIntransit, LPNsReceived,
                                 CustPO, ReceivingPallet, ReceivingLocation, ReceiverNumber,
                                 WarningMsg, EnableQty, DefaultQty, UDF1, UDF2)
  select ReceiptId, ReceiptNumber, ReceiptDetailId, SKU, Description,
         (select DisplaySKU from fn_SKUs_GetDisplaySKU (SKU, 'Receiving', @BusinessUnit, @UserId)) /* DisplaySKU */,
         UoMDescription, UPC, CaseUPC, UnitsPerInnerPack, InventoryUoM,
         QtyOrdered, QtyIntransit, QtyReceived, QtyToReceive, QtyToLabel,
         ExtraQtyAllowed, MaxQtyAllowedToReceive, LPNsIntransit, LPNsReceived,
         CustPO, @ReceivingPallet, @ReceivingLocation, @PackingSlip,
         (select WarningMsg = dbo.fn_SKUs_IsOperationAllowed (SKUId, 'ReceiveSKU')) /* WarningMsg */,
         @vEnableQty, case
                        /* Default could be 0 or 1 ie numeric, if so, use it */
                        when IsNumeric(@vDefaultQtyStr) = 1 then
                          cast(@vDefaultQtyStr as integer)
                        /* If not numeric, then we use the StdLPNQty for the SKU or QtyToLabel, whichever is greater */
                        when (UnitsPerInnerPack > 0) and (QtyToLabel >= UnitsPerLPN) then
                           InnerPacksPerLPN  -- default to std lpn InnerPacks only
                        when (UnitsPerInnerPack > 0) and (QtyToLabel > UnitsPerInnerPack) then
                           (QtyToLabel / UnitsPerInnerPack) -- Number of Innerpacks to receive
                        when (QtyToLabel >= UnitsPerLPN) then
                           UnitsPerLPN -- default ot std units per LPN
                        else
                          QtyToLabel -- if nothing else, receive in eaches
                      end,
         SKU5, UPC
  from vwReceiptDetails
  where (ReceiptId = @ReceiptId) and
        (coalesce(CustPO, '')    = coalesce(@CustPO, CustPO, ''));

  /* If we do not consider extra qty, then do not show lines where MaxQtyAllowedToReceive = 9 */
  if (@vConsiderExtraQty = 'N')
    delete from @ttReceiptDetails
    where (MaxQtyAllowedToReceive <= 0);

  /* if ConsiderExtraQty = N then we only show lines with QtyToLabel > 0  followed by QtyToLabel = 0 lines. */
  update @ttReceiptDetails
  set Sortorder = case when @Operation = 'ReceiveToLPN'  and @vConsiderExtraQty = 'N' and QtyToLabel > 0 then '1'
                       when @Operation = 'ReceiveToLPN'  and @vConsiderExtraQty = 'N' then '2'
                       when @Operation = 'ReceiveASNLPN' and QtyInTransit > 0 then '1'
                       when @Operation = 'ReceiveASNLPN' then '2'
                       else '9'
                  end;

  /* Return Data set */
  select ReceiptId, ReceiptNumber, ReceiptDetailId, SKU, coalesce(SKUDescription, SKU) as SKUDescription, DisplaySKU,
         coalesce(DisplayUoM, '') as UoM, coalesce(UPC, '') as UPC, coalesce(CaseUPC, '') as CaseUPC,
         coalesce(UnitsPerInnerPack, 0) as UnitsPerInnerPack,
         QtyOrdered, QtyIntransit, QtyReceived, QtyToReceive, QtyToLabel,
         ExtraQtyAllowed, MaxQtyAllowedToReceive, LPNsIntransit, LPNsReceived,
         coalesce(CustPO, '') as CustPO,
         coalesce(ReceivingPallet, '') as ReceivingPallet, coalesce(ReceivingLocation, '') as ReceivingLocation, coalesce(ReceiverNumber, '') as ReceiverNumber,
         WarningMsg, EnableQty, DefaultQty, UDF1, UDF2
  from @ttReceiptDetails
  order by SortOrder;

end /* pr_ReceiptHeaders_GetToReceiveDetails */

Go
