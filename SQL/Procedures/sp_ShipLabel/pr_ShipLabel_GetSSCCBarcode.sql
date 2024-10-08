/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/02  RV      pr_ShipLabel_GetSSCCBarcode: Made changes to get the next sequence number from sequences (JLCA-611)
              AY      pr_ShipLabel_GetSSCCBarcode: Use companyid based upon ShipFrom (ACME-412)
  2015/01/14  VM      pr_ShipLabel_GetSSCCBarcode: Correction to generate the right UCCBarcode
  2014/06/13  AY      pr_ShipLabel_GetSSCCBarcode: Enhanced to support Store Label
  2012/09/27  AY      pr_ShipLabel_GetSSCCBarcode: Walmart is using their custome version of
              AY      pr_ShipLabel_GetSSCCBarcode: New procedure to generate appropriate
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetSSCCBarcode') is not null
  drop Procedure pr_ShipLabel_GetSSCCBarcode;
Go
/*------------------------------------------------------------------------------
Proc pr_ShipLabel_GetSSCCBarcode:
  BarcodeTypes are : GS1-128/UCC128 or SSCC14

  UCC 128 barcode: 00 (AI) + 0 (Package) + 1234567 (CompanyId) + 123456789 (SeqNo)  + 1 Check Digit
  SCC14  barcode: 0 (PackageType) + 1234567 (UCC Prefix + ManfCode = CompanyId) + 12345 (SeqNo) + 1 Check Digit
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetSSCCBarcode
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit,
   @LPN               TLPN,
   @BarCodeType       TTypeCode = null,
   ------------------------------------------
   @SSCC_Barcode      TBarcode         output,
   @SSCC_PackageType  TBarcode  = null output,
   @SSCC_CompanyId    TBarcode  = null output,
   @SSCC_SeqNo        TBarcode  = null output,
   @SSCC_CheckDigit   TBarcode  = null output)
as
  declare @vLPNId               TRecordId,
          @vLPNLineCount        TCount,

          @vOrderId             TRecordId,
          @vOrderDetailId       TRecordId,
          @vLabelFormat         TDescription,
          @vShipFrom            TShipFrom,
          @vShipToStore         TShipToStore,
          @vWarehouse           TWarehouseId,

          @vControlCategory     TCategory,
          @vSeqNoCategory       TCategory;
begin
  /* Get LPN Info */
  select @vLPNId     = LPNId,
         @vOrderId   = OrderId,
         @vWarehouse = DestWarehouse
  from LPNs
  where (LPN = @LPN) and
        (BusinessUnit = @BusinessUnit);

  /* Assuming LPN has only one detail */
  select @vLPNLineCount  = count(*),
         @vOrderDetailId = Min(OrderDetailId)
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Get Order Info */
  select @vShipFrom      = ShipFrom,
         @vShipToStore   = ShipToStore,
         @SSCC_CompanyId = ShipFromCompanyId
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* If BarcodeType is not given, from the label format, determine the barcode type */
  if (@BarcodeType is null)
    begin
      select @vLabelFormat = 'ShipLabel';

      select @BarcodeType = labelformats.PrintOptions.value('(/printoptions/barcodetype)[1]','varchar(50)')
      from LabelFormats
      where (LabelFormatName = @vLabelFormat);

      /* If none defined in the label, then default to UCC128 */
      select @BarcodeType = coalesce(@BarcodeType, 'UCC128');
    end

  /* If Order does not specify the CompanyId, use the one for the ShipFrom */
  if (nullif(@SSCC_CompanyId, '') is null)
    begin
      select @vControlCategory = 'SSCCBarcode_' + @vShipFrom;
      select @SSCC_CompanyId = dbo.fn_Controls_GetAsString (@vControlCategory, 'CompanyId', '' /* Default */, @BusinessUnit, @UserId);
    end;

  /* If there is no specific company id to be used for the ShipFrom then use the default */
  if (nullif(@SSCC_CompanyId, '') is null)
    select @SSCC_CompanyId = dbo.fn_Controls_GetAsString ('SSCCBarcode', 'CompanyId', '0000000' /* Default */, @BusinessUnit, @UserId);

  /* Pad CompanyId to desired length - 7 for both UCC128 or SCC14 */
  if (@BarcodeType in ('UCC128', 'SCC14'))
    select @SSCC_CompanyId = dbo.fn_pad(@SSCC_CompanyId, 7 /* Fixed */);

  if (@BarcodeType = 'UCC128')
    begin
      select @SSCC_PackageType = '0';
    end
  else
  if (@BarcodeType = 'SCC14')
    begin
      select @SSCC_PackageType = coalesce(@SSCC_PackageType, '0');
    end

  if (@BarcodeType in ('UCC128', 'SCC14'))
    begin
      /* We will have a different sequence number for each company Id */
      select @vSeqNoCategory = @BarcodeType + '_' + @SSCC_CompanyId;

      /* Get Next SeqNo of SSCC SeqNo */
      exec pr_Controls_GetNextSeqNoStr @vSeqNoCategory, 1 /* Increment */, @UserId, @BusinessUnit, @SSCC_SeqNo output;
    end
  else
  if (@BarcodeType = 'Storelabel')
    begin
      /* Get Next SeqNo of SSCC SeqNo */
      exec pr_Controls_GetNextSeqNoStr 'SSCCBarcode', 1 /* Increment */, @UserId, @BusinessUnit, @SSCC_SeqNo output;
    end

  /* Compute check digit */
  select @SSCC_CheckDigit = dbo.fn_GetMod10CheckDigit(@SSCC_PackageType + @SSCC_CompanyId + @SSCC_SeqNo);

  /* Build the barcode based upon the symbology */
  if (@BarcodeType = 'UCC128')
    set @SSCC_BarCode = '00' + @SSCC_PackageType + @SSCC_CompanyId + @SSCC_SeqNo + @SSCC_CheckDigit;
  else
  if (@BarcodeType = 'SCC14')
    set @SSCC_BarCode = @SSCC_PackageType + @SSCC_CompanyId + @SSCC_SeqNo + @SSCC_CheckDigit;
  else
  if (@BarcodeType = 'StoreLabel')
    set @SSCC_BarCode = right(coalesce(@vShipToStore, '0000'), 4) + @SSCC_CompanyId + @SSCC_SeqNo;
end/* pr_ShipLabel_GetSSCCBarcode */

Go
