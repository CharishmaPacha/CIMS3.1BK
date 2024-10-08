/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/05/12  RV      pr_Shipping_GetPackingListData, fn_Shipping_GetPackingListDummyRecordsCount: Generalize the logic
                        to get the number dummy rows to print on the report with respect to the Report Name (CIMS-888)
  2015/10/14  VM      fn_Shipping_GetPackingListDummyRecordsCount: Added (FB-437)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Shipping_GetPackingListDummyRecordsCount') is not null
  drop Function fn_Shipping_GetPackingListDummyRecordsCount;
Go
/*------------------------------------------------------------------------------
  Function fn_Shipping_GetPackingListDummyRecordsCount:

    Returns the number of Dummy reocords to add to the packing list to fit the objects in required place
    based on the configuration. This function calls reccursively to return the dummy records depends upon
    page type.
------------------------------------------------------------------------------*/
Create Function fn_Shipping_GetPackingListDummyRecordsCount
  (@ActualRecordsCount TCount,
   @ReportName         TName, /* Report Name */
   @FirstTimeCall      TFlag = 'Y' /* Yes */,
   @BusinessUnit       TBusinessUnit)
  -------------------
   returns TInteger
as
begin
  declare @vDummyRecordsCount             TCount,
          @vFirstPageFullPageThreshold    TCount,
          @vFirstPagePartialPageThreshold TCount,
          @vRemPagesFullPageThreshold     TCount,
          @vRemPagesPartialPageThreshold  TCount,
          @vNextPageActualRecordCount     TCount;

  select @vDummyRecordsCount = 0;

  /* Get all the threshold value depends upon the pages from controls */
  if (@FirstTimeCall = 'Y' /* Yes */)
    select @vFirstPageFullPageThreshold    = dbo.fn_Controls_GetAsString(@ReportName, 'FP_FPTH', '0', @BusinessUnit, null /* UserId */),
           @vFirstPagePartialPageThreshold = dbo.fn_Controls_GetAsString(@ReportName, 'FP_PPTH', '0', @BusinessUnit, null /* UserId */),
           @vRemPagesFullPageThreshold     = dbo.fn_Controls_GetAsString(@ReportName, 'RP_FPTH', '0', @BusinessUnit, null /* UserId */),
           @vRemPagesPartialPageThreshold  = dbo.fn_Controls_GetAsString(@ReportName, 'RP_PPTH', '0', @BusinessUnit, null /* UserId */);
  else
     /* if not first page, all thresholds becomes remaining pages thresholds only as we are calling this function recursively */
    select @vFirstPageFullPageThreshold    = dbo.fn_Controls_GetAsString(@ReportName, 'RP_FPTH', '0', @BusinessUnit, null /* UserId */),
           @vFirstPagePartialPageThreshold = dbo.fn_Controls_GetAsString(@ReportName, 'RP_PPTH', '0', @BusinessUnit, null /* UserId */),
           @vRemPagesFullPageThreshold     = dbo.fn_Controls_GetAsString(@ReportName, 'RP_FPTH', '0', @BusinessUnit, null /* UserId */),
           @vRemPagesPartialPageThreshold  = dbo.fn_Controls_GetAsString(@ReportName, 'RP_PPTH', '0', @BusinessUnit, null /* UserId */);

  if (@vFirstPageFullPageThreshold = 0 /* Assumption is no settings done to all controls */)
    select @vDummyRecordsCount = 0;
  else
    begin
      if (@ActualRecordsCount <= @vFirstPagePartialPageThreshold)
        select @vDummyRecordsCount = (@vFirstPagePartialPageThreshold - @ActualRecordsCount);
      else
      if (@ActualRecordsCount < @vFirstPageFullPageThreshold)
        select @vDummyRecordsCount = (@vFirstPageFullPageThreshold - @ActualRecordsCount) + @vRemPagesPartialPageThreshold;
      else
      if (@ActualRecordsCount = @vFirstPageFullPageThreshold)
        select @vDummyRecordsCount = @vRemPagesPartialPageThreshold;
      else
      if (@ActualRecordsCount > @vFirstPageFullPageThreshold)
        begin
          /* Count the remaining records for next page(s) */
          select @vNextPageActualRecordCount = @ActualRecordsCount-@vFirstPageFullPageThreshold;

          /* Call the function recursively */
          /* Remaining pages */
          select @vDummyRecordsCount = dbo.fn_Shipping_GetPackingListDummyRecordsCount(@vNextPageActualRecordCount, @ReportName, 'N' /* FirstTimeCall */, @BusinessUnit)
        end
    end
  return(@vDummyRecordsCount)
end /* fn_Shipping_GetPackingListDummyRecordsCount */

Go
