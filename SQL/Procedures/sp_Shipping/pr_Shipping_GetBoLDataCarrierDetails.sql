/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/01  RT      pr_Shipping_GetBoLData: Rules to get the BoL Reports (FB-2225)
                      pr_Shipping_GetBoLDataCarrierDetails and pr_Shipping_GetBoLDataCustomerOrderDetails: Included BOD reference feilds (FB-2225)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetBoLDataCarrierDetails') is not null
  drop Procedure pr_Shipping_GetBoLDataCarrierDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetBoLDataCarrierDetails:
    The procedure that returns all the carrier details data to be printed on the
    BoL Main page as well as supplement pages as follows:
      a. If there are 5 or less Carrier detail entries, then they would be printed
         on the main page and none on the second page
      b. If there are more than 5 carrier detail entries to be printed, they only
         a message would be printed on main page and the supplement page(s) would
         have the actual data.
      c. Main page will always print the totals.

  The above is true for both Master BoL and Underlying BoL. If so desired, for
  Master BoL we could skip the supplement pages and reference the underlying BoLs
  when there are more than 5 carrier details to be printed.

  Parameters:
    xmlCarrierDetails: Data to be printed on the main page
    xmlCarrierDetailsTotals: Totals to be printed on the main page
    xmlSupplementCarrierDetails: Data to be printed on the Supplement page
!!  xmlSupplementCarrierTotals: This is not required, as supplement page should
                                 only have subtotals of each supplement page.

    We are setting value to IsSupplementPageXml  based on the row count.
      If Row count is < 5          then  'N' - No Supplement.
         Row Count is > 5 and < 15 then 'Y' - Normal.
         Row Count id > 14         then 'L' - Large
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetBoLDataCarrierDetails
  (@BoLId                       TBoLId,
   @Report                      TResult,
   @IsSupplementPageXml         TFlag = null output,
   @xmlCarrierDetails           XML   = null output,
   @xmlCarrierTotals            XML   = null output,
   @xmlSupplementCarrierDetails XML   = null output,
   @xmlSupplementCarrierTotals  XML   = null output)
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

  declare @CarrierDetails TBoLCarrierDetails;
begin  /* pr_Shipping_GetBoLDataCarrierDetails */
  /* Initialize */
  select @CODetails                   = 0,
         @IsSupplementPageXML         = null,
         @xmlCarrierDetails           = null,
         @xmlCarrierTotals            = null,
         @xmlSupplementCarrierDetails = null,
         @xmlSupplementCarrierTotals  = null;

  /* Get BoL Info */
  select @vBoLType        = BoLType,
         @vLoadId         = LoadId,
         @vBoLNumber      = BoLNumber,
         @vBusinessUnit   = BusinessUnit
  from BoLs
  where (BoLId = @BoLId);

  /* Adding Controls to print the Number of details based on the Bol Report */
  select @vRowsToPrintOnFirstPage     = dbo.fn_Controls_GetAsInteger(@Report, 'RowsToPrintOnFirstPage',     '5', @vBusinessUnit, @vUserId),
         @vRowsOnNormalSupplementPage = dbo.fn_Controls_GetAsInteger(@Report, 'RowsOnNormalSupplementPage', '14', @vBusinessUnit, @vUserId);

  /* Insert carrier details into temp table here for the give BoL if it is an
     underlying BoL. If Master, then summarize details for all BoLs of the Load
  */
  if (@vBoLType = 'U' /* Underlying */)
    begin
      select @vLine1 = 'SEE ATTACHED',
             @vLine2 = 'SUPPLEMENT PAGE';
      insert into @CarrierDetails(HandlingUnitType, HandlingUnitQty, PackageType, PackageQty, Weight,
                                  Hazardous, CommDescription, NMFCCode, CommClass, SortSeq, PageNumber)
        select HandlingUnitType, HandlingUnitQty, PackageType, PackageQty, Round (Weight, 0),
               Case
                 when Hazardous = 'N' then 'No'
                 when Hazardous = 'Y' then 'Yes'
                 else
                   'No'
               end /* Hazardous - 'No' for TD */,
               CommDescription, NMFCCode, CommClass, row_number() over (order by BoLId) as SortSeq /* SortSeq */, 0
        from BoLCarrierDetails
        where (BoLId = @BoLId);
    end
  else
    begin
      select @vLine1 = 'SEE UNDERLYING',
             @vLine2 = 'BOLS FOR DETAILS';
      insert into @CarrierDetails(HandlingUnitType, HandlingUnitQty, PackageType, PackageQty, Weight,
                                  Hazardous, CommDescription, NMFCCode, CommClass, SortSeq, PageNumber)
        select HandlingUnitType, sum(HandlingUnitQty), PackageType, sum(PackageQty), Round (sum(Weight), 0),
               Case
                 when Hazardous = 'N' then 'No'
                 when Hazardous = 'Y' then 'Yes'
                 else
                   'No'
               end /* Hazardous - 'No' for TD */,
               CommDescription, NMFCCode, CommClass, count(*) as SortSeq /* SortSeq */, 0
        from BoLCarrierDetails BCD join BoLs B on BCD.BoLId = B.BoLId
        where (B.BoLId = @BoLId)
        group by HandlingUnitType, PackageType, Hazardous, CommDescription, NMFCCode, CommClass
    end

  select @CODetails = @@rowcount;

  /* Set appropriate flag here based on the row count */
  if (@CODetails <= @vRowsToPrintOnFirstPage)
    select @IsSupplementPageXml = 'N' /* No */,
           @vRequiredRows       = @vRowsToPrintOnFirstPage;
  else
  if (@CODetails <= @vRowsOnNormalSupplementPage)
    select @IsSupplementPageXml = 'Y' /* Normal */,
           @vRequiredRows       = @vRowsOnNormalSupplementPage;
  else
    select @IsSupplementPageXml = 'L' /* Large */,
           @vRequiredRows       = (Ceiling(cast(@CODetails as Float) / 28) * 28);

  /* Build XML for Carrier Order Totals of main page - this is always the case
     no matter the BoLType or number of records of Carrier Details to print
     because the main page ALWAYS has the totals */
  exec pr_BoL_GetCarrierTotalsAsXML @CarrierDetails, @vBoLNumber,
                                    'N' /* Supplement */,
                                    @xmlCarrierTotals output;

  /* For Master or underlying BoLs, if there are less than 5 Carrier Details, then
     print them on the main page */
  if (@CODetails <= @vRowsToPrintOnFirstPage)
    begin
      /* Build the Carrier Details as an XML for main page with 5 rows/nodes */
      exec pr_BoL_GetCarrierDetailsAsXML @CarrierDetails, @vBoLNumber,
                                         @IsSupplementPageXml /* Supplement */, @vRequiredRows /* Rows */,
                                         @xmlCarrierDetails output;

    end
  else
    /* If there are more than 5 Carrier Details then print them on supplement page
       and print reference to supplement page on the main page */
    begin
      /*  I don't see why we need to have min of 14 on supplement page as there could be multiple supplement pages to be printed
          and the size of each section on the supplement page does not have to be the same
      */

      /* Build the XML for supplement Carrier  Details */
      exec pr_BoL_GetCarrierDetailsAsXML @CarrierDetails, @vBoLNumber,
                                         @IsSupplementPageXml /* Supplement */, @vRequiredRows /* Rows */,
                                         @xmlSupplementCarrierDetails output;

      /* Supplement Carrier Totals - I don't see why this is needed */
      exec pr_BoL_GetCarrierTotalsAsXML @CarrierDetails, @vBoLNumber,
                                        @IsSupplementPageXml /* Supplement */,
                                        @xmlSupplementCarrierTotals output;

      /* delete data from temp table */
      delete from @CarrierDetails;

     /* Insert carrier details inot temp table here...*/
      insert into @CarrierDetails(CommDescription, SortSeq)
              select @vLine1, 0
        union select @vLine2, 1

      /* Build the XML for Carrier  Details on main page */
      exec pr_BoL_GetCarrierDetailsAsXML @CarrierDetails, @vBoLNumber,
                                         'N' /* Supplement */, @vRowsToPrintOnFirstPage /* Rows */,
                                         @xmlCarrierDetails output;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_GetBoLDataCarrierDetails */

Go
