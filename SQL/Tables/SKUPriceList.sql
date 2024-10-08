/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/15  MS      SKUPriceList: Added table (CID-1118)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: SKUPriceList - Table to maitain the price list for SKUs based upon SoldToId
   to be used for Price Stickers
------------------------------------------------------------------------------*/
Create Table SKUPriceList (
    RecordId                 TRecordId      identity (1,1) not null,

    SKUId                    TRecordId,
    SKU                      TSKU,
    SoldToId                 TCustomerId,
    CustSKU                  TCustSKU,

    RetailUnitPrice          TPrice,
    UnitSalePrice            TPrice,
    Price1                   TPrice,
    Price2                   TPrice,
    Price3                   TPrice,

    Status                   TStatus default 'A',

    DisplaySKU               TSKU,
    DisplaySKU1              TSKU,
    DisplaySKU2              TSKU,
    DisplaySKU3              TSKU,

    UniqueId as              (SKU + '-' + coalesce(SoldToId, '') + '-' + coalesce(CustSKU, '')),

    BusinessUnit             TBusinessUnit,
    CreatedBy                TUserId,
    CreatedDate              TDateTime default current_timestamp,
    ModifiedBy               TUserId,
    ModifiedDate             TDateTime

    constraint pkSKUPriceList_SKUId PRIMARY KEY (RecordId),
    constraint ukSKUPriceList_SKU UNIQUE (UniqueId, BusinessUnit)
);

create index ix_SKUPriceList_SKUIdSoldToId       on SKUPriceList (SKUId, SoldToId, Status) Include (CustSKU);
create index ix_SKUPriceList_UniqueId            on SKUPriceList (UniqueId) Include (CustSKU, Status);

Go
