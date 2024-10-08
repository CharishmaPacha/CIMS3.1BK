/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TOrderDetailsImportType: Added not null constraints for Primary Columns (HA-483)
  TOnhandInventoryExportType, TOrderDetailsImportType, TExportsType: Added InventoryClass1 to InventoryClass3
  2020/03/19  YJ      TOrderDetailsImportType: Removed OrderLine and changed UDF1 to 10 as OD_UDF1 to 10 and also added OD_UDF11 to 30
  2019/02/26  PK      TOrderDetailsImportType: Added ParentLineId, ParentHostLineNo.
  2015/10/16  AY      TOrderDetailsImportType: Added OHStatus, Ownership
  2014/05/14  NB      Added TOrderDetailsImportType, TImportValidationType
  Create Type TOrderDetailsImportType as Table (
  Grant References on Type:: TOrderDetailsImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in Order Details Import
   This table structure mimics the record structure of Order Detail import, with few additional fields
   to capture key fields, etc.,. */
Create Type TOrderDetailsImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

    PickTicket               TPickTicket    not null,
    HostOrderLine            THostOrderLine not null,
    ParentHostLineNo         THostOrderLine,
    LineType                 TTypeCode,

    SKU                      TSKU           not null,
    UnitsOrdered             TQuantity      DEFAULT 0,
    UnitsAuthorizedToShip    TQuantity      DEFAULT 0,

    UnitsPerCarton           TInteger,
    UnitsPerInnerPack        TInteger,
    RetailUnitPrice          TRetailUnitPrice  DEFAULT 0.0,
    UnitSalePrice            TUnitPrice     DEFAULT 0.0,
    UnitTaxAmount            TMonetaryValue DEFAULT 0.0,

    Lot                      TLot,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    CustSKU                  TCustSKU,
    PackingGroup             TCategory,

    OD_UDF1                  TUDF,
    OD_UDF2                  TUDF,
    OD_UDF3                  TUDF,
    OD_UDF4                  TUDF,
    OD_UDF5                  TUDF,
    OD_UDF6                  TUDF,
    OD_UDF7                  TUDF,
    OD_UDF8                  TUDF,
    OD_UDF9                  TUDF,
    OD_UDF10                 TUDF,
    OD_UDF11                 TUDF,
    OD_UDF12                 TUDF,
    OD_UDF13                 TUDF,
    OD_UDF14                 TUDF,
    OD_UDF15                 TUDF,
    OD_UDF16                 TUDF,
    OD_UDF17                 TUDF,
    OD_UDF18                 TUDF,
    OD_UDF19                 TUDF,
    OD_UDF20                 TUDF,
    OD_UDF21                 TUDF,
    OD_UDF22                 TUDF,
    OD_UDF23                 TUDF,
    OD_UDF24                 TUDF,
    OD_UDF25                 TUDF,
    OD_UDF26                 TUDF,
    OD_UDF27                 TUDF,
    OD_UDF28                 TUDF,
    OD_UDF29                 TUDF,
    OD_UDF30                 TUDF,

    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      DEFAULT current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    OrderId                  TRecordId ,
    OHStatus                 TStatus,
    Ownership                TOwnership,

    OrderDetailId            TRecordId,
    ParentLineId             TRecordId,
    SKUId                    TRecordId,
    OrigUnitsAuthorizedToShip
                             TQuantity      DEFAULT 0,
    UnitsAssigned            TQuantity      DEFAULT 0,
    UnitsShipped             TQuantity      DEFAULT 0,

    LocationId               TRecordId,
    Location                 TLocation,
    PickZone                 TZoneId,

    DestZone                 TZoneId,
    DestLocation             TLocation,

    PickBatchGroup           TWaveGroup,
    PickBatchCategory        TCategory,

    InputXML                 TXML,
    ResultXML                TXML,

    HostRecId                TRecordId,

    PRIMARY KEY              (RecordId),
    Unique                   (OrderId, OrderDetailId, RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TOrderDetailsImportType   to public;

Go
