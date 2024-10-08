/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/16  AY      Added TReceiptDetails
  Create Type TReceiptDetails as Table (
  Grant References on Type:: TReceiptDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TReceiptDetails as Table (
    ReceiptId                TRecordId,
    ReceiptNumber            TReceiptNumber,

    ReceiptDetailId          TRecordId,
    SKU                      TSKU,
    DisplaySKU               TSKU,
    SKUDescription           TDescription,
    UoMDesc                  TUoM,
    UPC                      TUPC,
    CaseUPC                  TUPC,

    UnitsPerInnerPack        TInteger,
    InventoryUoM             TUoM,

    QtyOrdered               TQuantity,
    QtyInTransit             TQuantity,
    QtyReceived              TQuantity,
    QtyToReceive             TQuantity,
    QtyToLabel               TQuantity,
    ExtraQtyAllowed          TQuantity,
    MaxQtyAllowedToReceive   TQuantity,

    LPNsInTransit            TCount,
    LPNsReceived             TCount,

    CustPO                   TCustPO,
    ReceivingPallet          TPallet,
    ReceivingLocation        TLocation,
    ReceiverNumber           TReceiverNumber,
    WarningMsg               TMessage,
    EnableQty                TFlag,
    DefaultQty               TQuantity,
    SortOrder                TSortOrder,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    DisplayUoM as            case
                               when coalesce(UnitsPerInnerPack, 0) = 0 then 'Eaches'
                               when (QtyToLabel < coalesce(UnitsPerInnerPack, 0)) then 'Eaches'
                               when (QtyToLabel % UnitsPerInnerPack) >= 0 and charindex('CS', InventoryUoM) > 0 then 'Cases'
                               else UoMDesc
                             end,
    DisplayQtyToLabel as     case
                               when coalesce(UnitsPerInnerPack, 0) = 0 then
                                 cast(QtyToLabel as varchar) + ' EA'
                               when (QtyToLabel < coalesce(UnitsPerInnerPack, 0)) then
                                 cast(QtyToLabel as varchar) + ' EA'
                               when (QtyToLabel % UnitsPerInnerPack) = 0 and charindex('CS', InventoryUoM) > 0  then
                                 cast(QtyToLabel/UnitsPerInnerPack as varchar(max)) + ' CS'
                               when charindex('CS', InventoryUoM) = 0 then
                                 cast(QtyToLabel as varchar) + ' EA'
                               else
                                 cast(QtyToLabel/UnitsPerInnerPack as varchar(max)) + ' CS ' +
                                 cast(QtyToLabel % UnitsPerInnerPack as varchar(max)) + ' EA'
                             end
);

Grant References on Type:: TReceiptDetails to public;

Go
