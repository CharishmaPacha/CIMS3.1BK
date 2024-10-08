/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/24  RIA     TDataTableSKUDetails: Added LPNDetailId, OrderDetailId, ReceiptDetailId (CIMSV3-1236)
  2020/10/22  RIA     TDataTableSKUDetails: Added DisplayUDFs1-5 (JL-271)
  2020/09/30  RIA     TDataTableSKUDetails: Added SKUImageURL (CIMSV3-1110)
  2020/09/01  RIA     TDataTableSKUDetails: Added MinQty, MaxQty, CurrentUoM (OB2-1199)
  2020/08/31  RIA     TDataTableSKUDetails: Added LPN, Pallet, NumLPNs, NumPallets, UDFs1-5 (HA-527)
  2020/05/13  AY      Add InventoryClasses to TDataTableSKUDetails (HA-???)
  2020/04/29  RIA     Added TDataTableSKUDetails (CIMSV3-756)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* TDataTableSKUDetails: This mimics the datatable to be shown on the RF for
   many functions with the relevant info in that context. Eg: This will be the
   list of SKUs to receive in Receiving, List of items in the LPN when adjusting
   an LPN or list of SKUs needed for the Wave in LPN Reservation.

   DisplaySKU/DisplaySKUDesc: On how SKU and it's description should be shown
                              to user on RF

   Quantity* Fields: in AMF the fields are displayed only in the sequence given
   from SQL. And in different functions we have different quantities to display
   and we are therefore using generic field names to map to the needed values
   in SQL with the appropriate captions defined in HTML


   Note: Please be diligent while adding new fields to the data table as the mismatch
         in sequence leads to issues in V3 RF */
Create Type TDataTableSKUDetails as Table (
    DisplaySKU               TSKU,
    DisplaySKUDesc           TDescription,

    InnerPacks               TQuantity      DEFAULT 0,
    Quantity                 TQuantity      DEFAULT 0,
    Quantity1                TQuantity      DEFAULT 0,
    Quantity2                TQuantity      DEFAULT 0,
    DisplayQuantity          TDescription,
    /* SKU references */
    SKU                      TSKU,
    UPC                      TUPC,
    AlternateSKU             TSKU,
    Barcode                  TBarcode,
    /* Pack config info */
    InnerPacksPerLPN         TInteger,
    UnitsPerInnerPack        TInteger,
    UnitsPerLPN              TInteger,
    AllowNonStdInnerPacks    TFlags,        -- do not allow change of UnitsPerInnerPack if No
    /* UoM info */
    UoM                      TUoM,
    InventoryUoM             TUoM,
    IPUoMDescSL              TUoM,          -- Inner Packs in singular ex. case, box, pack of 12
    IPUoMDescPL              TUoM,          -- Inner Packs in plural ex. cases, boxes, packs of 12
    EAUoMDescSL              TUoM,          -- Eaches in singular ex. unit, pair, piece
    EAUoMDescPL              TUoM,          -- Eaches in plural ex. units, pairs, pieces

    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    Lot                      TLot,

    AvailableQty             TQuantity      DEFAULT 0, -- future use
    ReservedQty              TQuantity      DEFAULT 0, -- future use
    QtyOrdered               TQuantity      DEFAULT 0,
    QtyReceived              TQuantity      DEFAULT 0,

    Warehouse                TWarehouse,
    Ownership                TOwnership,
    BusinessUnit             TBusinessUnit,
    SKUId                    TRecordId,
    SortOrder                TSortOrder,

    MinQty                   TQuantity      DEFAULT 0,
    MaxQty                   TQuantity      DEFAULT 0,
    LPN                      TLPN,
    Pallet                   TPallet,
    NumLPNs                  TCount,
    NumPallets               TCount,
    CurrentUoM               TUoM,          -- the current UoM for particular record. Will be used to default
    SKUImageURL              TURL,

    DisplayUDF1              TUDF,          -- use these to show some additional information
    DisplayUDF2              TUDF,
    DisplayUDF3              TUDF,
    DisplayUDF4              TUDF,
    DisplayUDF5              TUDF,

    LPNId                    TRecordId,
    PalletId                 TRecordId,
    LocationId               TRecordId,
    LPNDetailId              TRecordId,
    OrderDetailId            TRecordId,
    ReceiptDetailId          TRecordId,

    UDF1                     TUDF,          -- future use
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF
);

Grant References on Type:: TDataTableSKUDetails to public;

Go
