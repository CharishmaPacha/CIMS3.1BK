/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/19  RKC     TImportInvAdjustments: Initial revision (HA-2341)
  Create Type TImportInvAdjustments as Table (
  Grant References on Type:: TImportInvAdjustments   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TImportInvAdjustments as Table (
    RecordId                      TRecordId      identity (1,1) not null,

    RecordType                    TRecordType not null DEFAULT 'LOCADJ',
    Warehouse                     TWarehouse  not null,
    Location                      TLocation   not null,
    LPN                           TLPN,
    SKU                           TSKU        not null,
    SKU1                          TSKU,
    SKU2                          TSKU,
    SKU3                          TSKU,
    SKU4                          TSKU,
    SKU5                          TSKU,
    InventoryClass1               TInventoryClass,
    InventoryClass2               TInventoryClass,
    InventoryClass3               TInventoryClass,

    UpdateOption                  TFlag       not null,
    InnerPacks                    TInnerPacks,
    Quantity                      TQuantity   not null,

    ReceiptNumber                 TReceiptNumber,
    ReasonCode                    TReasonCode not null,

    TransactionDateTime           TDateTime,
    Reference                     TVarchar    not null,
    Ownership                     TOwnership  not null,
    SortSeq                       TSortSeq    not null,

    UDF1                          TUDF,
    UDF2                          TUDF,
    UDF3                          TUDF,
    UDF4                          TUDF,
    UDF5                          TUDF,
    UDF6                          TUDF,
    UDF7                          TUDF,
    UDF8                          TUDF,
    UDF9                          TUDF,
    UDF10                         TUDF,

    Archived                      TFlag,
    BusinessUnit                  TBusinessUnit not null,
    /* Interface related fields */
    Result                        TVarchar,
    CIMSRecId                     TRecordId
);

Grant References on Type:: TImportInvAdjustments   to public;

Go
