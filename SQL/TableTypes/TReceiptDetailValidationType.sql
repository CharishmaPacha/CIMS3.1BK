/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/23  VM      TReceiptDetailValidationType: Added ReceiptStatus (HPI-2349)
  2018/04/25  TK      TReceiptDetailValidationType: Added QtyInTransit (HPI-1886)
  2016/09/01  KL      Added ReceiptType in TReceiptDetailValidationType  and TReceiptDetailImportType (HPI-512)
  2016/07/04  TK      TReceiptDetailValidationType: Added Key Data (HPI-231)
  2015/12/03  OK      TReceiptDetailValidationType: Added the Ownership fields(NBD-58)
  2015/08/17  NY      Added SKU for TReceiptDetailValidationType
  2014/12/02  SK      Added TReceiptDetailImportType, TReceiptDetailValidationType
  Create Type TReceiptDetailValidationType as Table (
  Grant References on Type:: TReceiptDetailValidationType to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TReceiptDetailValidationType as Table (
    RecordId                 TRecordId,

    ReceiptDetailId          TRecordId,
    RecordAction             TAction,
    KeyData                  TReference,
    ReceiptId                TRecordId,
    ReceiptNumber            TReceiptNumber,
    ReceiptType              TReceiptType,
    ReceiptStatus            TStatus,
    SKUId                    TRecordId,
    SKU                      TSKU,
    SKUStatus                TStatus,
    QtyInTransit             TQuantity,
    QtyReceived              TQuantity,
    HostReceiptLine          THostReceiptLine,
    HeaderOwnership          TOwnership,
    DetailOwnership          TOwnership,
    BusinessUnit             TBusinessUnit,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,
    InputXML                 TXML,
    ResultXML                TXML,

    AllowInactiveSKUs        TFlag,
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

    --Primary Key            (RecordId)

    HostRecId                TRecordId,

    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TReceiptDetailValidationType to public;

Go
