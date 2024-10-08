/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Picking Search Rules

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

    OrderByField - Field to sort the results by
                    Example: AllocableQty   .. will have to add OrderBy AllocableQty

    OrderByType  - Order ..whether to sort ascending or descending
                DESC ..order by the given field in Descending order
                    Applicable only when OrderByField is given
                If null, assume Ascending

------------------------------------------------------------------------------*/
Create Table PickSearchRules (
    RecordId                 TRecordId      identity (1,1) not null,

    SearchOrder              TInteger       not null,
    SearchSet                TLookUpCode    not null,

    SearchType               TLookUpCode    not null,
    PickingZone              TLookUpCode,
    LocationType             TLocationType,
    QuantityCondition        TDescription   not null,

    OrderByField             TDescription,
    OrderByType              TDescription,


    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkPickSearchRules_RecordId    PRIMARY KEY (RecordId),
    constraint ukPickSearchRules_SearchOrder UNIQUE (SearchOrder, SearchType, PickingZone, LocationType, OrderByField, OrderByType, QuantityCondition, BusinessUnit)
);

Go
