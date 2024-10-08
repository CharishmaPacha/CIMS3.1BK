/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/06  AY      Added AllocationRules.TLocationSubType (HPI-2119)
  2017/08/07  TK      AllocationRules: Added ReplenishClass & UDFs (HPI-1625)
  Added new table AllocationRules.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: AllocationRules

    SearchOrder - Sorting of the PickSearchRules
    SearchType  - Dynamic (Other types could be introduced Later)
    PickingZone - Zones to Restrict to
                   If null, Input Picking Zone is considered or Ignored altogether
    LocationType - Type of Location to Restrict to
                   If null, Input LocationType is considered or Ignored altogether
    QuantityCondition
                - What condition to use to search for Pallets or PickLanes on AvailableQuantity
                    and AllocableQty
                - Conditions are
                    EQ      for equals to
                        (AvailableQty = QtyToAllocate)
                    GT      for greater than
                        (AvailableQty > QtyToAllocate)
                    GTEQ    for greater than or equal to
                        (AvailableQty >= QtyToAllocate)
                    LT      for less than
                        (AvailableQty < QtyToAllocate)
                    LTEQ    for less than or equal to
                        (AvailableQty <= QtyToAllocate)
                    LTE1IP   for less than or equal to an Inner Pack
                        (AvailableIP = 1) and (AvailableQty <= UnitsPerInnerPack)
                    LT1IP   for less than an Inner Pack
                        (AvailableIP = 1) and (AvailableQty < UnitsPerInnerPack)

    OrderByField - Field to sort the results by
                    Example: AllocableQty   .. will have to add OrderBy AllocableQty

    OrderByType  - Order ..whether to sort ascending or descending
                DESC ..order by the given field in Descending order
                    Applicable only when OrderByField is given
                If null, assume Ascending

------------------------------------------------------------------------------*/
Create Table AllocationRules (
    RecordId                 TRecordId      identity (1,1) not null,

    SearchOrder              TInteger       not null,
    SearchSet                TLookUpCode    not null,

    SearchType               TLookUpCode,

    WaveType                 TTypeCode,

    RuleGroup                TDescription,

    LocationType             TLocationType,
    LocationSubType          TLocationSubType,
    StorageType              TTypeCode,
    OrderType                TTypeCode,

    SKUABCClass              TFlag,
    PickingClass             TCategory,
    PickingZone              TLookUpCode,
    PutawayClass             TPutawayClass,    --LPN's PAClass
    ReplenishClass           TCategory,

    QuantityCondition        TDescription,

    OrderByField             TDescription,
    OrderByType              TDescription,

    Status                   TFlag         default 'A', /* Active */

    ConsiderRuleGroup        TFlag,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Warehouse                TWarehouse,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkAllocationRules_RecordId PRIMARY KEY (RecordId)
);

/* Used by fn_Allocation_GetAllocationRules */
create index ix_AllocationRules_WaveType         on AllocationRules(WaveType, Warehouse, SearchSet, Status, BusinessUnit) Include (SearchType);

Go
