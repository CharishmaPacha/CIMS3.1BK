/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/19  TK      pr_LPNDetails_FindLDToUpdate: Changes to consider OnhandStatus as well while finding LPN detail to update (CID-281)
  2019/05/15  SV      pr_LPNDetails_FindLDToUpdate: Included CoO in validation (CID-135)
  2019/01/31  TK      pr_LPNDetails_FindLDToUpdate: Initial Revision (S2GMI-79)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNDetails_FindLDToUpdate') is not null
  drop Procedure pr_LPNDetails_FindLDToUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNDetails_FindLDToUpdate: This Procedure returns LPNDetailId that can be
    updated on the requested LPN. When adding items to an existing LPN, we would
    need to identify the existing line to add to. For example, if user is adding
    3 IPs (12 units/IP), then we can only add to an existing line which also has
    12 units/IP. Likewise, if user is adding units (without IPs), then we would
    want to add to an existing line which does not have IPs. This procedure
    identifies as such and returns the matching LPN Detail.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNDetails_FindLDToUpdate
  (@LPNId                  TRecordId,
   @OnhandStatus           TStatus,
   @CoO                    TCoO,
   @SKUId                  TRecordId,
   @OrderId                TRecordId,
   @OrderDetailId          TRecordId,
   @UnitsPerPackage        TInteger,
   @Innerpacks             TInnerpacks,
   @Quantity               TQuantity,
   @LPNDetailId            TRecordId     = null  output,
   @LPNDetailInnerPacks    TInnerpacks   = 0     output,
   @LPNDetailQuantity      TQuantity     = 0     output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TMessage;
begin
  SET NOCOUNT ON;

  /* If Innerpacks is greater than zero then find if there exists an LPN detail with Innerpacks and
     matching the UnitsPerPackage */
  if (coalesce(@InnerPacks, 0) > 0)
    select @LPNDetailId         = LPNDetailId,
           @LPNDetailInnerPacks = InnerPacks,
           @LPNDetailQuantity   = Quantity
    from LPNDetails
    where (LPNId           = @LPNId) and
          (OnhandStatus    = coalesce(@OnhandStatus, OnhandStatus)) and
          (coalesce(CoO, '') = coalesce(@CoO, CoO, '')) and
          (SKUId           = @SKUId) and
          (OrderId         = coalesce(@OrderId, OrderId)) and
          (OrderDetailId   = coalesce(@OrderDetailId, OrderDetailId)) and
          (UnitsPerPackage = @UnitsPerPackage) and
          (InnerPacks > 0);
  else
    /* If Quantity is greater than zero then find if there exists an LPN detail with Innerpacks as Zero */
    select @LPNDetailId         = LPNDetailId,
           @LPNDetailInnerPacks = InnerPacks,
           @LPNDetailQuantity   = Quantity
    from LPNDetails
    where (LPNId         = @LPNId) and
          (OnhandStatus  = coalesce(@OnhandStatus, OnhandStatus)) and
          (coalesce(CoO, '') = coalesce(@CoO, CoO, '')) and
          (SKUId         = @SKUId) and
          (OrderId       = coalesce(@OrderId, OrderId)) and
          (OrderDetailId = coalesce(@OrderDetailId, OrderDetailId)) and
          (InnerPacks    = 0);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNDetails_FindLDToUpdate */

Go
