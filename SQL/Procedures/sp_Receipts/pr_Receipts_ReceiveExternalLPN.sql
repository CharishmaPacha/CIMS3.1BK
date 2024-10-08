/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/06  SV      pr_ReceiptHeaders_GetToReceiveDetails, pr_Receipts_ReceiveInventory, pr_Receipts_ReceiveExternalLPN:
                        Changes to receive the LPN into default loc (S2G-337)
  2018/01/17  TK      pr_ReceiptHeaders_GetToReceiveDetails: Return SKU.UPC, SKU.CaseUPC and refractored code (S2G-41)
                      pr_Receipts_ReceiveExternalLPN & pr_Receipts_ValidateExternalLPN: Initial Revision (S2G-20)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_ReceiveExternalLPN') is not null
  drop Procedure pr_Receipts_ReceiveExternalLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_ReceiveExternalLPN: This procedure evaluates whether the scanned
    LPN is valid to receive or not, if it is a valid LPN than it creates an LPN in
    cIMS and return the LPNId to the caller
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_ReceiveExternalLPN
  (@ReceiptId        TRecordId,
   @LocationId       TRecordId,
   @LPN              TLPN,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   ----------------------------------
   @ExternalLPNId    TRecordId output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,

          @vReceiptId            TRecordId,
          @vReceiptType          TTypeCode,
          @vVendorId             TVendorId,
          @vOwnership            TOwnership,
          @vROWarehouse          TWarehouse,
          @vLPNWarehouse         TWarehouse,
          @vLocWarehouse         TWarehouse,
          @vGeneratedLPNId       TRecordId,

          @vControlCategory      TCategory,
          @vReceiveToWHOption    TControlValue,

          @vIsValidLPN           TFlags,
          @vXmlData              TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Receipt info */
  select @vReceiptId    = ReceiptId,
         @vReceiptType  = ReceiptType,
         @vVendorId     = VendorId,
         @vOwnership    = Ownership,
         @vROWarehouse  = Warehouse
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  select @vLocWarehouse = Warehouse
  from Locations
  where (LocationId = @LocationId);

 /* set the control category based on the control type */
  select @vControlCategory = 'Receiving_' + @vReceiptType;
  select @vReceiveToWHOption = dbo.fn_Controls_GetAsString(@vControlCategory, 'ReceiveToWarehouse', 'LOC', @BusinessUnit, @UserId);

  /* Determine the Warehouse for the LPN i.e. is it Locations' WH or RO WH? */
  select @vLPNWarehouse = case when @vReceiveToWHOption = 'LOC' then @vLocWarehouse else @vROWarehouse end;

  /* Build xml to evaluate Rules */
  select @vXmlData = dbo.fn_XMLNode('RootNode',
                          dbo.fn_XMLNode('ReceiptId',       @vReceiptId) +
                          dbo.fn_XMLNode('VendorId',        @vVendorId)  +
                          dbo.fn_XMLNode('Ownership',       @vOwnership) +
                          dbo.fn_XMLNode('Warehouse',       @vLPNWarehouse) +
                          dbo.fn_XMLNode('BusinessUnit',    @BusinessUnit));

  /* check whether the scanned external LPN is valid or not */
  exec pr_Receipts_ValidateExternalLPN @vXmlData, @LPN, @BusinessUnit, @vIsValidLPN output;

  /* Generate a new LPN */
  if (@vIsValidLPN = 'Y')
    exec @vReturnCode = pr_LPNs_Generate default /* @LPNType */,
                                         1       /* @NumLPNsToCreate */,
                                         @LPN    /* @LPNFormat - will take default */,
                                         @vLPNWarehouse,
                                         @BusinessUnit,
                                         @UserId,
                                         @vGeneratedLPNId    output;

  if (@vReturnCode > 0)
    goto ExitHandler;

  set @ExternalLPNId = @vGeneratedLPNId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_ReceiveExternalLPN */

Go
