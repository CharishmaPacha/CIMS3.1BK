/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/20  YJ      TASNLPNImportType: Added InventoryClass1 to InventoryClass3
  2019/12/23  TD      TASNLPNImportType,TASNLPNDetailImportType- Added HostReceiptLine(CID-1233)
  2019/02/22  RIA     TASNLPNImportType, TASNLPNHeaderImportType: Changed LPNId type (CID-87)
  2019/02/05  TD      TASNLPNImportType,TReceiptHeaderImportType:Added HostNumLines(CID-44)
  2019/02/04  TD      TASNLPNHeaderImportType,TASNLPNImportType  (CID-66)
  2019/02/02  AY      Earlier TASNLPNImportType renamed to TASNLPNHeaderImportType
  Introduced TASNLPNImportType which is combination of Hdr + Dtl (HPI-2360)
  2019/01/25  HB      TASNLPNImportType: Added RecordType,ActualWeight,InnerPacks,Quantity,PalletId,ReceiptId
  2017/11/28  TD/SV   Added TASNLPNImportType, TASNLPNDetailImportType, TCartonImportType,
  Create Type TASNLPNImportType as Table (
  Grant References on Type:: TASNLPNImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in def_DE_Interface
   This table structure mimics the record structure of ASNLPND import, with few additional fields
   to capture key fields, etc.,. */
Create Type TASNLPNImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,
    /* LPN Info */
    LPN                      TLPN,
    LPNType                  TTypeCode,
    LPNWeight                TFloat,
    Pallet                   TPallet,
    Ownership                TOwnership,
    ASNCase                  TASNCase,
    HostNumLines             TCount,

    ReceivedDate             TDateTime,
    ExpiryDate               TDateTime,
    DestWarehouse            TWarehouse,
    Location                 TLocation,

    Status                   TStatus,
    InventoryStatus          TStatus,
    OnhandStatus             TStatus,

    /* LPNDetail info */
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,

    InnerPacks               TInnerPacks,
    UnitsPerPackage          TInteger,
    Quantity                 TQuantity,

    PrevLPNQty               TQuantity,
    PrevLPNInnerPacks        TInnerPacks,

    ReceivedUnits            TInteger,
    Weight                   TWeight,
    Volume                   TVolume,
    Lot                      TLot,
    InventoryClass1          TInventoryClass,
    InventoryClass2          TInventoryClass,
    InventoryClass3          TInventoryClass,
    CoO                      TCoO,

    /* Receipt Info */
    ReceiptNumber            TReceiptNumber,
    HostReceiptLine          THostReceiptLine,

    /* UDFs */
    LPN_UDF1                 TUDF,
    LPN_UDF2                 TUDF,
    LPN_UDF3                 TUDF,
    LPN_UDF4                 TUDF,
    LPN_UDF5                 TUDF,
    LPN_UDF6                 TUDF,
    LPN_UDF7                 TUDF,
    LPN_UDF8                 TUDF,
    LPN_UDF9                 TUDF,
    LPN_UDF10                TUDF,

    LPND_UDF1                TUDF,
    LPND_UDF2                TUDF,
    LPND_UDF3                TUDF,
    LPND_UDF4                TUDF,
    LPND_UDF5                TUDF,

    SourceSystem             TName          DEFAULT 'HOST',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    LPNId                    TRecordId,
    PalletId                 TRecordId,
    LPNDetailId              TRecordId,
    SKUId                    TRecordId,
    ReceiptId                TRecordId,
    ReceiptDetailId          TRecordId,

    LPNLine                  TDetailLine,

    InputXML                 TXML,
    ResultXML                TXML,

    HostRecId                TRecordId,

    PRIMARY KEY              (RecordId),
    Unique                   (LPN, RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TASNLPNImportType   to public;

Go
