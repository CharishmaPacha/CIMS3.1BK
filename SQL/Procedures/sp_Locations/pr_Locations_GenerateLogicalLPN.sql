/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

                      pr_Locations_GenerateLogicalLPN: Consider Lot for uniqueness (S2GCA-216)
  2018/03/14  TK      pr_Locations_AddSKUToPicklane & pr_Locations_GenerateLogicalLPN: Changes to preprocess Logical LPN after adding SKU (S2G-367)
  2016/10/31  AY      pr_Locations_GenerateLogicalLPN: By default setup picking class on Picklane as U (HPI-GoLive)
  2016/04/07  AY      pr_Locations_GenerateLogicalLPN: Preprocess the logical LPN to have picking class on it.
                      pr_Locations_GenerateLogicalLPN: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_GenerateLogicalLPN') is not null
  drop Procedure pr_Locations_GenerateLogicalLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_GenerateLogicalLPN:
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_GenerateLogicalLPN
   (@LPNType      TTypeCode,
    @NumLPNs      TInteger,
    @LPNStatus    TStatus,
    @LocationId   TRecordId,
    @Location     TLocation,
    @SKU          TSKU,
    @Lot          TLot,
    @Warehouse    TWarehouse,
    @Ownership    TOwnership,
    @BusinessUnit TBusinessUnit,
    @UserId       TUserId,
    @LPNId        TRecordId output)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @UpdateOption         TFlag;
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @LPNId       = 0;

  /* Generates Logical LPN */
  exec @ReturnCode = pr_LPNs_Generate @LPNType,
                                      @NumLPNs,
                                      @Location,
                                      @Warehouse,
                                      @BusinessUnit,
                                      @UserId,
                                      @LPNId output;

  if (@ReturnCode > 1)
    goto ErrorHandler;

  /* Update LPN's Location, Status etc.
     update Ownership with given, else leave it as is. For most clients Onwership and BU are same and
     SKU Ownership may not be defined */
  /* There are chances that picklanes have same SKU with multiple Lots, so added Lot for uniqueness */
  update LPNs
  set LocationId    = @LocationId,
      Location      = @Location,
      UniqueId      = @Location + '-' + coalesce(@SKU, '') + '-' + coalesce(@Lot, ''),
      Status        = @LPNStatus,
      Ownership     = coalesce(@Ownership, Ownership)
    --  PickingClass  = 'U' /* Default */   -- This will be updated in LPNs_Preprocess
  where (LPNId = @LPNId);

  /* Update Count of LPNs in Location */
  exec @ReturnCode = pr_Locations_UpdateCount @LocationId   = @LocationId,
                                              @NumLPNs      = @NumLPNs,
                                              @UpdateOption = '+' /* Add */;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Locations_GenerateLogicalLPN */

Go
