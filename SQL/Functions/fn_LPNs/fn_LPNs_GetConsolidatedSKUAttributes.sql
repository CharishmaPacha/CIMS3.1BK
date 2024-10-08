/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/19  AY      pr_LPNs_ReceivedCounts: Corrections to update counts when Intransit LPNs are received
                      fn_LPNs_AllowNewInventory: Some callers passing in LocationId and some Location - fixed it.
                      fn_LPNs_GetConsolidatedSKUAttributes: Enhanced to compute for Pallet as well
  2019/12/11  RT      pr_LPNs_Recount: Included SKU to update on the LPNs
                      fn_LPNs_GetConsolidatedSKUAttributes: Included SKU (FB-1683)
  2016/05/05  TK      pr_LPNs_Recount: Enhanced to update SKU1 - SKU5 on LPNs
                      fn_LPNs_GetConsolidatedSKUAttributes: Initial Revision (FB-648)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_LPNs_GetConsolidatedSKUAttributes') is not null
  drop Function fn_LPNs_GetConsolidatedSKUAttributes;
Go
/*------------------------------------------------------------------------------
  Proc fn_LPNs_GetConsolidatedSKUAttributes:  This Function will returns the
    consolidated SKU attributes in the LPN, if any attribute has mutiple values
    then returns null else returns attribute value.
------------------------------------------------------------------------------*/
Create Function fn_LPNs_GetConsolidatedSKUAttributes
  (@LPNId     TRecordId,
   @PalletId  TRecordId)
  -------------------
returns
 @SKUAttributes table
    (SKU    TSKU,
     SKU1   TSKU,
     SKU2   TSKU,
     SKU3   TSKU,
     SKU4   TSKU,
     SKU5   TSKU)
as
begin
  /* Declarations */
  declare @ttSKUAttributes table
            (SKU    TSKU,
             SKU1   TSKU,
             SKU2   TSKU,
             SKU3   TSKU,
             SKU4   TSKU,
             SKU5   TSKU);

  declare @vSKUCount  TCount,
          @vSKU1Count TCount,
          @vSKU2Count TCount,
          @vSKU3Count TCount,
          @vSKU4Count TCount,
          @vSKU5Count TCount,

          @vSKUValue  TSKU,
          @vSKU1Value TSKU,
          @vSKU2Value TSKU,
          @vSKU3Value TSKU,
          @vSKU4Value TSKU,
          @vSKU5Value TSKU;

  /* Get all the distinct SKU Attributes in the LPN */
  if (@LPNId is not null)
    insert into @ttSKUAttributes(SKU, SKU1, SKU2, SKU3, SKU4, SKU5)
      select distinct coalesce(SKU, ''), coalesce(SKU1, ''), coalesce(SKU2, ''), coalesce(SKU3, ''),
             coalesce(SKU4, ''), coalesce(SKU5, '')
      from LPNDetails LD
        join SKUs S on (LD.SKUId = S.SKUId)
      where (LPNId = @LPNId);
  else
  if (@PalletId is not null)
    insert into @ttSKUAttributes(SKU, SKU1, SKU2, SKU3, SKU4, SKU5)
      select distinct coalesce(S.SKU, ''), coalesce(S.SKU1, ''), coalesce(S.SKU2, ''), coalesce(S.SKU3, ''),
             coalesce(S.SKU4, ''), coalesce(S.SKU5, '')
      from LPNs L
        join LPNDetails LD on (LD.LPNId = L.LPNId)
        join SKUs S        on (S.SKUId  = LD.SKUId)
      where (PalletId = @PalletId);

  /* Get the distinct count of each SKU Attributes */
  select @vSKUCount  = count(distinct SKU),
         @vSKU1Count = count(distinct SKU1),
         @vSKU2Count = count(distinct SKU2),
         @vSKU3Count = count(distinct SKU3),
         @vSKU4Count = count(distinct SKU4),
         @vSKU5Count = count(distinct SKU5),
         @vSKUValue  = Min(SKU),
         @vSKU1Value = Min(SKU1),
         @vSKU2Value = Min(SKU2),
         @vSKU3Value = Min(SKU3),
         @vSKU4Value = Min(SKU4),
         @vSKU5Value = Min(SKU5)
  from @ttSKUAttributes;

  /* If the SKU Attributes count is Unique the return it eles return null */
  insert into @SKUAttributes
    select case when (@vSKUCount  <> 1) then null else @vSKUValue  end /* SKU */,
           case when (@vSKU1Count <> 1) then null else @vSKU1Value end /* SKU1 */,
           case when (@vSKU2Count <> 1) then null else @vSKU2Value end /* SKU2 */,
           case when (@vSKU3Count <> 1) then null else @vSKU3Value end /* SKU3 */,
           case when (@vSKU4Count <> 1) then null else @vSKU4Value end /* SKU4 */,
           case when (@vSKU5Count <> 1) then null else @vSKU5Value end /* SKU5 */;

  return;
end /* fn_LPNs_GetConsolidatedSKUAttributes */

Go
