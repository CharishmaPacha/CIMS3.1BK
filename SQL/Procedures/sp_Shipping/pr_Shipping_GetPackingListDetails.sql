/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/15  MS      pr_Shipping_GetPackingListDetails: Changes to compute page numbers
                      pr_Shipping_GetPackingListDetails_ComputePages renamed as pr_Printing_ComputeTotalPages (CIMSV3-1234)
  2020/10/20  PK      pr_Shipping_GetPackingListDetails_ComputePages: Send 50 as RemainingPageNumRows control var - Port back from Prod/Stag onsite by VM (HA-1483)
  2020/06/13  MS      pr_Shipping_GetPackingListData_New, pr_Shipping_GetPackingListDetails,
                      pr_Shipping_GetPackingListDetails_ComputePages: Changes to print Append file (HA-857)
  2020/05/29  RV      pr_Shipping_GetPackingListDetails: Bug fixed to do not send duplicate details in the append report (HA-666)
  2020/01/04  AY      pr_Shipping_GetPackingListDetails & pr_Shipping_GetPackingListDetails_ComputePages: Corrections and
                        code re-organization
  2019/08/09  MS      pr_Shipping_GetPackingListDetails: Changes to not to print UnitsOrdered & BackOrdQty on LPNWithORD PL Types
                      pr_Shipping_GetPackingListData: Changes to callers (HPI-2691)
  2019/08/07  MS      pr_Shipping_GetPackingListDetails: Changes to get the Dataset from Rules (HPI-2656)
  2018/10/05  AY      pr_Shipping_GetPackingListDetails: Changed to print short lines for PCPK/PTS waves (S2GCA-354)
  2018/08/12  RT      pr_Shipping_GetPackingListDetails: Added LPN to in the Carton Packing List (OB2-555)
  2018/07/18  RV      pr_Shipping_GetPackingListDetails: Remove client specific code (S2G-1052)
  2018/05/16  RV      pr_Shipping_GetPackingListDetails: Bug fixed to avoid Divided by zero error, if no controls are setup for
                        single report Packing List (S2G-846)
  2018/05/01  RV/RT   pr_Shipping_GetPackingListData, pr_Shipping_GetPackingListDetails: Made changes to print
                        fixed records on first page and remaining records on second page if required (HPI-1498)
  2016/07/20  YJ      Added pr_Shipping_GetPackingListDetails: Packing List Detail Customizations(HPI-330)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetPackingListDetails') is not null
  drop Procedure pr_Shipping_GetPackingListDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetPackingListDetails: Returns the list of details to print
    for the particular packing list. Some PLs have a limited set of records that
    can be printed on the first page (as there is a label) and so the additional
    details will be printed on the addendum page. In such scenario, the additional
    records to be printed on addendum page would be returned in PLDetailsxml2.
    PLDetailsxml1 will be at least the first page records or may be the complete
    set for a report where there is no addendum page.

 PackingListType: There are different types of Packing lists data to print. Here
   are the variations and their usage.

   High level: Packing lists are defined as ORD or LPN Packing lists. ORD
   packing list means it is printed for an Order, LPN Packing list means it is
   printed for an LPN. In the scenario, an Order can have multiple LPNs and each
   have an individual packing list, including a master for the entire order.

   ORD-MATRIX: This is an Order packing list of the Order details to be printed
     in a matrix form with the sizes shown as columns.
   ORD: Order packing list with the Order details listed out.
   LPNwithODs: This is an LPN Packing list i.e. intiatied by an LPN, but the
     entire order detials are printed. This is typically printed for the first
     or last LPN of the Order with the entire order details. We refer to this
     as LPN packing list not just because it is printed for an LPN, but because
     it does have the LPN details as well like the shipping label and other info.
   ORDwithLDs: This is an order packing list with the details of all the LPNs of
     the order. i.e. it would show each LPN and it's contents.
   LPN/ReturnLPN: This is packing list printed for an LPN with the details of the LPN
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetPackingListDetails
  (@LoadId           TRecordId,
   @OrderId          TRecordId,
   @LPNId            TRecordId,
   @Report           TName,
   @PackingListType  TTypeCode,
   @xmlRulesData     TXML,
   @PLDetailsxml     TXML     output,
   @TotalPages       TInteger output,
   @NumPackedDetails TInteger output,
   @BusinessUnit     TBusinessUnit)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TDescription,

          @vMainPageNumRows         TInteger,
          @vSupplementPageNumRows   TInteger,
          @vPageType                TName,
          @vSupplementPagePosition  TName,
          @vStartIndex              TInteger,
          @vEndIndex                TInteger,
          @vNumDetails              TCount,
          @vSupplementReport        TName,
          @vUserId                  TUserId;

  declare @ttPackingListDetails  TPackingListDetails;

begin
  SET NOCOUNT ON;

  /* select to create table structure for #ttPackingListDetails */
  select * into #ttPackingListDetails from @ttPackingListDetails

  /* Get the dataset to print on packingslips */
  exec pr_RuleSets_ExecuteRules 'PackingListDetails' /* RuleSetType */, @xmlRulesData;

  /* Finalize all the packinglist details */
  exec pr_RuleSets_ExecuteAllRules 'PackingListDetails_Finalize' /* RuleSetType */, @xmlRulesData, @BusinessUnit;

  /* Get NumDetails to print */
  select @vNumDetails = count(*) from #ttPackingListDetails;

  /* Get the Totalpages & Numrows to print on first page */
  exec pr_Printing_ComputeRecordsAndPages @Report, @vNumDetails, @BusinessUnit, @vUserId, @TotalPages output, @vMainPageNumRows output,
                                          @vSupplementPageNumRows output, @vPageType output, @vSupplementPagePosition output,
                                          @vStartIndex output, @vEndIndex output;

  set @PLDetailsxml = (select * from #ttPackingListDetails
                        where (Counter between @vStartIndex and @vEndIndex)
                        order by SortOrder
                        for xml raw('PACKINGLISTDETAILS'), elements);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_GetPackingListDetails */

Go
