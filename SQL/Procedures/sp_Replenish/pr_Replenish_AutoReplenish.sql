/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/11/16  AY      pr_Replenish_AutoReplenish: Release min-max replenishments on creation.
  2014/09/03  PK      Added pr_Replenish_AutoReplenish
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_AutoReplenish') is not null
  drop Procedure pr_Replenish_AutoReplenish;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_AutoReplenish: This procedure will be setup as a Job to run
    auto replenishments without user intervention.
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_AutoReplenish
  (@BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @StorageType    TStorageType = null,
   @PickingZone    TLookUpCode  = null,
   @PutawayZone    TLookUpCode  = null,
   @Location       TLocation    = null,
   @ReplenishType  TTypeCode    = 'R',
   @SKU            TSKU         = null)
as
  declare @vMessageName         TMessageName,
          @vReturnCode          TInteger,

          @LocsToReplenish      XML,
          @vLocsToReplenish     TXML,
          @vGenerateReplenishOrders
                                TXML,
          @vLocationsInfo       TXML,
          @vOptions             TXML,
          @vConfirmMessage      TDescription,
          @vAutoRelease         TFlags = 'Y',
          @vNewWaveNo           TWaveNo,
          @ttWavesToRelease     TEntityKeysTable;

  declare @ttLocationsToReplenish Table
          (RecordId             TRecordId,

           LocationId           TRecordId,
           Location             TLocation,
           LocationType         TTypeCode,
           LocationSubType      TTypeCode,
           LocationRow          TRow,
           LocationLevel        TLevel,
           LocationSection      TSection,
           StorageType          TTypeCode,
           Status               TStatus,
           PutawayZone          TLookUpCode,
           PickZone             TLookUpCode,

           SKUId                TRecordId,
           SKU                  TSKU,
           SKU1                 TSKU,
           SKU2                 TSKU,
           SKU3                 TSKU,
           SKU4                 TSKU,
           SKU5                 TSKU,
           ProdCategory         TCategory,
           ProdSubCategory      TCategory,

           LPNId                TRecordId,
           LPN                  TLPN,

           Quantity             TQuantity,
           InnerPacks           TInnerPacks,
           UnitsPerLPN          TQuantity,
           MinReplenishLevel    TQuantity,
           MinReplenishLevelDesc
                                TDescription,
           MinReplenishLevelUnits
                                TQuantity,
           MinReplenishLevelInnerPacks
                                TInnerPacks,
           MaxReplenishLevel    TQuantity,
           MaxReplenishLevelDesc
                                TDescription,
           MaxReplenishLevelUnits
                                TQuantity,
           MaxReplenishLevelInnerPacks
                                TInnerPacks,

           PercentFull          TInteger,
           MinToReplenish       TQuantity,
           MinToReplenishDesc   TDescription,
           MaxToReplenish       TQuantity,
           MaxToReplenishDesc   TDescription,
           ReplenishUoM         TUoM,

           UnitsInProcess       TQuantity,
           OrderedUnits         TQuantity,
           ResidualUnits        TQuantity,
           ReplenishType        TTypeCode,
           HotReplenish         TTypeCode, -- SKU can be both Required/Fill Up as well as Hot, hence diff. flag is needed
           Ownership            TOwnership,
           Warehouse            TWarehouse,
           InventoryAvailable   TFlag,

           CurrentQty           TQuantity  default 0,
           UnitsOnOrder         TQuantity  default 0,
           DirectedQty          TQuantity  default 0,
           AllocatedQty         TQuantity  default 0,
           ToAllocateQty        TQuantity  default 0,
           FinalQty             TInteger);
begin

  /* generate the xml string with the selections */
  select @LocsToReplenish = (select @StorageType    StorageType,
                                    @PickingZone    PickZone,
                                    @PutawayZone    PutawayZone,
                                    @Location       Location,
                                    @ReplenishType  ReplenishType,
                                    @SKU            SKU
                             FOR XML RAW('SELECTIONS'), TYPE, ELEMENTS XSINIL, ROOT('LOCATIONSTOREPLENISH'));

  select @vLocsToReplenish = convert(varchar(max), @LocsToReplenish);

  /* insert the Locations which are to be replenished */
  insert into @ttLocationsToReplenish
    exec pr_Replenish_LocationsToReplenish @vLocsToReplenish, @BusinessUnit, @UserId, @vConfirmMessage;

  /* if there are no Locations to replenish then exit */
  if (@@rowcount = 0)
    goto ExitHandler;

  /* get the selection criteria to generate the replenish orders */
  select @vLocationsInfo = (select coalesce(Location, '')       as Location,
                                   coalesce(StorageType, '')    as StorageType,
                                   coalesce(SKU,      '')       as SKU,
                                   coalesce(ReplenishUoM, '')   as ReplenishUoM,
                                   coalesce(MaxToReplenish, '') as QtyToReplenish,
                                   coalesce(Ownership,      '') as Ownership,
                                   coalesce(Warehouse,      '') as Warehouse
                            from @ttLocationsToReplenish
                            where (Location      like coalesce(@Location + '%', Location))
                                  /* these filters are already applied in pr_Replenish_LocationsToReplenish */
                                  --(StorageType   = coalesce(@StorageType,   StorageType)) and
                                  --(PickZone      = coalesce(@PickingZone,   PickZone)) and
                                  --(PutawayZone   = coalesce(@PutawayZone,   PutawayZone)) and
                                  --(ReplenishType = coalesce(@ReplenishType, ReplenishType)) and
                                  --(SKU           = coalesce(@SKU,           SKU))
                            FOR XML RAW('LOCATIONSINFO'), ELEMENTS),
         @vOptions = '<OPTIONS>
                        <Priority>5</Priority>
                        <Operation>AutoReplenish</Operation>
                      </OPTIONS>';

  /* build the XML for generating Replenish Orders */
  select @vGenerateReplenishOrders = '<GENERATEREPLENISHORDER>'
                                       + coalesce(@vLocationsInfo, '') +
                                       + coalesce(@vOptions, '') +
                                     '</GENERATEREPLENISHORDER>';

  /* Generate the replenish orders */
  exec pr_Replenish_GenerateOrders @vGenerateReplenishOrders, @BusinessUnit, @UserId, @vConfirmMessage output,
                                   default, @vNewWaveNo output;

  /* Auto release min-max waves */
  if (@vAutoRelease = 'Y') and (@vNewWaveNo is not null)
    begin
      insert into @ttWavesToRelease (EntityKey) select @vNewWaveNo;
      exec pr_PickBatch_ReleaseBatches @ttWavesToRelease, @UserId, @BusinessUnit;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Replenish_AutoReplenish */

Go
