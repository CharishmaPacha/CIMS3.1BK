/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this TableType exists. Taken here for additional fields.
  So, if there are any common fields to be added, MUST consider adding the same in Base version as well.
  *****************************************************************************

  2020/09/29  SK      TAuditDetails: Initial revision (CIMS-2967)
------------------------------------------------------------------------------*/

Go

if type_id('dbo.TAuditDetails') is not null drop type TAuditDetails;
/*----------------------------------------------------------------------------*/
/* Table Type for handling Audit Detail records */
Create Type TAuditDetails as Table
  (
    ActivityType         TActivityType,
    Comment              varchar(500),
    BusinessUnit         TBusinessUnit,
    UserId               TUserId,

    AuditId              TRecordId,

    SKUId                TRecordId,
    SKU                  TSKU,
    LPNId                TRecordId,
    LPN                  TLPN,
    OrderId              TRecordId,
    PickTicket           TPickTicket,
    WaveId               TRecordId,
    WaveNo               TPickBatchNo,
    ToLPNId              TRecordId,
    ToLPN                TLPN,
    LocationId           TRecordId,
    Location             TLocation,
    ToLocationId         TRecordId,
    ToLocation           TLocation,
    PalletId             TRecordId,
    Pallet               TPallet,
    ReceiverId           TRecordId,
    ReceiptId            TRecordId,
    TaskId               TRecordId,
    TaskDetailId         TRecordId,
    PrevInnerPacks       TInnerPacks,
    InnerPacks           TInnerPacks,
    PrevQuantity         TQuantity,
    Quantity             TQuantity,

    Warehouse            TWarehouse,
    ToWarehouse          TWarehouse,
    Ownership            TOwnership,
    ToOwnership          TOwnership,

    Unique               (ActivityType, Comment, BusinessUnit)
  );

Grant References on Type:: TAuditDetails to public;

Go
