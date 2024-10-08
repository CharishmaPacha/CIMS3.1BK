/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TPickBatchSummary as Table (
    Line                     TInteger,
    BatchNo                  TPickBatchNo,
    HostOrderLine            THostOrderLine,
    OrderDetailId            TRecordId,
    CustSKU                  TCustSKU,
    CustPO                   TCustPO,
    ShipToStore              TShipToStore,
    PickLocation             TLocation,

    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    UPC                      TUPC,
    Description              TDescription,

    UnitsPerCarton           TQuantity,
    UnitsPerInnerPack        TQuantity,

    UnitsOrdered             TQuantity,
    UnitsAuthorizedToShip    TQuantity,
    UnitsPreAllocated        TQuantity,
    UnitsAssigned            TQuantity,
    UnitsNeeded              TQuantity,
    /* Units Available */
    UnitsAvailable           TQuantity,     -- Total in WH
    UnitsAvailable_UPicklane TQuantity,     -- Available in Unit Picklane
    UnitsAvailable_PPicklane TQuantity,     -- Available in Package Picklane
    UnitsAvailable_Reserve   TQuantity,     -- Available in Reserve
    UnitsAvailable_Bulk      TQuantity,     -- Available in Bulk
    UnitsAvailable_RB        TQuantity,     -- Available in Reserve + Bulk
    UnitsAvailable_Other     TQuantity,     -- Available in Other Locations
    /* Units Short */
    UnitsShort_UPicklane     TQuantity,     -- Units Short in Unit Picklane
    UnitsShort_PPicklane     TQuantity,     -- Units Short in Package Picklane
    UnitsShort_Other         TQuantity,     -- Units Short from Reserve/Bulk
    UnitsShort               TQuantity,     -- Total Units Short
    /* Cases Available */
    CasesAvailable           TQuantity,     -- Total Cases in WH
    CasesAvailable_PPicklane TQuantity,     -- Cases Available in Package Picklane
    CasesAvailable_Reserve   TQuantity,     -- Cases Available in Reserve
    CasesAvailable_Bulk      TQuantity,     -- Cases Available in Bulk
    CasesAvailable_RB        TQuantity,     -- Cases Available in Reserve + Bulk
    CasesAvailable_Other     TQuantity,     -- Cases Available in Other Locations
    /* Cases Short */
    CasesShort_PPicklane     TQuantity,     -- Cases Short in Package Picklane
    CasesShort_Other         TQuantity,     -- Cases Short from Reserve/Bulk
    CasesShort               TQuantity,     -- Total Cases Short

    UnitsPicked              TQuantity,
    UnitsPacked              TQuantity,
    UnitsLabeled             TQuantity,
    UnitsShipped             TQuantity,

    CasesOrdered             TCount,
    CasesToShip              TCount,
    CasesPreAllocated        TCount,
    CasesAssigned            TCount,
    CasesNeeded              TCount,
    CasesPicked              TCount,
    CasesPacked              TCount,
    CasesLabeled             TCount,
    CasesStaged              TCount,
    CasesLoaded              TCount,
    CasesShipped             TCount,

    LPNsOrdered              TCount,
    LPNsToShip               TCount,
    LPNsAssigned             TCount,
    LPNsNeeded               TCount,
    LPNsAvailable            TCount,
    LPNsShort                TCount,
    LPNsPicked               TCount,
    LPNsPacked               TCount,
    LPNsLabeled              TCount,
    LPNsStaged               TCount,
    LPNsLoaded               TCount,
    LPNsShipped              TCount,

    PrimaryLocation          TLocation,
    SecondaryLocation        TLocation,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    UDF6                     TUDF,
    UDF7                     TUDF,
    UDF8                     TUDF,
    UDF9                     TUDF,
    UDF10                    TUDF,
    RecordId                 TRecordId      identity (1,1),

    Primary Key              (RecordId)
);

Grant References on Type:: TPickBatchSummary to public;

Go
