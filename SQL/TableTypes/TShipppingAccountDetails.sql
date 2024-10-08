/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/26  VS      TShipppingAccountDetails: Initial Version (OBV3-1301)
  Create Type TShipppingAccountDetails as table (
  grant references on Type:: TShipppingAccountDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TShipppingAccountDetails as table (
    UserId                   TUserId,
    Password                 TPassword,
    ShipperAccountNumber     TAccount,
    ShipperMeterNumber       TMeterNumber,
    ShipperAccessKey         TAccessKey,
    ShippingAccountName      TAccountName,
    OtherShipperDetails      TVarchar,
    RecordId                 TRecordId identity(1,1)
);

grant references on Type:: TShipppingAccountDetails to public;

Go
