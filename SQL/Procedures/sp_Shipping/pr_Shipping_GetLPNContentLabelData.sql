/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/23  AY      pr_Shipping_GetLPNContentLabelData: Bug fixes (HA-1013)
  2019/06/28  MS      pr_Shipping_GetLPNContentLabelData: Calling LPNResequence to correct the packageseqno (CID-654)
  2019/04/10  MS      Converted fn_Shipping_GetLPNContentLabelData to pr_Shipping_GetLPNContentLabelData and made changes (CID-221)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetLPNContentLabelData') is not null
  drop procedure pr_Shipping_GetLPNContentLabelData ;
Go
/*-----------------------------------------------------------------------------

**** DEPRECATED ****** USE pr_ShipLabel_GetLPNDataAndContents for Combo labels and
  pr_ShipLabel_GetLPNContents for simple contents labels ******

  pr_Shipping_GetLPNContentLabelData
  Procedure to return the packed item details for lpn / carton.

  Assumptions: content label will contain max 30 rows of sku details,
  so creating a table with 30 columns to return data. However, some labels
  may have less than 30 lines and we only use upto whatever we would need.

  This Procedure is implemented to suite the bartender label design, and hence
  should only be used with bartender label for contents label
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetLPNContentLabelData
  (@LPN                   TLPN,
   @LPNId                 TRecordId,
   @BusinessUnit          TBusinessUnit,
   @ContentLinesPerLabel  TCount,
   @MaxLabelsToPrint      TCount)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          @UserId             TUserId,

          @vOrderId           TRecordId,
          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vTrackingNo        TTrackingNo,
          @vPackedDate        TDateTime,
          @vPackedBy          TUserId,
          @vPackageSeqNo      TInteger,
          @vLPNQuantity       TQuantity,
          @vLPNLine           TDetailLine,
          @vSKU               TSKU,
          @vQuantity          TQuantity,
          @vLinecount         TCount,
          @vRecordId          TInteger,
          @vLabelSNo          TInteger,
          @vCol               TInteger,
          @vCols              TInteger,
          @vColStr            varchar(10),
          @vUPC               TUPC,
          @vCustSKU           TCustSKU,
          @vSKUDescription    varchar(203),
          @vSKU1              varchar(50),
          @vSKU2              varchar(50),
          @vSKU3              varchar(50),
          @vSKU4              varchar(50),
          @vSKU5              varchar(50),
          @vShipToStore       TShipToStore,
          @vTotalLPNs         TCount,
          @vShipVia           TShipVia,
          @vShipFrom          TShipFrom,
          @vCustPO            TCustPO,
          @vShipToId          TShipToId,
          @vUCCBarcode        TBarcode,
          @vUnitsAuthorizedToShip
                              TQuantity,

          /* Ship From */
          @vShipFromName      TName,
          @vShipFromAddr1     TAddressLine,
          @vShipFromAddr2     TAddressLine,
          @vShipFromCity      TCity,
          @vShipFromState     TState,
          @vShipFromZip       TZip,
          @vShipFromCountry   TCountry,
          @vShipFromCSZ       TVarchar,
          @vShipFromPhoneNo   TPhoneNo,

          /* Ship To */
          @vShipToName        TName,
          @vShipToAddr1       TAddressLine,
          @vShipToAddr2       TAddressLine,
          @vShipToCity        TCity,
          @vShipToState       TState,
          @vShipToZip         TZip,
          @vShipToCSZ         TVarchar,
          @vShipToReference1  TDescription,
          @vShipToReference2  TDescription,
          @vStr               TVarchar,
          @RecordCount        TInteger;

  declare @LPNContentLabelData    TLPNContentsLabelData;
  declare @LPNDetails             TLPNContentsLabelDetails;
begin
  set NOCOUNT ON;

  select @ReturnCode   = 0,
         @Messagename  = null,
         @UserId       = System_User,
         @vRecordId    = 0;

  /* In some cases we would want to return an empty data set - so return so if MaxLabels = -1 */
  if (@MaxLabelsToPrint = -1)
    begin
      insert into @LPNContentLabelData(LPN) select @LPN;
      return;
    end

  /* select to create table structure for #LPNContents */
  select * into #LPNContents from @LPNContentLabelData

  /* Initialize row with starting number
     Initialize cols with number sku details a label can hold - 10 if none is passed in */
  select @vLabelSNo        = 1,
         @vCols            = coalesce(nullif(@ContentLinesPerLabel, 0), 10),
         @MaxLabelsToPrint = coalesce(nullif(@MaxLabelsToPrint, 0), 9);

  select @vLPNId        = LPNId,
         @vOrderId      = OrderId,
         @vTrackingNo   = TrackingNo,
         @vPackageSeqNo = PackageSeqno,
         @vUCCBarcode   = UCCBarcode,
         @vLPNQuantity  = Quantity
  from LPNs
  where (LPN = @LPN) and (BusinessUnit = @BusinessUnit);

  /* Fetch ship-via and store-no  */
  select @vShipVia     = OH.ShipVia,
         @vShipToStore = OH.ShipToStore,
         @vShipFrom    = OH.ShipFrom,
         @vCustPO      = OH.CustPO,
         @vShipToId    = OH.ShipToId,
         @vTotalLPNs   = OH.NumLPNs
  from OrderHeaders OH
  where (OH.OrderId = @vOrderId);

  /* Get Company Details */
  select @vShipFromName     = SF.Name,
         @vShipFromAddr1    = SF.AddressLine1,
         @vShipFromAddr2    = SF.AddressLine2,
         @vShipFromCity     = SF.City,
         @vShipFromState    = SF.State,
         @vShipFromZip      = SF.Zip,
         @vShipFromCountry  = SF.Country,
         @vShipFromCSZ      = SF.CityStateZip,
         @vShipFromPhoneNo  = SF.PhoneNo
  from vwContacts SF
  where (SF.ContactRefId = @vShipFrom) and (SF.ContactType = 'F' /* Ship From */);

  /* Get ShipTo Details */
  select @vShipToName       = SHTA.Name,
         @vShipToAddr1      = SHTA.AddressLine1,
         @vShipToAddr2      = SHTA.AddressLine2,
         @vShipToCity       = SHTA.City,
         @vShipToState      = SHTA.State,
         @vShipToZip        = SHTA.Zip,
         @vShipToCSZ        = SHTA.CityStateZip,
         @vShipToReference1 = SHTA.Reference1,
         @vShipToReference2 = SHTA.Reference2
  from dbo.fn_Contacts_GetShipToAddress(null /* Order Id */, @vShipToId) SHTA

  /* Reorder the Package Seq No if LPN is allocated to an Order */
  if (@vOrderId is not null)
    exec pr_LPNs_PackageNoResequence @vOrderId, @vLPNId;

  select top 1 @vPackedDate = PackedDate,
               @vPackedBy   = PackedBy
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Insert the required data into a temp table to loop through / process */
  insert into @LPNDetails(LPN, LPNLine, SKU, Quantity, UPC, CustSKU, SKUDescription,
                          SKU1, SKU2, SKU3, SKU4, SKU5, UnitsAuthorizedToShip)
    select LPN, LPNLine, SKU, Quantity, null, CustSKU, SKUDescription,
           SKU1, SKU2, SKU3, SKU4, SKU5, UnitsAuthorizedToShip
    from vwLPNPackingListDetails
    where LPNId = @vLPNId
    order by LPNDetailId;

  /* Number of records inserted */
  select @vLinecount = count(*) from @LPNDetails;

  /* Fill the table variable with the rows for your result set
     Iterate thru each Pack detail record and insert into output table */
  while (@vRecordId < @vLinecount)
    begin
      /* For each record to print, compute the label number and the column number to add data to in that label,
         for example, the first record will be label 1 col 1, second will be label 1, col 2 ... 10th would be
         label 1, col 10 and next would be label 2, col 1 and so on... */
      select top 1
             @vRecordId          = RecordId,
             @vLPN               = LPN,
             @vSKU               = SKU,
             @vQuantity          = Quantity,
             @vUPC               = UPC,
             @vCustSKU           = CustSKU,
             @vSKUDescription    = dbo.fn_RemoveSpecialChars(SKUDescription), /* SKUDesc may have single qoteslike Women's and that will cause for issue futhere */
             @vSKU1              = SKU1,
             @vSKU2              = SKU2,
             @vSKU3              = SKU3,
             @vSKU4              = SKU4,
             @vSKU5              = SKU5,
             @vUnitsAuthorizedToShip
                                 = UnitsAuthorizedToShip,
             /* Column number is mod of total columns except when result is zero when it is the last line */
             @vCol               = case when RecordId % @vCols = 0 then @vcols
                                        else RecordId % @vCols end,
             @vLabelSNo          = case when RecordId % @vCols = 0 then RecordId / @vCols
                                        else round(RecordId / @vCols + 1, 0) end
      from @LPNDetails
      where RecordId > @vRecordId
      order by RecordId;

      /* In some situations, no matter how many lines there are, we may only want to print one label
         and have something like ...and more at the end of the label. So, check for the condition
         where we are exceeding the max labels and quit;
      */
      if (@vLabelSNo > @MaxLabelsToPrint) break;

      /* create a new record for each lpn and for single label (label can hold 10 sku details)
        create additional record if sku details exceeds more than 10 per label */
      /* Pointed SKU1 to CustSKU for FB specific as they required CustSKU in the place of
        SKU field in content label*/
      if not exists (select @LPN from #LPNContents where LPN = @vLPN and LabelSNo = @vLabelSNo)
        begin
          insert into #LPNContents (LPN, TrackingNo, PackedDate, PackedBy, PackageSeqNo, UCCBarcode,
                                    LabelSNo, LPNLine01, SKU01, Quantity01, UPC01, CustSKU01, SKUDescription01,
                                    SKU101, SKU201, SKU301, SKU401, SKU501, UnitsAuthorizedToShip01,
                                    ShipVia,ShipFrom, CustPO, ShipToId, ShipToStore, TotalLPNs,
                                    ShipFromName, ShipFromAddr1, ShipFromAddr2, ShipFromCity, ShipFromState, ShipFromZip, ShipFromCountry, ShipFromCSZ,
                                    ShipToName, ShipToAddr1, ShipToAddr2, ShipToCity, ShipToState, ShipToZip, ShipToCSZ,
                                    TotalLines, TotalQuantity)
          values(@vLPN, @vTrackingNo, @vPackedDate, @vPackedBy, @vPackageSeqNo, @vUCCBarcode,
                 @vLabelSNo, cast(@vRecordId as varchar(10)), @vSKU, @vQuantity, @vUPC, @vCustSKU, @vSKUDescription,
                 @vSKU1, @vSKU2, @vSKU3, @vSKU4, @vSKU5, @vUnitsAuthorizedToShip,
                 @vShipVia, @vShipFrom, @vCustPO,@vShipToId, @vShipToStore, @vTotalLPNs,
                 @vShipFromName, @vShipFromAddr1, @vShipFromAddr2, @vShipFromCity, @vShipFromState, @vShipFromZip, @vShipFromCountry, @vShipFromCSZ,
                 @vShipToName, @vShipToAddr1, @vShipToAddr2, @vShipToCity, @vShipToState, @vShipToZip, @vShipToCSZ,
                 @vLinecount, @vLPNQuantity);
        end
      else
        begin
          /* Formulate the column number */
          select @vColStr = dbo.fn_LeftPadNumber(@vCol, 2);

          /* Build and execute the SQL stmt */
          select @vStr = 'Update #LPNContents ' +
                         'set LPNLine'               + @vColStr + ' = ' + cast(@vRecordId as varchar(10)) +
                         '   ,SKU'                   + @vColStr + ' = ''' + @vSKU + '''' +
                         '   ,Quantity'              + @vColStr + ' = ' + cast(@vQuantity as varchar(10)) +
                         '   ,UnitsAuthorizedToShip' + @vColStr + ' = ' + cast(@vUnitsAuthorizedToShip as varchar(10)) +
                         '   ,UPC'                   + @vColStr + ' = ''' + coalesce(@vUPC,'')             + '''' +
                         '   ,CustSKU'               + @vColStr + ' = ''' + coalesce(@vCustSKU, '')        + '''' +
                         '   ,SKUDescription'        + @vColStr + ' = ''' + coalesce(@vSKUDescription, '') + '''' +
                         '   ,SKU1'                  + @vColStr + ' = ''' + coalesce(@vSKU1, '') + '''' +
                         '   ,SKU2'                  + @vColStr + ' = ''' + coalesce(@vSKU2, '') + '''' +
                         '   ,SKU3'                  + @vColStr + ' = ''' + coalesce(@vSKU3, '') + '''' +
                         '   ,SKU4'                  + @vColStr + ' = ''' + coalesce(@vSKU4, '') + '''' +
                         '   ,SKU5'                  + @vColStr + ' = ''' + coalesce(@vSKU5, '') + '''' +
                         ' where LPN = ''' + @LPN + ''' and LabelSNo = ' + cast(@vLabelSNo as varchar(10));
          exec (@vStr)
        end
    end --while (@vRecordId < @vPackDetailCount)

  /* Returns the details to print on content label*/
  select * from #LPNContents
end /* pr_Shipping_GetLPNContentLabelData */

Go
