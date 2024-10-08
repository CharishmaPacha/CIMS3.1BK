/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/02/10  TK      TSoftAllocationDetails: Added columns PrevUnitsPreAllocated, ReasonToDisQualify, OrderAllocationPercent & RuleId (HPI-1365)
  2016/05/27  TK      TSoftAllocationDetails: Added column QualifiedStatus & fields for Logging (HPI-31)
  2016/04/01  AY/TK   TSoftAllocationDetails: Added
  Create Type TSoftAllocationDetails as Table (
  Grant References on Type:: TSoftAllocationDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TSoftAllocationDetails as Table (
    OrderId                  TRecordId,
    OrderDetailId            TRecordId,
    SKUId                    TRecordId,
    SKU                      TSKU,

    UnitsToShip              TQuantity      Default 0,
    UnitsAssigned            TQuantity      Default 0,
    UnitsToAllocate          TQuantity      Default 0,
    UnitsPreAllocated        TQuantity      Default 0,
    UnitsToReduce            TQuantity      Default 0,
    PrevUnitsPreAllocated    TQuantity      Default 0,

    AllocatedStatus          as case when (UnitsToAllocate > 0) and (UnitsToAllocate = UnitsPreAllocated) then 'F'/* Fully Allocated */
                                     when (UnitsPreAllocated > 0) and (UnitsPreAllocated < UnitsToAllocate) then 'P' /* Partially Allocated */
                                  else 'N'  /* Not Allocated */
                                end,

    QualifiedStatus          TStatus        Default 'N',
    ReasonToDisQualify       TDescription,

    --TotalAvailableQty      TQuantity      Default 0,      -- what is this?

    SortOrder                TDescription,

    /* Additional Info */
    PickTicket               TPickTicket,
    OrderType                TTypeCode,
    OrderStatus              TStatus,
    NumLines                 TCount,
    OrderCategory1           TCategory,
    OrderCategory2           TCategory,
    OrderCategory3           TCategory,
    OrderCategory4           TCategory,
    OrderCategory5           TCategory,
    ShipComplete             TFlag,
    ShipCompletePercent      TPercent,
    OrderAllocationPercent   TPercent       Default 0,

    Warehouse                TWarehouse,
    Ownership                TOwnership,
    LotNo                    TLot,
    ShipPack                 TInteger,

    /* For Logging */
    SABatchNo                TInteger,
    Operation                TOperation,
    CreatedDate              TDateTime      DEFAULT current_timestamp,

    Iteration                TCount,
    KeyValue                 TDescription,

    LineType                 TTypeCode,     -- KC: Kit Component line
    HostOrderLine            THostOrderLine,
    ParentOrderLine          THostOrderLine,
    KitsToShip               TInteger,
    ComponentRatio           TInteger,      /* If kit component line, then how many should we have in each kit */

    RuleId                   TRecordId,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId,

    Unique                   (KeyValue, RecordId),
    Unique                   (OrderId, KeyValue, SKUId, UnitsPreallocated, RecordId),
    Unique                   (SKUId, Ownership, Warehouse, RecordId),
    Unique                   (QualifiedStatus, SKUId, AllocatedStatus, RecordId),
    Primary Key              (RecordId)
);

Grant References on Type:: TSoftAllocationDetails to public;

Go
