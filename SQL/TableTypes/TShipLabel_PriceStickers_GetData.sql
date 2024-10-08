/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/12/09  AY      TShipLabel_PriceStickers_GetData: DataSet that is returned by price stickers procedure (CID-933)
  Create Type TShipLabel_PriceStickers_GetData as Table (
  Grant References on Type:: TShipLabel_PriceStickers_GetData to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TShipLabel_PriceStickers_GetData as Table (
    LPN                      TLPN,
    WaveNo                   TWaveNo,
    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    SoldToId                 TCustomerId,
    Account                  TAccount,
    ShipToStore              TShipToStore,

    SKUId                    TRecordId,
    SKU                      TSKU,
    SKU1                     TSKU,
    SKU2                     TSKU,
    SKU3                     TSKU,
    SKU4                     TSKU,
    SKU5                     TSKU,
    SKUDescription           TDescription,
    SKU1Description          TDescription,
    SKU2Description          TDescription,
    SKU3Description          TDescription,
    SKU4Description          TDescription,
    SKU5Description          TDescription,
    UPC                      TUPC,

    RetailUnitPrice          TPrice,
    UnitSalePrice            TPrice,
    Price1                   TPrice,
    Price2                   TPrice,
    Price3                   TPrice,

    OH_UDF1                  TUDF,
    OH_UDF2                  TUDF,
    OH_UDF3                  TUDF,
    OH_UDF4                  TUDF,
    OH_UDF5                  TUDF,
    OH_UDF6                  TUDF,
    OH_UDF7                  TUDF,
    OH_UDF8                  TUDF,
    OH_UDF9                  TUDF,
    OH_UDF10                 TUDF,

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

    QtyToPrint               TInteger
);

Grant References on Type:: TShipLabel_PriceStickers_GetData to public;

Go
