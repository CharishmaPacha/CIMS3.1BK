/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TASNLPNDetailImportType: Added InventoryClass1 to 3, and UDF Renamed as LD_UDF1 to 5 and Removed from 6-25 UDF's
  2019/12/23  TD      TASNLPNImportType,TASNLPNDetailImportType- Added HostReceiptLine(CID-1233)
  TASNLPNDetailImportType: Added RecordType,UnitsPerPackage,ReceiptId,ReceivedUnits,InputXML,ResultXML
  2017/11/28  TD/SV   Added TASNLPNImportType, TASNLPNDetailImportType, TCartonImportType,
  Create Type TASNLPNDetailImportType as Table (
  Grant References on Type:: TASNLPNDetailImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in def_DE_Interface
   This table structure mimics the record structure of ASNLPND import, with few additional fields
   to capture key fields, etc.,. */
Create Type TASNLPNDetailImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

    LPN                      TLPN,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,

    InnerPacks               TInnerPacks,
    UnitsPerPackage          TInteger,
    Quantity                 TQuantity,

    ReceiptNumber            TReceiptNumber,
    HostReceiptLine          THostReceiptLine,

    Weight                   TWeight,
    Volume                   TVolume,
    Lot                      TLot,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    CoO                      TCoO,

    LPND_UDF1                TUDF,
    LPND_UDF2                TUDF,
    LPND_UDF3                TUDF,
    LPND_UDF4                TUDF,
    LPND_UDF5                TUDF,

    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    LPNId                    TRecordId,
    LPNDetailId              TRecordId,
    SKUId                    TRecordId,
    ReceiptId                TRecordId,
    ReceiptDetailId          TRecordId,

    LPNLine                  TDetailLine,
    LPNType                  TTypeCode,
    Status                   TStatus,
    InventoryStatus          TStatus,
    OnhandStatus             TStatus,

    PrevLPNQty               TQuantity,
    PrevLPNInnerPacks        TInnerPacks,

    InputXML                 TXML,
    ResultXML                TXML,

    HostRecId                TRecordId,

    ReceiptLine              TReceiptLine, -- Not used, deprecated

    PRIMARY KEY              (RecordId),
    Unique                   (LPN, RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TASNLPNDetailImportType   to public;

Go
