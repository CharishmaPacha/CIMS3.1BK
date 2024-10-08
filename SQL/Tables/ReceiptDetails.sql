/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/20  AY      ix_ReceiptDetails_ReceiptId: Revised to add SKUId (HA Support)
  2020/11/05  MS      ReceiptHeaders,ReceiptDetails: Added newfields of sorting (JL-294)
  2020/04/09  MS      ReceiptDetails: Removed not null for ReceiptLine column (HA-126)
  2020/04/01  TK      ReceiptDetails: InventoryClass defaulted to empty string (HA-84)
  2020/03/29  AY      ReceiptDetails: Added Lot & InventoryClasses (HA-77)
  2019/03/12  PHK     ReceiptDetails: Removed unique key violations on ReceiptLine field (HPI-2449)
  2018/06/13  AY      Added ReceiptDetails.QtyToLabel (S2G-879)
  2016/01/10  DK      ReceiptDetails: Added ReasonCode (FB-596)
  2014/11/01  NY      ReceiptHeaders, ReceiptDetails: Added QtyToReceive
  2013/03/13  PK      ReceiptDetails: Added UDF6 - UDF10.
  2013/03/05  YA      ReceiptDetails: Added new field ExtraQtyAllowed.
  2013/03/04  PK      ReceiptDetails: Added CustPO
  2011/07/09  PK      ReceiptDetails : Added HostReceiptLine.
  2011/01/14  VK      Added VendorId and VendorSKU to ReceiptDetails
  2010/10/26  VM      ReceiptDetails: CoE => CoO
  2010/10/22  VM      ReceiptDetails: Added Foreign key with On Delete Cascade
  2010/10/21  VM      ukReceiptDetails_ReceiptNumberLine => ukReceiptDetails_ReceiptIdLine
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: ReceiptDetails
------------------------------------------------------------------------------*/
Create Table ReceiptDetails (
    ReceiptDetailId          TRecordId      identity (1,1) not null,

    ReceiptId                TRecordId      not null,
    ReceiptLine              TReceiptLine,
    SKUId                    TRecordId      not null,
    VendorId                 TVendorId,
    VendorSKU                TVendorSKU,
    CoO                      TCoO,

    QtyOrdered               TQuantity      not null default 0,
    QtyInTransit             TQuantity      not null default 0,
    QtyReceived              TQuantity      not null default 0,
    LPNsInTransit            TCount         not null default 0,
    LPNsReceived             TCount         not null default 0,
    ExtraQtyAllowed          TQuantity      not null default 0,
    QtyToReceive             As case when ((QtyOrdered - QtyReceived) < 0) then
                                       0
                                     else
                                       (QtyOrdered - QtyReceived)
                                     end,
    QtyToLabel               As case when ((QtyOrdered - QtyReceived - QtyInTransit) < 0) then
                                       0
                                     else
                                       (QtyOrdered - QtyReceived - QtyInTransit)
                                     end,

    UnitCost                 TCost          not null default 0.0,

    CustPO                   TCustPO,
    HostReceiptLine          THostReceiptLine,
    Ownership                TOwnership,

    Lot                      TLot,
    InventoryClass1          TInventoryClass      default '',
    InventoryClass2          TInventoryClass      default '',
    InventoryClass3          TInventoryClass      default '',

    ReasonCode               TReasonCode, /* Used while creating return Receipts */

    SortLanes                TDescription,
    SortOptions              TVarchar,
    SortStatus               TStatus,

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

    UDF11                    TUDF,
    UDF12                    TUDF,
    UDF13                    TUDF,
    UDF14                    TUDF,
    UDF15                    TUDF,
    UDF16                    TUDF,
    UDF17                    TUDF,
    UDF18                    TUDF,
    UDF19                    TUDF,

    UDF20                    TUDF,
    UDF21                    TUDF,
    UDF22                    TUDF,
    UDF23                    TUDF,
    UDF24                    TUDF,
    UDF25                    TUDF,
    UDF26                    TUDF,
    UDF27                    TUDF,
    UDF28                    TUDF,
    UDF29                    TUDF,
    UDF30                    TUDF,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkReceiptDetails_ReceiptDetailId PRIMARY KEY (ReceiptDetailId)
);

create index ix_ReceiptDetails_SKU               on ReceiptDetails (SKUId, CustPO);
/* Used in pr_RFC_ReceiveToLPN:  SKUId used when identifying the scanned SKU for receiving */
create index ix_ReceiptDetails_ReceiptId         on ReceiptDetails (ReceiptId, SKUId) Include (QtyOrdered, QtyInTransit, QtyReceived, QtyToReceive);

Go
