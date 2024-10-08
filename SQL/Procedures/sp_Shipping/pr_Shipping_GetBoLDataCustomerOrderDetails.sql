/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/27  RKC     pr_Shipping_ShipManifest_GetDetails, pr_Shipping_GetBoLDataCustomerOrderDetails: Made changes to get the correct Weight (HA-2650)
  2021/03/28  TK      pr_Shipping_GetBoLDataCustomerOrderDetails: Changes to fn_GenerateSequence data set (HA-2471)
                      pr_Shipping_GetBoLDataCarrierDetails and pr_Shipping_GetBoLDataCustomerOrderDetails: Included BOD reference feilds (FB-2225)
  2020/12/10  PHK     pr_Shipping_GetBoLDataCustomerOrderDetails: Made changes to order details to fix the sort seq updating issue (HA-1731)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetBoLDataCustomerOrderDetails') is not null
  drop Procedure pr_Shipping_GetBoLDataCustomerOrderDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetBoLDataCustomerOrderDetails: It will gives the empty xml result
       when we have Supplement result.

  BoL Report has provision on
  - Main Page (which prints 5 lines of Customer Order Details) (which also has 5 lines of carrier details)
  - Normal Supplement page (14 lines of Customer Order Details) (which also has 14 lines of carrier details)
  - Large Supplement page (which has only 28 lines of Customer Order Details)

  If count <= 5, then we print all records on Main page
  If count <= 14 then we print all records on Normal supplement page
  else                we print all records on Large supplement page

  Therefore, based upon the count we set the IsSupplmentPageML values to N, Y or L

  We are setting value to IsSupplementPageXml based on the row count.
  If Row count is <= 5          then 'N' - No Supplement.
     Row Count is > 6 and <= 14 then 'Y' - Normal.
     Row Count id > 14          then 'L' - Large

  However, when we have less lines than what the page can accommodate, we have to generate blank lines
  for the remainder for proper formatting of the report. i.e. if there are only 3 records and we
  print on Main page we have to generate two dummy lines; if there are 10 records adn we
  print on Normal supplement, then we have to generate four dummy lines etc. These
  dummy records are generated in pr_BoL_GetCustomerOrderDetailsAsXML.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetBoLDataCustomerOrderDetails
  (@BoLId                     TBoLId,
   @Report                    TResult,
   @IsSupplementPageXml       TFlag = null output,
   @xmlCustomerOrderDetails   XML   = null output,
   @xmlCustomerOrderTotals    XML   = null output,
   @xmlSupplementOrderDetails XML   = null output,
   @xmlSupplementOrderTotals  XML   = null output)
as
  declare @ReturnCode                   TInteger,
          @MessageName                  TMessageName,
          @CODetails                    TCount,
          @vRequiredRows                TCount,
          @vRowsToPrintOnFirstPage      TCount,
          @vRowsOnNormalSupplementPage  TCount,

          @vBoLType                     TTypeCode,
          @vLoadId                      TLoadId,
          @vBoLNumber                   TBoLNumber,
          @vLine1                       varchar(30),
          @vLine2                       varchar(30),
          @vBusinessUnit                TBusinessUnit,
          @vUserId                      TUserId;

  declare @vCustomerOrderDetails TBoLCustomerOrderDetails;

begin  /* pr_Shipping_GetBoLDataCustomerOrderDetails */
  /* Initialize */
  select @CODetails                   = 0,
         @IsSupplementPageXML         = null,
         @xmlCustomerOrderDetails     = null,
         @xmlCustomerOrderTotals      = null,
         @xmlSupplementOrderDetails   = null,
         @xmlSupplementOrderTotals    = null,
         @vLine1                      = 'SEE ATTACHED',
         @vLine2                      = 'SUPPLEMENT PAGE';

  /* Get BoL info */
  select @vBoLType       = BoLType,
         @vLoadId        = LoadId,
         @vBoLNumber     = BoLNumber,
         @vBusinessUnit  = BusinessUnit
  from BoLs
  where (BoLId = @BoLId);

  /* Adding Controls to print the Number of details based on the Bol Report */
  select @vRowsToPrintOnFirstPage     = dbo.fn_Controls_GetAsInteger(@Report, 'RowsToPrintOnFirstPage',     '5',  @vBusinessUnit, @vUserId),
         @vRowsOnNormalSupplementPage = dbo.fn_Controls_GetAsInteger(@Report, 'RowsOnNormalSupplementPage', '14', @vBusinessUnit, @vUserId);

  /* Insert customer Orderdetails into temp table here...*/
  if (@vBoLType = 'U' /* Underlying */) or (@vBoLType = 'M' /* Master */)
    begin
      /* For Underlying BoL, get all Customer Order details for the current BoL */
      insert into @vCustomerOrderDetails(CustomerOrderNumber, NumPackages, Weight, Palletized, AdditionalShipperInfo,
                                         BOD_Reference1, BOD_Reference2, BOD_Reference3, BOD_Reference4, BOD_Reference5,
                                         UDF1, UDF2, UDF3, UDF4, UDF5, SortSeq, PageNumber)
        select CustomerOrderNo, NumPackages, Weight, Palletized, ShipperInfo,
               BOD_Reference1, BOD_Reference2, BOD_Reference3, BOD_Reference4, BOD_Reference5,
               UDF1, UDF2, UDF3, UDF4, UDF5, row_number() over (order by BoLId) as SortSeq, 1
        from BoLOrderDetails
        where (BoLId = @BoLId)
        order by BODGroupCriteria;
    end
  else
    begin
      /* For Master BoL, get all the Customer Order details of the Load i.e. all Loads */
      insert into @vCustomerOrderDetails(CustomerOrderNumber, NumPackages, Weight, Palletized, AdditionalShipperInfo,
                                         BOD_Reference1, BOD_Reference2, BOD_Reference3, BOD_Reference4, BOD_Reference5,
                                         UDF1, UDF2, UDF3, UDF4, UDF5, SortSeq, PageNumber)
        select min(CustomerOrderNo), sum(NumPackages), ceiling (sum(Weight)), min(Palletized), min(ShipperInfo),
               min(BOD_Reference1), min(BOD_Reference2), min(BOD_Reference3), min(BOD_Reference4), Min(BOD_Reference5),
               min(BOD.UDF1), min(BOD.UDF2), min(BOD.UDF3), min(BOD.UDF4), min(BOD.UDF5),
               row_number() over (order by (select 1)) as SortSeq, 1
        from BoLOrderDetails BOD
        where (BOD.BoLId = @BoLId)
        group by BODGroupCriteria
        order by BODGroupCriteria;
    end

  select @CODetails = @@rowcount;

  /* For Master BoL, generate list of Underlying BoLs in the supplement details */
  /* If we have more than 6 underlying bols for a load then it is not possible to print the underlying BoL numbers
     in the special instructions section. Hence, we print the Underlying BoL Numbers in the supplement page */
  if ((@vBoLType = 'M'/* Master */) and ((select count(*) from BoLs  where ((LoadId = @vLoadId) and (BoLType = 'U' /* Underlying */) )) > 6))
    begin
      /* Insert 1 blank row after the Customer Order Details */
      insert into @vCustomerOrderDetails (SortSeq)
        select SequenceNo from dbo.fn_GenerateSequence(@CODetails /* Start */, null /* End */, 1 /* Count */);

      /* Insert 1 blank row after the Customer Order Details */
      insert into @vCustomerOrderDetails (CustomerOrderNumber)
        select 'Underlying BoLs:';

      insert into @vCustomerOrderDetails(CustomerOrderNumber)
        select VICSBoLNumber
        from BoLs
        where ((LoadId = @vLoadId) and (BoLType = 'U' /* Underlying */));
    end

  select @CODetails = count(*) from @vCustomerOrderDetails;

  /* Set appropriate flag here based on the row count */
  If (@CODetails <= @vRowsToPrintOnFirstPage)
    select @IsSupplementPageXml = 'N' /* No */,
           @vRequiredRows       = @vRowsToPrintOnFirstPage;
  else
  if (@CODetails <= @vRowsOnNormalSupplementPage)
    select @IsSupplementPageXml = 'Y' /* Normal */,
           @vRequiredRows       = @vRowsOnNormalSupplementPage;
  else
    select @IsSupplementPageXml = 'L' /* Large */,
           @vRequiredRows       = (Ceiling(cast(@CODetails as Float) / 28) * 28);

  /* Build XML for Customer Order Totals of main page - this is always the case
     no matter the BoLType or number of records of Carrier Details to print
     because the main page ALWAYS has the totals */
  exec pr_BoL_GetCustomerOrderTotalsAsXML @vCustomerOrderDetails, @BoLId,
                                          'N' /* Supplement */,
                                          @xmlCustomerOrderTotals output;

  /* For Master or underlying BoLs, if there are less than 5 Customer Order
     Details, then print them on the main page */
  if (@CODetails <= @vRowsToPrintOnFirstPage)
    begin
      /* Build the Customer Order Details as an XML for main page with 5 rows/nodes */
      exec pr_BoL_GetCustomerOrderDetailsAsXML @vCustomerOrderDetails, @vBoLNumber,
                                               @IsSupplementPageXml /* Supplement */, @vRequiredRows,
                                               @xmlCustomerOrderDetails output;

    end
  else
    /* If there are more than 5 Customer OrderDetails then print them on
       supplement page and print reference to supplement page on the main page */
    begin
      /* Build the XML for supplement Customer Order Details */
      exec pr_BoL_GetCustomerOrderDetailsAsXML @vCustomerOrderDetails, @vBoLNumber,
                                               @IsSupplementPageXml /* Supplement */, @vRequiredRows,
                                               @xmlSupplementOrderDetails output;

      /* Supplement Customer Order Totals - I don't see why this is needed */
      exec pr_BoL_GetCustomerOrderTotalsAsXML @vCustomerOrderDetails, @BoLId,
                                              @IsSupplementPageXml /* Supplement */,
                                              @xmlSupplementOrderTotals output;

      /* delete data from temp table */
      delete from @vCustomerOrderDetails;

      /* Insert carrier details into temp table here...*/
      insert into @vCustomerOrderDetails(CustomerOrderNumber, SortSeq)
              select @vLine1, 0
        union select @vLine2, 1

      /* Build the XML for Carrier Details on main page */
      exec pr_BoL_GetCustomerOrderDetailsAsXML @vCustomerOrderDetails, @vBoLNumber,
                                               'N' /* Supplement */, @vRowsToPrintOnFirstPage /* Rows */,
                                               @xmlCustomerOrderDetails output;
    end

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_GetBoLDataCustomerOrderDetails */

Go
