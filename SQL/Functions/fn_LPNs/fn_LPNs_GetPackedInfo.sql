/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/01  RT      fn_LPNs_GetPackedInfo: Function to return the Packed info (S2GCA-667)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_LPNs_GetPackedInfo') is not null
  drop Function fn_LPNs_GetPackedInfo;
Go
/*------------------------------------------------------------------------------
  fn_LPNs_GetPackedInfo:
      This function returns PackInfo for an LPN

  Options:
    L  - LPN
    LD - LPNDetails

  Operation: to update the respective fields as per the operation
    BoL_GenerateCarrierDetails
    BoL_GenerateOrderDetails
    ShippingManifest
------------------------------------------------------------------------------*/
Create Function fn_LPNs_GetPackedInfo
  (@LPNId          TRecordId   = null,
   @Operation      TOperation  = null,
   @Options        TFlags      = 'L')
  -----------------------------
returns
  @PackInfo      table
    (LPNDetailId      TRecordId,
     InnerPacks       TInnerPacks,
     Quantity         TQuantity,
     Cases            TQuantity,
     UnitsPerPackage  TInteger
    )
as
begin
  /* Get the PackInfo of the respective LPN */
  insert into @PackInfo
    select LD.LPNDetailId, LD.InnerPacks, LD.Quantity,
           case when LD.InnerPacks <> 0 then LD.InnerPacks
                when LD.UnitsPerPackage > 0 and LD.Quantity >= LD.UnitsPerPackage then LD.Quantity/LD.UnitsPerPackage
                else 0
           end /* Cases */,
           case when coalesce(LD.UnitsPerPackage, 0) <> 0 then LD.UnitsPerPackage
                when LD.InnerPacks > 0 then LD.Quantity/LD.InnerPacks
                else 0
           end /* UnitsPerPackage */
    from LPNs L join LPNDetails LD on (L.LPNId = LD.LPNId)
    where (L.LPNId = @LPNId);

  /* if the cases are less than 0 the we consider it as 1 */
  if (@Operation like 'BoL_%' or @Operation like 'ShippingManifest%') and
     (not exists (select * from @PackInfo where Cases > 0))
    update @PackInfo
    set Cases = 1;

  return;
end /* fn_LPNs_GetPackedInfo */

Go
