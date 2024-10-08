/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/07/13  AY      pr_ShipLabel_SplitSSCCBarcode: Added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_SplitSSCCBarcode') is not null
  drop Procedure pr_ShipLabel_SplitSSCCBarcode;
Go
/*------------------------------------------------------------------------------
Proc pr_ShipLabel_SplitSSCCBarcode:
  BarcodeTypes are : GS1-128/UCC128 or SSCC14

  UCC 128 barcode: 00 (AI) + 0 (Package) + 1234567 (CompanyId) + 123456789 (SeqNo)  + 1 Check Digit
  SCC14  barcode: 0 (PackageType) + 1234567 (UCC Prefix + ManfCode = CompanyId) + 12345 (SeqNo) + 1 Check Digit
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_SplitSSCCBarcode
  (@SSCC_BarCode      TBarcode,
   @BarcodeType       TTypeCode = null,
   ------------------------------------------
   @SSCC_PackageType  TBarcode  = null output,
   @SSCC_CompanyId    TBarcode  = null output,
   @SSCC_SeqNo        TBarcode  = null output,
   @SSCC_CheckDigit   TBarcode  = null output)
as
  declare @vReturnCode           TInteger,
          @vMessageName          TMessageName,

          @vBarcodeLength        TInteger;
begin
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vBarcodeLength = Len(@SSCC_Barcode);

  /* If barcode type is not specified, then figure it out */
  if (@BarcodeType is null) and (@vBarcodeLength = 20)
    set @BarcodeType = 'UCC128';
  else
  if (@BarcodeType is null) and (@vBarcodeLength = 14)
    set @BarcodeType = 'SCC14'

  if (@BarcodeType is null)
    begin
      set @vMessageName = 'InvalidBarcode';
      goto Exithandler;
    end

  /* Based upon the Barcode Type, split the barcode into its components */
  if (@BarcodeType = 'UCC128')
    begin
      select @SSCC_PackageType = substring(@SSCC_Barcode,  3, 1),
             @SSCC_CompanyId   = substring(@SSCC_Barcode,  4, 7),
             @SSCC_SeqNo       = substring(@SSCC_Barcode, 11, 9),
             @SSCC_CheckDigit  = substring(@SSCC_Barcode, 20, 1);
    end
  else
  if (@BarcodeType = 'SCC14')
    begin
      select @SSCC_PackageType = substring(@SSCC_Barcode,  1,  1),
             @SSCC_CompanyId   = substring(@SSCC_Barcode,  2,  7),
             @SSCC_SeqNo       = substring(@SSCC_Barcode,  9,  5),
             @SSCC_CheckDigit  = substring(@SSCC_Barcode, 14, 1);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end/* pr_ShipLabel_SplitSSCCBarcode */

Go
