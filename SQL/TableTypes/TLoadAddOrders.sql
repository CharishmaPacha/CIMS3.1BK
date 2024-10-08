/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/13  RKC     Added TLoadAddOrders (HA-1610)
  Create Type TLoadAddOrders as Table (
  Grant References on Type:: TLoadAddOrders   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Used in the processing of Adding Orders to Loads or generating Loads */
Create Type TLoadAddOrders as Table (
    RecordId                  TRecordId identity(1,1) not null,

    OrderId                   TRecordId,
    PickTicket                TPickTicket,

    LoadId                    TLoadId,
    LoadNumber                TLoadNumber,

    LoadGroup                 TLoadGroup,
    ProcessStatus             TStatus,

    Primary Key               (RecordId)
);

Grant References on Type:: TLoadAddOrders   to public;

Go
