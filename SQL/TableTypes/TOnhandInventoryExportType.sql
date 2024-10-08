/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TOnhandInventoryExportType, TOrderDetailsImportType, TExportsType: Added InventoryClass1 to InventoryClass3
  2019/06/28  VS      TOnhandInventoryExportType: To Show UPC in Onhandinventory Export (CID-659)
  2018/03/29  SV      TOnhandInventoryExportType: Added SourceSystem (HPI-1845)
  2018/03/16  SV      TOnhandInventoryExportType: Added Warehouse field (S2G-437)
  2018/01/31  SV      TInventoryExportType: Corrected to TOnhandInventoryExportType, added other required fields (S2G-188)
  Create Type TOnhandInventoryExportType as Table (
  Grant References on Type:: TOnhandInventoryExportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in def_DE_Interface
   This table structure mimics the record structure of Inventory Export, with few additional fields
   to capture key fields, etc.,. */
Create Type TOnhandInventoryExportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    UPC                      TUPC,

    AvailableQty             TQuantity,
    ReservedQty              TQuantity,
    OnhandQty                TQuantity,
    ReceivedQty              TQuantity,

    Ownership                TOwnership,
    Warehouse                TWarehouse,
    LPN                      TLPN,
    Location                 TLocation,
    Lot                      TLot,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    LPNType                  TTypeCode,
    TransDateTime            TDateTime,

    SourceSystem             TName,
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      DEFAULT current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    LPNTypeDescription       TDescription,

    PRIMARY KEY              (RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TOnhandInventoryExportType   to public;

Go
