/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  Create Type TCartShelves as Table (
  Grant References on Type:: TCartShelves to public;
------------------------------------------------------------------------------*/

Go

/* Table definition to hold the cart layout i.e #Shelves and utilization of those */
Create Type TCartShelves as Table (
    CartType                 TTypeCode,
    /* Shelf */
    Shelf                    TLevel,
    ShelfWidth               TInteger,
    ShelfHeight              TInteger,
    UsedWidth                TInteger,
    AvailableWidth           As ShelfWidth  - UsedWidth,

    Status                   TStatus        Default 'A' /* Available */,
    SortOrder                TSortOrder,
    /* Task */
    TaskId                   TRecordId,
    TDCategory1              TCategory,
    TDCategory2              TCategory,
    TDCategory3              TCategory,
    TDCategory4              TCategory,
    TDCategory5              TCategory,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId identity (1,1),
    Primary Key              (RecordId),
    Unique                   (TaskId, AvailableWidth, ShelfHeight, RecordId)
);

Grant References on Type:: TCartShelves to public;

Go
