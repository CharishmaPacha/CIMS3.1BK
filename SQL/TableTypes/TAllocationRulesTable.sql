/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/08/07  TK      TAllocationRulesTable & TAllocableLPNsTable: Added ReplenishClass (HPI-1625)
  2014/04/06  TD      Added TOrderDetailsToAllocateTable, TAllocationRulesTable,
  Create Type TAllocationRulesTable as Table
  Grant References on Type:: TAllocationRulesTable to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TAllocationRulesTable as Table
  (
    RuleId                   TRecordId,

    SearchOrder              TInteger,
    SearchSet                TLookUpCode,

    SearchType               TLookUpCode,

    WaveType                 TTypeCode,

    SKUABCClass              TFlag,
    ReplenishClass           TCategory,

    RuleGroup                TDescription,

    LocationType             TLocationType,
    LocationSubType          TLocationSubType,
    StorageType              TTypeCode,

    OrderType                TTypeCode,

    PickingClass             TCategory,
    PickingZone              TLookUpCode,
    PutawayClass             TPutawayClass,

    QuantityCondition        TDescription,

    OrderByField             TDescription,
    OrderByType              TDescription,

    Status                   TFlag,

    AR_UDF1                  TUDF,
    AR_UDF2                  TUDF,
    AR_UDF3                  TUDF,
    AR_UDF4                  TUDF,
    AR_UDF5                  TUDF,

    RecordId                 TRecordId      identity (1,1),
    Primary Key              (RecordId)
);

Grant References on Type:: TAllocationRulesTable to public;

Go
