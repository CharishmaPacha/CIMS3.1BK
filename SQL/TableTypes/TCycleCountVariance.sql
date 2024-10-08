/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/11  OK      TCycleCountVariance: Added LocationId and UniqueId (HA-2248)
  2021/03/10  AY      TCycleCountVariance: Added more fields (HA-2247)
  2020/09/02  SK      TCycleCountVariance: Added Warehouse, BusinessUnit fields (CIMSV3-1066)
  2020/09/01  AY      TCycleCountVariance: Added (CIMSV3-1026)
  Create Type TCycleCountVariance as Table (
  Grant References on Type:: TCycleCountVariance to public;
------------------------------------------------------------------------------*/

Go

/*******************************************************************************
   !!!! WARNING !!!WARNING !!!WARNING !!!
   Changes to Any Table Type in this table should be communicated to respective touch points

   All pr_[]_DS_* Procedure using the Table Type should be verified for correctness of functionality
   The changes needed to these procedures and underlying procedures should be done

   Init_DBObjects.sql should be rerun against the target DB, to ensure the changes to these
   definitions are properly communicated to external applications like V3 UI Framework
*******************************************************************************/

/*----------------------------------------------------------------------------*/
Create Type TCycleCountVariance as Table (
    RecordId                 TRecordId PRIMARY KEY,

    BatchNo                  TTaskBatchNo,
    TaskId                   TRecordId,
    TaskDetailId             TRecordId,
    TaskSubType              TTypeCode,
    TaskSubTypeDesc          TDescription,
    TaskDesc                 TDescription, -- Row or Row-Level etc.
    TransactionDate          TDate,
    TransactionTime          TDateTime,

    PutawayClass             TCategory,

    LocationId               TRecordId,
    Location                 TLocation,
    LocationType             TTypeCode,
    LocationTypeDesc         TDescription,
    StorageTypeDesc          TDescription,
    PutawayZone              TZoneId,
    PickZone                 TZoneId,
    -- Units
    PreviousUnits            TCount,
    NewUnits                 TCount,
    AbsUnitsChange           TCount,
    PercentUnitsChange       TFloat,
    UnitsAccuracy            TFloat,
    AbsPercentUnitsChange    TFloat,
    -- LPNs
    PrevLPNS                 TCount,
    NumLPNs                  TCount,
    -- SKUs
    PreviousNumSKUs          TCount,
    NewNumSKUs               TCount,
    PercentSKUsChange        TFloat,
    SKUsAccuracy             TFloat,
    -- Value
    OldValue                 TCount,
    NewValue                 TCount,
    -- IPs
    PrevInnerPacks           TCount,
    NewInnerPacks            TCount,
    InnerPacksChange         TCount,
    PercentIPChange          TFloat,
    IPAccuracy               TFloat,
    -- Computed Columns
    CountVariance            as (case when NewUnits   <> PreviousUnits   then 'Y' else 'N' end),
    SKUVariance              as (case when NewNumSKUs <> PreviousNumSKUs then 'Y' else 'N' end),
    LPNChange                as (NumLPNs    - PrevLPNs),
    UnitsChange              as (NewUnits   - PreviousUnits),
    SKUsChange               as (NewNumSKUs - PreviousNumSKUs),
    ValueChange              as (NewValue   - OldValue),
    -- Generic Counts
    Count1                   TCount,
    Count2                   TCount,
    Count3                   TCount,
    Count4                   TCount,
    Count5                   TCount,
    -- UDFs for future use
    CCV_UDF1                 TUDF,
    CCV_UDF2                 TUDF,
    CCV_UDF3                 TUDF,
    CCV_UDF4                 TUDF,
    CCV_UDF5                 TUDF,
    -- UDFs from view
    vwCCR_UDF1               TUDF,
    vwCCR_UDF2               TUDF,
    vwCCR_UDF3               TUDF,
    vwCCR_UDF4               TUDF,
    vwCCR_UDF5               TUDF,

    BusinessUnit             TBusinessUnit,
    Ownership                TOwnership,
    Warehouse                TWarehouse,
    UniqueId                 as cast(LocationId as varchar(10)) + '-' + cast(RecordId as varchar(10))

    --     LocationId               TRecordId,
    --
    -- Location                 TLocation,
    --     LocationType             TTypeCode,
    --     LocationTypeDesc         TDescription,
    --     LocationSubType          TTypeCode,
    --     LocationSubTypeDesc      TDescription,
    --     StorageType              TTypeCode,
    --     LocationRow              TRow,
    --     LocationLevel            TLevel,
    --     LocationSection          TSection,
    --     PutawayZone              TLookUpCode,
    --     PickZone                 TLookUpCode,
    --     PutawayZoneDesc          TDescription,
    --     PickZoneDesc             TDescription,
    --
    --     SKUId                    TRecordId,
    --     SKU                      TSKU,
    --     SKU1                     TSKU,
    --     SKU2                     TSKU,
    --     SKU3                     TSKU,
    --     SKU4                     TSKU,
    --     SKU5                     TSKU,
    --     SKU1Desc                 TDescription,
    --     SKU2Desc                 TDescription,
    --     SKU3Desc                 TDescription,
    --     SKU4Desc                 TDescription,
    --     SKU5Desc                 TDescription,
    --
    --     NumSKUs                  TCount,
    --     NumLPNs                  TCount,
    --     InnerPacks               TQuantity,
    --     Quantity                 TQuantity,
    --     LocationABCClass         TFlag,
    --     LastCycleCounted         TDateTime,
    --     PolicyCompliant          TFlag,
    --     DaysAfterLastCycleCount  TCount,
    --
    --     HasActiveTask            as case when TaskId > 0 then 'Y' else 'N' end,
    --     TaskId                   TRecordId,
    --     BatchNo                  TTaskBatchNo,
    --     ScheduledDate            TDateTime,
    --
    --     CC_LocUDF1               TUDF,
    --     CC_LocUDF2               TUDF,
    --     CC_LocUDF3               TUDF,
    --     CC_LocUDF4               TUDF,
    --     CC_LocUDF5               TUDF,
    --     CC_LocUDF6               TUDF,
    --     CC_LocUDF7               TUDF,
    --     CC_LocUDF8               TUDF,
    --     CC_LocUDF9               TUDF,
    --     CC_LocUDF10              TUDF,
    --
    --     BusinessUnit             TBusinessUnit,
    --
    --     UniqueId                 as cast(LocationId as varchar(10)) + '-' + cast(SKUId as varchar(10)),
    --
    --     Unique                   (Location, RecordId),
    --     Unique                   (LocationId, SKUId, RecordId),
    --     Unique                   (SKUId, RecordId)
);

Grant References on Type:: TCycleCountVariance to public;

Go
