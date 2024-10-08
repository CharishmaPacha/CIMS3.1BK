/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/31  TK      pr_ShipLabel_GenerateUCCBarcodes: pad sequence no max length (HA-2471)
  2021/03/28  TK      pr_ShipLabel_GenerateUCCBarcodes: Code optimization (HA-2471)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GenerateUCCBarcodes') is not null
  drop Procedure pr_ShipLabel_GenerateUCCBarcodes;
Go
/*------------------------------------------------------------------------------
Proc pr_ShipLabel_GenerateUCCBarcodes: Generates UCCBarcodes for all the LPNs
  listed in #LPNShipLabels

  BarcodeTypes are : GS1-128/UCC128 or SSCC14

  #LPNShipLabels: TLPNShipLabelData

  UCC 128 barcode: 00 (AI) + 0 (Package) + 1234567 (CompanyId) + 123456789 (SeqNo)  + 1 Check Digit
  SCC14  barcode: 0 (PackageType) + 1234567 (UCC Prefix + ManfCode = CompanyId) + 12345 (SeqNo) + 1 Check Digit
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GenerateUCCBarcodes
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vRecordId           TRecordId,

          @vCompanyId          TBarcode,
          @vBarcodeType        TTypeCode,
          @vSSCC_SeqNo         TBarcode,

          @vSeqNoCount         TInteger,
          @vSequenceName       TCategory,
          @vSeqNoIncrement     TInteger,
          @vSeqNoMaxLength     TControlValue,
          @vNextSeqNo          bigint,
          @vLastSeqNo          bigint;
begin
  select @vRecordId = 0;

  /* Get LPN Info */
  update LSL
  set LSL.OrderId   = L.OrderId,
      LSL.Warehouse = L.DestWarehouse
  from #LPNShipLabels LSL
    join LPNs L on (L.LPNId = LSL.LPNId);

  /* Get Order Info, if caller passes specific label format, use that, else
     use for UCC128LabelFormat from the Order */
  update LSL
  set LSL.ShipFromName    = OH.ShipFrom,
      LSL.ShipToStore     = OH.ShipToStore,
      LSL.CompanyId       = OH.ShipFromCompanyId,
      LSL.LabelFormatName = coalesce(LSL.LabelFormatName, OH.UCC128LabelFormat)
  from #LPNShipLabels LSL
    join OrderHeaders OH on (OH.OrderId = LSL.OrderId);

  /* If BarcodeType is not given, from the label format, determine the barcode type */
  update LSL
  set LSL.BarcodeType = coalesce(LF.PrintOptions.value('(/printoptions/barcodetype)[1]','varchar(50)'), 'UCC128')
  from #LPNShipLabels LSL
    left outer join LabelFormats LF on (LF.LabelFormatName = LSL.LabelFormatName)
  where (LSL.BarcodeType is null);

  /* If Order does not specify the CompanyId, use the one for the ShipFrom */
  update LSL
  set LSL.CompanyId = dbo.fn_Controls_GetAsString ('SSCCBarcode_' + LSL.ShipFromName, 'CompanyId', null /* Default */, @BusinessUnit, @UserId)
  from #LPNShipLabels LSL
  where (LSL.CompanyId is null);

  /* If there is no specific company id to be used for the ShipFrom then use the default */
  update LSL
  set LSL.CompanyId = dbo.fn_Controls_GetAsString ('SSCCBarcode', 'CompanyId', '0000000' /* Default */, @BusinessUnit, @UserId)
  from #LPNShipLabels LSL
  where (LSL.CompanyId is null);

  /* Pad CompanyId to desired length - 7 for both UCC128 or SCC14 */
  update LSL
  set LSL.CompanyId = dbo.fn_pad(LSL.CompanyId, 7 /* Fixed */)
  from #LPNShipLabels LSL
  where (LSL.BarcodeType in ('UCC128', 'SCC14'));

  update LSL
  set LSL.PackingCode = case when (BarcodeType = 'UCC128') then '0'
                             when (BarcodeType = 'SCC14') then coalesce(LSL.PackingCode, 0) end
  from #LPNShipLabels LSL

  /* Update RecordId partioned by each CompanyId */
  ;with LPNRecordIds as
  (
   select LPNId, row_number() over (partition by CompanyId, BarcodeType order by CompanyId, BarcodeType) as GroupRecordId
   from #LPNShipLabels
  )
  update LSL
  set RecordId = LR.GroupRecordId
  from #LPNShipLabels LSL
    join LPNRecordIds LR on (LSL.LPNId = LR.LPNId);

  /* Get the list of distinct CompanyIds */
  select distinct CompanyId, BarcodeType, count(*) as SeqNoCount,
                  dbo.fn_Controls_GetAsInteger(BarcodeType + '_' + CompanyId, 'SeqNoMaxLength', '9', @BusinessUnit, @UserId) as SeqNoMaxLength,
                  row_number() over(order by CompanyId, BarcodeType) as RecordId
  into #CompanyIds
  from #LPNShipLabels
  group by CompanyId, BarcodeType;

  /* Loop thru each company id and generate sequence numbers */
  while exists(select * from #CompanyIds where RecordId > @vRecordId)
     begin
       /* reset variables */
       select @vNextSeqNo = null, @vLastSeqNo = null, @vSeqNoIncrement = null;

       select top 1 @vRecordId       = RecordId,
                    @vCompanyId      = CompanyId,
                    @vBarcodeType    = BarcodeType,
                    @vSeqNoCount     = SeqNoCount,
                    @vSeqNoMaxLength = SeqNoMaxLength,
                    @vSequenceName   = 'Seq_' + BarcodeType + '_' + CompanyId
       from #CompanyIds
       where (RecordId > @vRecordId)
       order by RecordId;

       /* Get the sequnce number range */
       exec pr_Sequence_GetNext @vSequenceName, @vSeqNoCount, @UserId, @BusinessUnit, @vNextSeqNo output, @vLastSeqNo output;

       /* Update the LPNs with Sequential Number */
       update LSL
       set SequentialNumber = dbo.fn_pad(SN.SequenceNo, @vSeqNoMaxLength)
       from #LPNShipLabels LSL
         join dbo.fn_GenerateSequence (@vNextSeqNo, @vLastSeqNo, 1) SN on (LSL.RecordId = SN.RecordId)
       where (CompanyId = @vCompanyId) and
             (BarcodeType = @vBarcodeType);
     end

  /* Compute check digit */
  update LSL
  set LSL.CheckDigit = dbo.fn_GetMod10CheckDigit(LSL.PackingCode + LSL.CompanyId + LSL.SequentialNumber)
  from #LPNShipLabels LSL;

  /* Build the barcode based upon the symbology */
  update LSL
  set LSL.SCCBarcode = case when (LSL.BarcodeType = 'UCC128') then '00' + LSL.PackingCode + LSL.CompanyId + LSL.SequentialNumber + LSL.CheckDigit
                            when (LSL.BarcodeType = 'SCC14') then LSL.PackingCode + LSL.CompanyId + LSL.SequentialNumber + LSL.CheckDigit
                            when (LSL.BarcodeType = 'StoreLabel') then right(coalesce(LSL.ShipToStore, '0000'), 4) + LSL.CompanyId + LSL.SequentialNumber end
  from #LPNShipLabels LSL;

  /* Update Cartons with UCC Barcode */
  update L
  set L.UCCBarcode = LSL.SCCBarcode
  from LPNs L
    join #LPNShipLabels LSL on (L.LPNId = LSL.LPNId);
end /* pr_ShipLabel_GenerateUCCBarcodes */

Go
