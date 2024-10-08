/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  RT      pr_BoL_GenerateCarrierDetails and pr_BoL_GenerateOrderDetails: Included fields and Rules to get the details (FB-2225)
                      pr_BoL_GenerateCarrierDetails: Generate details for Master BoL (HA-1954)
  2020/07/10  RKC     pr_BoL_GenerateOrderDetails, pr_BoL_GenerateCarrierDetails: If Palletized as N the do not include Pallet weight in the Load Weight (HA-1106)
  2019/05/03  RT      pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Removed the LPNDetails in the join statement (S2GCA-674)
  2019/05/01  RT      pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Included function to get teh CaseQty (S2GCA-667)
  2019/03/06  VS/TK   pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Changed the NumPackages Calculations (S2GCA-459)
  2018/09/14  AY/RT   pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Commented the changes regarding Pallet TareWeight/Volume to CarrierDetails and set to 0 by Default
  2018/09/12  AY/RT   pr_BoL_GenerateCarrierDetails: Made changes to print the NumCases in BoL report under Package
  2015/07/18  AY      pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Enh. to use Estimated Weight/Volume
  2013/06/20  VM      pr_BoL_GenerateCarrierDetails: Hazardous is alwasy 'No' for TD
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_GenerateCarrierDetails') is not null
  drop Procedure pr_BoL_GenerateCarrierDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_GenerateCarrierDetails:  This Procedure will generate the BoL Carrier
         details based on the BoLId. It will update  volume,quantity, Handling UnitType,
        Handling Unit Quantity.
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_GenerateCarrierDetails
  (@BoLId         TBoLId,
   @xmlRulesData  TXML  = null,
   @Regenerate    TFlag = 'N' /* No */)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          @Message            TDescription,
          @vBoLId             TBoLId,
          @vBoLType           TTypeCode,
          @vPalletized        TFlags,
          @vLoadId            TLoadId,
          @vSoldToCount       TCount,
          @vShipToStore       TShipToStore,
          @vBusinessUnit      TBusinessUnit,
          @vUserId            TUserId,
          @vPalletTareWeight  TInteger = 0,
          @vPalletTareVolume  TFloat   = 0.0;

  declare @ttBoLCarrierDetails table
          (BoLId             TBoLId,
           HandlingUnitQty   TCount,
           HandlingUnitType  TLookUpCode,
           PackageQuantity   TQuantity,
           PackageType       TTypeCode,
           TotalVolume       TVolume,
           TotalWeight       TWeight,
           NMFCCode          TLookUpCode,
           NMFCClass         TCategory,
           NMFCCommodityDesc TDescription,
           Hazardous         TFlag,
           UDF1              TUDF,
           UDF2              TUDF,
           UDF3              TUDF,
           UDF4              TUDF,
           UDF5              TUDF);

begin  /* pr_BoL_GenerateCarrierDetails */
  select @ReturnCode  = 0,
         @MessageName = null,
         @vUserId     = System_User;

  select * into #BoLCarrierDetails from @ttBoLCarrierDetails;

  /* Get Business Unit here */
  select @vBoLId        = BoLId,
         @vLoadId       = LoadId,
         @vBoLType      = BoLType,
         @vShipToStore  = UDF1,
         @vBusinessUnit = Businessunit
  from BoLs
  where (BoLId = @BoLId);

  /* Get the Load information */
  select @vPalletized = Palletized
  from Loads
  where (LoadId = @vLoadId);

  if (@BoLId is null)
    set @MessageName = 'BoLIdIsRequired';
  else
  if (@vBoLId is null)
    set @MessageName = 'InvalidBoLId';

  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* If user wants to regenerate then we need to delete details for the
     given BoLId from the BoLCarrierDetails table */
  if (@Regenerate = 'Y' /* Yes */ )
    delete from BoLCarrierDetails where (BoLId = @vBoLId);

  /* Get the PalletTareWeight and Volume and update accordingly */
  select @vPalletTareWeight = dbo.fn_Controls_GetAsInteger('BoL', 'PalletTareWeight', '35' /* lbs */, @vBusinessUnit, null),
         @vPalletTareVolume = dbo.fn_Controls_GetAsInteger('BoL', 'PalletVolume', '7680' /* cu.in. */, @vBusinessUnit, null);

  /* If details found for the given BoLId and not regenerate, exit else, we need to
     insert those details into the BoLCarrierDetails Table

     TODO TODO
     This needs to change to handle changes to BoL
     For example - there can be changes to Orders on Shipment and associated LPNs
     So, the details have to be recalculated and updated accordingly
     There can be new Carrier Details added OR counts on existing details can change */
  if (exists (select * from BoLCarrierDetails where (BoLId = @vBoLId)))
    goto ExitHandler;

  -- /* Get list of LPNs to consider for BoL */
  -- exec pr_BoLs_GenerateLPNs @BoLId, @vBoLType, @vLoadId, @vxmlRulesData, 'BoL_GenerateCarrierDetails', @vBusinessUnit, @vUserId;

  /* Insert BoL Carrier Details */
  insert into #BoLCarrierDetails(BoLId, HandlingUnitQty, HandlingUnitType, PackageQuantity, PackageType,
                                 TotalVolume, TotalWeight, Hazardous,
                                 UDF1, UDF2, UDF3, UDF4, UDF5)
    select @vBoLId, count(distinct BL.PalletId), 'plts', sum(BL.Packages), 'ctns',
           sum(BL.LPNVolume) + (count(distinct BL.PalletId) * @vPalletTareVolume),
           sum(BL.LPNWeight) + (count(distinct BL.PalletId) * @vPalletTareWeight),
            'N' /* Hazardous - 'No' for TD by default */,
            @vShipToStore, null, null, null, null
    from  #BoLLPNs BL
    group by BCD_GroupCriteria;

  /* Process the BoLCarrier Details */
  exec pr_RuleSets_ExecuteAllRules 'BoLCarrierDetails', @xmlRulesData, @vBusinessUnit;

  /* Insert the BoL Carrier details from the temp table */
  insert into BoLCarrierDetails
    (BoLId, HandlingUnitQty, HandlingUnitType, PackageQty, PackageType,
     Volume, Weight, Hazardous, CommDescription, NMFCCode, CommClass,
     UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit)
    select BoLId, HandlingUnitQty, HandlingUnitType, PackageQuantity, PackageType,
           TotalVolume, TotalWeight, Hazardous, NMFCCommodityDesc, NMFCCode, NMFCClass,
           UDF1, UDF2, UDF3, UDF4, UDF5, @vBusinessUnit
    from #BoLCarrierDetails;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_BoL_GenerateCarrierDetails */

Go
