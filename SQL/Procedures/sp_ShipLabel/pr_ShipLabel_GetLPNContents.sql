/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/24  AY      pr_ShipLabel_GetLPNContents: New procedure to return LPN Contents
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLPNContents') is not null
  drop procedure pr_ShipLabel_GetLPNContents ;
Go
/*-----------------------------------------------------------------------------
  pr_ShipLabel_GetLPNContents
  Procedure to return the contents of an LPN pivoted so we can print a label
  with several lines

  Assumptions: content label will contain max 30 rows of sku details,
  so creating a table with 30 columns to return data. However, some labels
  may have less than 30 lines and we only use upto whatever we would need.

  This procedure would be used for combo shipping labels where the shipping
  label has multiple SKU details printed on it.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLPNContents
  (@LPN                   TLPN,
   @LPNId                 TRecordId,
   @BusinessUnit          TBusinessUnit,
   @ContentLinesPerLabel  TCount,
   @MaxLabelsToPrint      TCount,
   @ReturnDataSet         TFlag = 'Y')
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

          @vStr               TVarchar,
          @RecordCount        TInteger;

  declare @LPNContents        TLPNContents;
  declare @LPNDetails         TLPNContentsLabelDetails;
begin /* pr_ShipLabel_GetLPNContents */
  set NOCOUNT ON;

  select @ReturnCode   = 0,
         @Messagename  = null,
         @UserId       = System_User,
         @vRecordId    = 0,
         @vLPNId       = @LPNId;

  /* select to create table structure for #LPNContents */
  if object_id('tempdb..#LPNContents') is null
    select * into #LPNContents from @LPNContents;

  /* In some cases we would want to return an empty data set - so return so if MaxLabels = -1 */
  if (@MaxLabelsToPrint = -1)
    begin
      insert into #LPNContents(LC_LPN) select @LPN;
      return;
    end

  /* Initialize row with starting number
     Initialize cols with number sku details a label can hold - 10 if none is passed in */
  select @vLabelSNo        = 1,
         @vCols            = coalesce(nullif(@ContentLinesPerLabel, 0), 10),
         @MaxLabelsToPrint = coalesce(nullif(@MaxLabelsToPrint, 0), 9);

  if (@vLPNId is null)
    select @vLPNId = LPN from LPNs where (LPN = @LPN) and (BusinessUnit = @BusinessUnit)

  select @vOrderId      = OrderId,
         @vLPNQuantity  = Quantity
  from LPNs
  where (LPNId = @vLPNId);

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

      /* create a new record for each lpn and for single label. for example, if label can hold 10 sku details
        create additional record if sku details exceeds more than 10 per label */
      if not exists (select * from #LPNContents where LC_LPN = @vLPN and LabelSNo = @vLabelSNo)
        begin
          insert into #LPNContents (LC_LPN, LabelSNo, LPNLine01, SKU01, Quantity01, UPC01, CustSKU01, SKUDescription01,
                                    SKU101, SKU201, SKU301, SKU401, SKU501, UnitsAuthorizedToShip01,
                                    LC_TotalLines, LC_TotalQuantity)
          values(@vLPN, @vLabelSNo, cast(@vRecordId as varchar(10)), @vSKU, @vQuantity, @vUPC, @vCustSKU, @vSKUDescription,
                 @vSKU1, @vSKU2, @vSKU3, @vSKU4, @vSKU5, @vUnitsAuthorizedToShip,
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
                         '   ,UPC'                   + @vColStr + ' = ''' + coalesce(@vUPC,'')             + '''' +
                         '   ,CustSKU'               + @vColStr + ' = ''' + coalesce(@vCustSKU, '')        + '''' +
                         '   ,SKUDescription'        + @vColStr + ' = ''' + coalesce(@vSKUDescription, '') + '''' +
                         '   ,SKU1'                  + @vColStr + ' = ''' + coalesce(@vSKU1, '') + '''' +
                         '   ,SKU2'                  + @vColStr + ' = ''' + coalesce(@vSKU2, '') + '''' +
                         '   ,SKU3'                  + @vColStr + ' = ''' + coalesce(@vSKU3, '') + '''' +
                         '   ,SKU4'                  + @vColStr + ' = ''' + coalesce(@vSKU4, '') + '''' +
                         '   ,SKU5'                  + @vColStr + ' = ''' + coalesce(@vSKU5, '') + '''' +
                         '   ,UnitsAuthorizedToShip' + @vColStr + ' = ' + cast(@vUnitsAuthorizedToShip as varchar(10)) +
                         ' where LC_LPN = ''' + @vLPN + ''' and LabelSNo = ' + cast(@vLabelSNo as varchar(10));
          exec (@vStr)
        end
    end --while (@vRecordId < @vPackDetailCount)

  /* Returns the details to print on content label*/
  if (@ReturnDataSet = 'Y')
    select * from #LPNContents;
end /* pr_ShipLabel_GetLPNContents */

Go
