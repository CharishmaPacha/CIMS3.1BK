/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/11/15  TD      Added RoutingRules (CIMSDE-16)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: RoutingRules :

  We will have the data for all carriers and mapping which has best methods for
  the given inputs.
------------------------------------------------------------------------------*/
Create Table RoutingRules (

    RecordId                 TRecordId      identity (1,1) not null,
    SortSeq                  TInteger       default 0,

    /* input fields */
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    Account                  TAccount,

    ShipToZone               TName,         -- Zone can define State, Range of Zips, Country
    ShipToState              TState,
    ShipToZipStart           TZip,
    ShipToZipEnd             TZip,
    ShipToCountry            TCountry,
    ShipToAddressRegion      TDescription,  -- I: International, D-Domestic

    InputCarrier             TCarrier,
    InputShipVia             TShipVia,
    InputFreightTerms        TDescription,

    MinWeight                TWeight        default 0.0,
    MaxWeight                TWeight        default 0.0,

    DeliveryRequirement      TDescription,

    ShipFrom                 TShipFrom,
    Ownership                TOwnership,
    Warehouse                TWarehouse,

    Criteria1                TDescription,
    Criteria2                TDescription,
    Criteria3                TDescription,
    Criteria4                TDescription,
    Criteria5                TDescription,

    /* output fields */
    ShipVia                  TShipVia,
    FreightTerms             TDescription,
    BillToAccount            TBillToAccount,

    Comments                 TVarChar,
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Status                   TStatus        default 'A'  /* Active */,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

  constraint pkRoutingRules_RecordId PRIMARY KEY (RecordId)
);

create index ix_RoutingRules_SoldToShipTo        on RoutingRules (SoldToId, ShipToId) include(ShipToState, ShipToZipStart, ShipToZipEnd, InputShipVia, InputFreightTerms, MinWeight, MaxWeight);

Go
