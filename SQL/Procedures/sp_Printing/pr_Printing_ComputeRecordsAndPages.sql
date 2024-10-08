/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/06/05  RV      pr_Printing_ComputeRecordsAndPages: Made changes to get the report name from the full path (JLCA-855)
  2021/01/15  MS      pr_Printing_InsertSupplementReport: Added new proc to get append report (CIMSV3-1234)
                      pr_Printing_ComputeRecordsAndPages: New proc to compute total pages (CIMSV3-1234)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_ComputeRecordsAndPages') is not null
  drop Procedure pr_Printing_ComputeRecordsAndPages;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_ComputeRecordsAndPages: Proc is to compute total pages for the
   given report based on NumDetails count & its supplement page
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_ComputeRecordsAndPages
  (@Report                    TName,
   @NumDetails                TCount,
   @BusinessUnit              TBusinessUnit,
   @UserId                    TUserId,
   @TotalPages                TInteger output,
   @MainPageNumRecords        TInteger output,
   @SupplementPageNumRecords  TInteger output,
   @PageType                  TFlags   output,
   @SupplementPagePosition    TName    output,
   @StartIndex                TInteger = null output,
   @EndIndex                  TInteger = null output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,

          @vPageModel                  TName,
          @vIsMainPage                 TFlags,
          @vIsSupplementPage           TFlags,
          @vMP_RecordsPerPage          TInteger,
          @vSP_RecordsPerPage          TInteger,
          @vMainPageNumRecords         TInteger,
          @vSupplementPageNumRecords   TInteger;

begin /* pr_Printing_ComputeTotalPages */
  SET NOCOUNT ON;

  select @vReturnCode           = 0,
         @vMessageName          = null,
         @vRecordId             = 0;

  select @vPageModel             = R.PageModel,
         @vIsMainPage            = case when (dbo.fn_IsInList('M', R.PageModel) > 0) then 'Y' else 'N' end,
         @vIsSupplementPage      = case when (dbo.fn_IsInList('S', R.PageModel) > 0) then 'Y' else 'N' end,
         @PageType               = case when (dbo.fn_IsInList('S', R.PageModel) > 0) then 'S' else 'M' end,
         @SupplementPagePosition = case when (dbo.fn_IsInList('A', R.PageModel) > 0) then 'After'
                                        when (dbo.fn_IsInList('B', R.PageModel) > 0) then 'Before'
                                        else 'None'
                                   end,
         @vMP_RecordsPerPage     = case when (dbo.fn_IsInList('M', R.PageModel) > 0) then coalesce(R.NumRecordsPerPage, 999) else coalesce(RM.NumRecordsPerPage, 999) end,
         @vSP_RecordsPerPage     = case when (dbo.fn_IsInList('S', R.PageModel) = 0) then coalesce(RS.NumRecordsPerPage, 999) else coalesce(R.NumRecordsPerPage, 999) end
  from Reports R
    left outer join Reports RS on (RS.ReportName           = R.AdditionalReportName) and (RS.BusinessUnit = R.BusinessUnit)
    left outer join Reports RM on (RM.AdditionalReportName = R.ReportName) and (RS.BusinessUnit = R.BusinessUnit)
  where (R.ReportName = @Report) and (R.BusinessUnit = @BusinessUnit);

  /* Determine how many records will print on the main page. This depends on how many
     records we have to print and the page model i.e. if supplement page is before or after */
  select @MainPageNumRecords = case
                                 -- if there is no supplement page, then print all on main page
                                 when (@SupplementPagePosition = 'None') then @NumDetails
                                 -- if all records can fit on main page then print on main page only
                                 when (@NumDetails <= @vMP_RecordsPerPage) then @NumDetails
                                 -- if supplement page is after then print as many as we can on main page
                                 when (@SupplementPagePosition = 'After') then @vMP_RecordsPerPage
                                 -- if supplement page is before, then print as many as we can on supplement page
                                 -- and remaining on the main page
                                 when (@SupplementPagePosition = 'Before') then @NumDetails % @vSP_RecordsPerPage
                               end;

  /* Of course the supplement page would print the remaining records beyond what is printed on the main page */
  select @SupplementPageNumRecords = @NumDetails - coalesce(@MainPageNumRecords, @vMainPageNumRecords);

  /* Calculate the remaining total pages and add one to remaining total pages */
  if (@SupplementPageNumRecords = 0)
    select @TotalPages = coalesce(nullif(ceiling(@NumDetails * 1.0 / @vMP_RecordsPerPage), 0), 1);
  else
    -- there will always be a main page, so add the number of supplement pages
    select @TotalPages = 1 + ceiling (@SupplementPageNumRecords * 1.0 / @vSP_RecordsPerPage);

  if (@vIsMainPage = 'Y') and (@SupplementPagePosition in ('None', 'After'))
    select @StartIndex = 1, @EndIndex = @MainPageNumRecords;
  else
  if (@vIsMainPage = 'Y') and (@SupplementPagePosition = 'Before')
    select @StartIndex = @SupplementPageNumRecords + 1, @EndIndex = @NumDetails;
  else
  if (@vIsSupplementPage = 'Y') and (@SupplementPagePosition = 'Before')
    select @StartIndex = 1, @EndIndex = @SupplementPageNumRecords
  else
  if (@vIsSupplementPage = 'Y') and (@SupplementPagePosition = 'After')
    select @StartIndex = @MainPageNumRecords + 1, @EndIndex = @NumDetails;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_ComputeRecordsAndPages */

Go
