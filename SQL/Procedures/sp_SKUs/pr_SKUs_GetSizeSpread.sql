/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/01  VM      pr_SKUs_GetSizeSpread: Consider SKU3 as size always in terms of CIMS (HA-1037)
  2020/03/02  AY      pr_SKUs_GetSizeSpread: Get the size scale and counts in SKUSortOrder (JL-123)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_GetSizeSpread') is not null
  drop Procedure pr_SKUs_GetSizeSpread;
Go
/*------------------------------------------------------------------------------
  pr_SKUs_GetSizeSpread: for the given list of sizes (#SizeList - TSizeList),
   this procedure would list the sizes and the requested counts in the order of
   SKU SortOrder. This is useful to print the size scale and quantities on
   labels and reports.

 Example, if an LPN had 3 SKUs with the respective quantities as
  S - 10, M - 8, L - 12 and those are populated into #SizeList, this proc would
  format them as
  S  M  L (SizeScale)
 10  8 12 (Count1Spread)

 Assumptions:
 - Input information is loaded into #SizeList table of type TSizeList
 - Size is always in field SKU3
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_GetSizeSpread
 (@NumSpaces     TInteger = 2,
  @Align         TFlag    = 'R',
  -----------------------------------
  @SizeScale     TVarchar = null out,
  @Count1Spread  TVarchar = null out,
  @Count2Spread  TVarchar = null out,
  @Count3Spread  TVarchar = null out)
as
  declare @vMaxWidth  TInteger,
          @vWidth     TInteger,
          @vSpacer    TVarchar,
          @vDebug     TFlags;
begin /* pr_SKUs_GetSizeSpread */
  SET NOCOUNT ON;

  select @SizeScale    = '',
         @Count1Spread = '',
         @Count2Spread = '',
         @Count3Spread = '';

  /* Update the sizes and SKU Sort Order */
  update SL
  set Size         = coalesce(Size, S.SKU3),
      SKUSortOrder = S.SKUSortOrder
  from #SizeList SL join SKUs S on SL.SKUId = S.SKUId;

  select @vWidth = dbo.fn_MaxOfThree(max(len(Size)), len(max(Count1)), len(max(Count2)))
  from #SizeList;

  select @vSpacer = space(@NumSpaces);

  select @SizeScale += dbo.fn_AddWhiteSpaces(Size, @Align, @vWidth) + @vSpacer
  from #SizeList
  order by SKUSortOrder;

  select @Count1Spread += dbo.fn_AddWhiteSpaces(Count1, @Align, @vWidth) + @vSpacer
  from #SizeList
  order by SKUSortOrder;

  select @Count2Spread += dbo.fn_AddWhiteSpaces(Count2, @Align, @vWidth) + @vSpacer
  from #SizeList
  order by SKUSortOrder;

  select @Count3Spread += dbo.fn_AddWhiteSpaces (Count3, @Align, @vWidth) + @vSpacer
  from #SizeList
  order by SKUSortOrder;

  if charindex('D', @vDebug) > 0
    begin
      select * from #SizeList order by SKUSortOrder;
      select @SizeScale, @Count1Spread, @Count2Spread, @Count3Spread;
    end;
end /* pr_SKUs_GetSizeSpread */

Go
