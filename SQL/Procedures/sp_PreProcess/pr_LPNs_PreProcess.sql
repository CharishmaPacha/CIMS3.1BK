/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/13  TD      pr_LPNs_PreProcess, pr_ReceiptHeaders_PreProcess - Changes to update default Warehouse (CID-102)
  2019/02/01  MS      pr_LPNs_PreProcess: Changes to update PutawayClass (CID-52)
                      pr_LPNs_PreProcess: Changes not to consider LPN innerpacks (S2G-367)
  2018/02/27  TK      pr_LPNs_PreProcess: Bug fix to update Picking and Putaway Class (S2G-151)
  2016/08/03  YJ      pr_LPNs_PreProcess: Changed @xmlRulesData to use fn_XMLNode (NBD-643)
  2016/07/13  YJ      pr_LPNs_PreProcess: Change to use rules to determine Putaway class (NBD-643)
  2016/04/22  TK      pr_LPNs_PreProcess: Bug fix to update Picking class while adding SKU without inventory
  2015/01/25  DK/VM   pr_LPNs_PreProcess: Use rules to setup LPN Picking Class
  2014/04/29  PV      pr_LPNs_PreProcess: Changed fetching controlvalue 'PAByWeight'
  2014/03/25  TD      Added new Procedure pr_LPNs_PreProcess.
  2014/03/25  TD      Added new procedure pr_LPNs_PreProcess.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_PreProcess') is not null
  drop Procedure pr_LPNs_PreProcess;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_PreProcess:
  Flags: PAC - Update PA Class, PIC - Update Picking Class, null - Update both
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_PreProcess
  (@LPNId         TRecordId,
   @Flags         TFlags = null,
   @Businessunit  TBusinessUnit)
As
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @vLPNId               TRecordId,
          @vLPNInnerPacks       TInnerPacks,
          @vPickingClass        TPickingClass,
          @vPutawayClass        TCategory,
          @vDestZone            TLookUpCode,
          @vLPNQuantity         TInteger,
          @vLPNStatus           TStatus,
          @vLPNWarehouse        TWarehouse,

          @vSKUId               TRecordId,
          @vPalletTie           TInteger,
          @vInnerPacksPerLPN    TInteger,
          @vUnitsPerInnerPack   TInteger,
          @vUnitsPerLPN         TInteger,
          @vCaseHeight          THeight,
          @vLPNLayers           TInteger,
          @vLPNHeight           THeight,
          @vLPNPercentFull      TInteger,
          @vMaxUnitWeight       TWeight,
          @vMaxLPNWeight        TWeight,
          @vLPNWeight           TWeight,
          @vUnitWeight          TWeight,

          @vLocationId          TRecordId,
          @vLocationType        TTypeCode,
          @vLocStorageType      TTypeCode,
          @vDestLocation        TLocation,
          @vDestLocationType    TLocationType,

          @vUseSKUStandardQty   TFlag,
          @vUseFLThresholdQty   TFlag,

          @vPCFLThreshold       TControlValue,
          @vPCPLThreshold       TControlValue,
          @vUseInnerPacks       TControlValue,
          @vPAByWeight          TControlValue;

  declare @xmlRulesData         TXML,
          @vPickingRulesResult  TResult,
          @vPutawayRulesResult  TResult;

begin
  SET NOCOUNT ON;

  /* At GNC, LPN is considered and picked as a Full LPN during picking if it has at least 80% of the StdCasesPerPallet
     and partial if is between 40 & 80 and if less than 40 then it is picked as individual cases */
  select @vUseFLThresholdQty   = dbo.fn_Controls_GetAsBoolean('Allocation', 'UseFLThresholdQty',     'N' /* No */, @BusinessUnit, null /* UserId */),
         @vPCFLThreshold       = dbo.fn_Controls_GetAsString ('Allocation', 'FLThreshold',           '80',   @BusinessUnit, null),
         @vPCPLThreshold       = dbo.fn_Controls_GetAsString ('Allocation', 'PLThreshold',           '40',   @BusinessUnit, null),
         @vMaxLPNWeight        = dbo.fn_Controls_GetAsInteger('Putaway',    'MaxLPNWeightForRacks',  '2000', @BusinessUnit, null),
         @vMaxUnitWeight       = dbo.fn_Controls_GetAsInteger('Putaway',    'MaxUnitWeightForRacks', '30',   @BusinessUnit, null),
         @vPAByWeight          = dbo.fn_Controls_GetAsBoolean('Putaway',    'ByWeight',              'N' /* No */, @BusinessUnit, null),
         @vUseInnerPacks       = dbo.fn_Controls_GetAsBoolean('System',     'UseInnerPacks',         'N' /* No */, @BusinessUnit, null /* UserId */),
         @vUseSKUStandardQty   = dbo.fn_Controls_GetAsBoolean('SKU',        'UseSKUStandardQty',     'N' /* No */, @BusinessUnit, null /* UserId */);

  /* Get LPNDetails InnerPacks Here */
  select top 1 @vLPNInnerPacks = coalesce(InnerPacks, 0),
               @vLPNQuantity   = Quantity,
               @vLPNId         = LPNId,
               @vSKUId         = SKUId,
               @vLocationId    = LocationId,
               @vLPNStatus     = LPNStatus,
               @vLPNWeight     = Weight
  from vwLPNDetails
  where (LPNId  = @LPNId)
  order by InnerPacks desc, Quantity desc;

  /* If we are adding SKU without inventory the there wouldn't be any details for the Locagical LPN and hence we are not updating Picking class on it */
  select @vLPNId        = LPNId,
         @vLocationId   = coalesce(@vLocationId, LocationId),
         @vPickingClass = coalesce(PickingClass, ''),
         @vPutawayClass = coalesce(PutawayClass, ''),
         @vDestZone     = DestZone,
         @vDestLocation = DestLocation,
         @vLPNWarehouse = DestWarehouse
  from LPNs
  where (LPNId  = @LPNId);

  /* If the LPN is Consumed, Allocated, Picked, Staged, Loaded, Shipped or Voided then we don't need to update
     either one - so return */
  if (charindex(@vLPNStatus, 'CAKGLSV') > 0)
    return;

  /* Get SKU Details */
  select @vSKUId             = SKUId,
         @vPalletTie         = nullif(PalletTie, 0),
         @vInnerPacksPerLPN  = coalesce(InnerPacksPerLPN, 0),
         @vUnitsPerInnerPack = nullif(UnitsPerInnerPack, 0),
         @vUnitsPerLPN       = coalesce(UnitsPerLPN, 0),
         @vCaseHeight        = coalesce(InnerPackHeight, 1),
         @vUnitWeight        = coalesce(UnitWeight, 0)
  from SKUs
  where (SKUId = @vSKUId);

  if ((coalesce(@vLPNId, 0) = 0) or
      (coalesce(@vSKUId, 0) = 0))
  return;

  /* Calculate height of the LPN. Height of the LPN is the number of layers which is inturn
     computed as InnerPacks/PalletTie i.e  */
  select @vLPNLayers = ceiling(1.0 * @vLPNInnerPacks / @vPalletTie);
  select @vLPNHeight = @vLPNLayers * @vCaseHeight;

  /* Calculate picking class value */
  if (coalesce(@vInnerPacksPerLPN, 0) > 0)
    select @vLPNPercentFull = ((1.0 * @vLPNInnerPacks / @vInnerPacksPerLPN) * 100);

  /* Get Location Details here */
  if (coalesce(@vLocationId, 0) > 0)
    select @vLocationType   = LocationType,
           @vLocStorageType = StorageType
    from Locations
    where (LocationId = @vLocationId);

  /* if Dest Location is know, get it's Location Type */
  if (@vDestLocation is not null)
    select @vDestLocationType = LocationType
    from Locations
    where (Location = @vDestLocation) and (BusinessUnit = @BusinessUnit);

  /* Setup PickingClass based on Rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('PutawayClassType',   'LPN')                +
                           dbo.fn_XMLNode('PickingClassType',   'LPN')                +
                           dbo.fn_XMLNode('EntityType',         'LPN')                +
                           dbo.fn_XMLNode('Operation',          'PreProcess')         +
                           dbo.fn_XMLNode('Flags',              coalesce(@Flags, '')) +
                           dbo.fn_XMLNode('PickingClass',       @vPickingClass)       +
                           dbo.fn_XMLNode('PutawayClass',       @vPutawayClass)       +
                           dbo.fn_XMLNode('DestZone',           @vDestZone)           +
                           dbo.fn_XMLNode('PAByWeight',         @vPAByWeight)         +
                           dbo.fn_XMLNode('LPNHeight',          @vLPNHeight)          +
                           dbo.fn_XMLNode('UnitWeight',         @vUnitWeight)         +
                           dbo.fn_XMLNode('MaxUnitWeight',      @vMaxUnitWeight)      +
                           dbo.fn_XMLNode('MaxLPNWeight',       @vMaxLPNWeight)       +
                           dbo.fn_XMLNode('LPNInnerPacks',      @vLPNInnerPacks)      +
                           dbo.fn_XMLNode('LPNQuantity',        @vLPNQuantity)        +
                           dbo.fn_XMLNode('PalletTie',          @vPalletTie)          +
                           dbo.fn_XMLNode('LocationType',       @vLocationType)       +
                           dbo.fn_XMLNode('LocStorageType',     @vLocStorageType)     +
                           dbo.fn_XMLNode('DestLocation',       @vDestLocation)       +
                           dbo.fn_XMLNode('DestLocationType',   @vDestLocationType)   +
                           dbo.fn_XMLNode('UseSKUStandardQty',  @vUseSKUStandardQty)  +
                           dbo.fn_XMLNode('UnitsPerLPN',        @vUnitsPerLPN)        +
                           dbo.fn_XMLNode('UnitsPerInnerPack',  @vUnitsPerInnerPack)  +
                           dbo.fn_XMLNode('InnerPacksPerLPN',   @vInnerPacksPerLPN)   +
                           dbo.fn_XMLNode('UseFLThresholdQty',  @vUseFLThresholdQty)  +
                           dbo.fn_XMLNode('PCFLThreshold',      @vPCFLThreshold)      +
                           dbo.fn_XMLNode('PCPLThreshold',      @vPCPLThreshold)      +
                           dbo.fn_XMLNode('LPNPercentFull',     @vLPNPercentFull)     +
                           dbo.fn_XMLNode('Warehouse',          @vLPNWarehouse)       +
                           dbo.fn_XMLNode('LPNStatus',          @vLPNStatus)          +
                           dbo.fn_XMLNode('LPNId',              @vLPNId));

  /* Get the Picking Class */
  if (coalesce(@Flags, '') in ('PIC', ''))
    exec pr_RuleSets_Evaluate 'LPN_PickingClass', @xmlRulesData, @vPickingRulesResult output;

  /* Get the Putaway Class */
  if (coalesce(@Flags, '') in ('PAC', ''))
    exec pr_RuleSets_Evaluate 'LPN_PutawayClass', @xmlRulesData, @vPutawayRulesResult output;

  /* On Preprocess, beyond PutawayClass and Picking Classes, there may be other updates to
     be done like update WH on Intransit LPNs for CID, we now use the rules to do such updates */
  exec pr_RuleSets_ExecuteRules 'LPN_PreprocessUpdates', @xmlRulesData;

  /* Update PickingClass */
  update LPNs
  set PutawayClass = coalesce(@vPutawayRulesResult, @vPutawayClass),
      PickingClass = coalesce(@vPickingRulesResult, @vPickingClass),
      ModifiedDate = current_timestamp,
      ModifiedBy   = 'CIMSAgent'
  where (LPNId = @vLPNId);

end /* pr_LPNs_PreProcess */

Go
