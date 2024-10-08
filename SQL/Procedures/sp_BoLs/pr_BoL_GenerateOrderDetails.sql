/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/28  SK      pr_BoL_GenerateOrderDetails: Changes for consolidating report based on User selection (HA-2676)
  2021/04/27  RKC     pr_BoL_GenerateOrderDetails, pr_BoL_GetCustomerOrderTotalsAsXML: Made changes to get the correct weight on the BOLs (HA-2650)
  2021/04/19  AY      pr_BoL_GenerateOrderDetails: Bug fix for Transfer Loads where some LPNs may have CustPO and some may not (HA GoLive)
  2021/03/27  RV      pr_BoL_GenerateOrderDetails: Made changes to update the shipper info from BOL LPNs (HA-2390)
  2021/03/07  SK      pr_BoL_GenerateOrderDetails: New field "AdditionalShipperInfo" to temp table (HA-2152)
  2021/02/03  RT      pr_BoL_GenerateCarrierDetails and pr_BoL_GenerateOrderDetails: Included fields and Rules to get the details (FB-2225)
  2021/02/02  AY/RKC  pr_BoL_GenerateOrderDetails: Generate details for Master BoL,
  2020/07/10  RKC     pr_BoL_GenerateOrderDetails, pr_BoL_GenerateCarrierDetails: If Palletized as N the do not include Pallet weight in the Load Weight (HA-1106)
  2019/05/03  RT      pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Removed the LPNDetails in the join statement (S2GCA-674)
  2019/05/01  RT      pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Included function to get teh CaseQty (S2GCA-667)
  2019/03/06  VS/TK   pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Changed the NumPackages Calculations (S2GCA-459)
  2018/09/14  AY/RT   pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Commented the changes regarding Pallet TareWeight/Volume to CarrierDetails and set to 0 by Default
                      pr_BoL_GenerateOrderDetails: Changes NumInnerPacks to NumCases (S2GCA-255)
  2015/07/18  AY      pr_BoL_GenerateCarrierDetails, pr_BoL_GenerateOrderDetails: Enh. to use Estimated Weight/Volume
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_GenerateOrderDetails') is not null
  drop Procedure pr_BoL_GenerateOrderDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_GenerateOrderDetails: This procwill take BoLId as input and generate
          data based on that BoL iD from different tables. This will update Num UNits,
          #LPNs, #Packages , Quantity, Volume,Weight....
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_GenerateOrderDetails
  (@BoLId         TBoLId,
   @xmlRulesData  TXML  = null,
   @Regenerate    TFlag = 'N' /* No */)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,
          @vBoLId            TBoLId,
          @vBoLType          TTypeCode,
          @vPalletized       TFlags,
          @vLoadId           TLoadId,
          @vLoadType         TTypeCode,
          @vSoldToCount      TCount,
          @vShipToStore      TShipToStore,
          @vTotalOrders      TCount,
          @vShipToCount      TCount,
          @vTotalPallets     TCount,
          @vTotalLPNs        TCount,
          @vTotalPackages    TCount,
          @vTotalUnits       TCount,
          @vOrderId          TRecordId,
          @vVolume           TFloat,
          @vWeight           TFloat,
          @vPalletTareWeight TInteger = 0,
          @vPalletTareVolume TFloat   = 0.0,
          @vxmlRulesData     TXML,
          @vBusinessUnit     TBusinessUnit,
          @vUserId           TUserId;

  declare @ttBoLOrderDetails table
          (BoLId                  TBoLId,
           CustPO                 TCustPO,
           NumPallets             TCount,
           NumLPNs                TCount,
           NumInnerPacks          TCount,
           NumUnits               TCount,
           NumPackages            TCount,
           NumShippables          TCount,
           TotalVolume            TVolume,
           TotalWeight            TVolume,
           Palletized             TFlag,
           BOD_Reference1         TReference,
           BOD_Reference2         TReference,
           BOD_Reference3         TReference,
           BOD_Reference4         TReference,
           BOD_Reference5         TReference,
           BOD_GroupCriteria      TCategory,
           ShipperInfo            TDescription,

           UDF1                   TUDF,
           UDF2                   TUDF,
           UDF3                   TUDF,
           UDF4                   TUDF,
           UDF5                   TUDF);

begin /* pr_BoL_GenerateOrderDetails */
  select @ReturnCode  = 0,
         @MessageName = null,
         @vUserId     = System_User;

  select * into #BoLOrderDetails from @ttBoLOrderDetails;

  /* Get Business Unit here */
  select @vBoLId        = BoLId,
         @vBoLType      = BoLType,
         @vLoadId       = LoadId,
         @vShipToStore  = UDF1,
         @vBusinessUnit = Businessunit
  from BoLs
  where (BoLId = @BoLId);

  /* Get the Load information */
  select @vPalletized = Palletized,
         @vLoadType   = LoadType
  from Loads
  where (LoadId = @vLoadId);

  if (@BoLId is null)
    set @MessageName = 'BoLIdIsRequired';
  else
  if (@vBoLId is null)
    set @MessageName = 'InvalidBoLId';

  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Get the PalletTareWeight and Volume and update accordingly */
  select @vPalletTareWeight = dbo.fn_Controls_GetAsInteger('BoL', 'PalletTareWeight', '35' /* lbs */, @vBusinessUnit, null),
         @vPalletTareVolume = dbo.fn_Controls_GetAsInteger('BoL', 'PalletVolume', '7680' /* cu.in. */, @vBusinessUnit, null);

  /* If user wants to regenerate then we need to delete details for the
        given BoLId from the BoLCarrierDetails table */
  if (@Regenerate = 'Y' /* Yes */ )
    delete from BoLOrderDetails where (BoLId = @vBoLId);

  /* If no details found for the given BoLid then we need to insert those details
     into the BoLOrderDetails Table

     TODO TODO
     This needs to change to handle changes to BoL
     For example - there can be changes to Orders on Shipment and associated LPNs
     So, the details have to be recalculated and updated accordingly
     There can be new Order Details added OR counts on existing details can change */
  if (exists (select * from BoLOrderDetails where (BoLId = @vBoLId)))
    goto ExitHandler;

  /* TODO
     Should revisit
     The counts have to calculated for Palletized and Non-Palletized Inventory */

  -- /* Get list of LPNs to consider for BoL */
  -- exec pr_BoLs_GenerateLPNs @BoLId, @vBoLType, @vLoadId, @vxmlRulesData, 'BoL_GenerateOrderDetails', @vBusinessUnit, @vUserId;

  /* Build the standard set of BoLOrder details. If they need to be different, then we can do so in rules */
  insert into #BoLOrderDetails
    (BoLId, CustPO, NumPallets, NumLPNs, NumInnerPacks, NumUnits,
     NumPackages, Palletized, TotalVolume, TotalWeight,
     BOD_Reference1, BOD_Reference2, BOD_Reference3, BOD_Reference4, BOD_Reference5, BOD_GroupCriteria, ShipperInfo,
     UDF1, UDF2, UDF3, UDF4, UDF5)
    select @vBoLId, min(BL.CustPO), count(distinct BL.PalletId), count(BL.LPNId), sum(BL.InnerPacks), sum(BL.Quantity),
           sum(BL.Packages), coalesce(@vPalletized, case when count(distinct BL.PalletId) > 0 then 'Y' else 'N' end),
           sum(BL.LPNVolume), sum(BL.LPNWeight),
           min(BOD_Reference1), min(BOD_Reference2), min(BOD_Reference3), min(BOD_Reference4), min(BOD_Reference5), BOD_GroupCriteria, min(BOD_ShipperInfo),
           @vShipToStore, null, null, null, null
    from #BoLLPNs BL
    group by BL.BOD_GroupCriteria;

  /* Get the BoLCarrierDetails - provides for customization of BoLOrderDetails */
  exec pr_RuleSets_ExecuteAllRules 'BoLOrderDetails', @xmlRulesData, @vBusinessUnit;

  /* Insert data into table from temp table. For Transfer Loads, we would add LPNs to Load
     which are not associated with any orders and so there may not be a CustPO. In that case,
     show the literal word Transfer */
  insert into BoLOrderDetails(BoLId, CustomerOrderNo, NumPallets, NumLPNs, NumInnerPacks, NumUnits,
                              NumPackages, NumShippables, Volume, Weight, Palletized,
                              ShipperInfo, BusinessUnit,
                              BOD_Reference1, BOD_Reference2, BOD_Reference3, BOD_Reference4, BOD_Reference5, BODGroupCriteria,
                              UDF1, UDF2, UDF3, UDF4, UDF5)
    select BoLId, case when @vLoadType = 'Transfer' then coalesce(CustPO, @vLoadType) else CustPO end, NumPallets, NumLPNs, NumInnerPacks, NumUnits,
           NumPackages, NumShippables, TotalVolume, TotalWeight, Palletized,
           ShipperInfo, @vBusinessUnit,
           BOD_Reference1, BOD_Reference2, BOD_Reference3, BOD_Reference4, BOD_Reference5, BOD_GroupCriteria,
           UDF1, UDF2, UDF3, UDF4, UDF5
    from #BoLOrderDetails;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_BoL_GenerateOrderDetails */

Go
