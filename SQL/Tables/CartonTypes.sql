/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/23  AY      CartonTypes: Renamed UDFs to prefix with CT_ (HA-796)
  CartonTypes: Added MaxUnits
  2018/02/08  TD      CartonTypes: Added CartonTypeFilter (S2G-107)
  2017/04/10  TK      CartonTypes: Added Account (HPI-1494)
  2016/03/18  AY      CartonTypes: Added Ownership, Warehouse
  2015/09/09  YJ      Added SoldToId for ukCartonTypes_Description
  2015/04/23  AY      CartonTypes: Added SoldToId, ShipToId, AvailableSpaces and UDF fields
  2011/08/23  AA      CartonTypes - Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Carton Types
 Notes: The table is for listing various carton types used.

 CarrierPackagingType - at times, the CartonType information has be to be translated to
                        carrier or service specific code, when processing shipping transactions
                        or generating ship labels. This column will hold such constants for various
                        services used as an XML format
                        Ex
                        This structure has been decided based on making it very simple to handle this
                        in the carrier interface end

                        <CarrierPackagingTypes>
                          <CarrierPackagingType>
                            <ShipVia>FEDEX</ShipVia>
                            <PackagingType>YOUR_PACKAGING</PackagingType>
                          </CarrierPackagingType>
                          <CarrierPackagingType>
                            <ShipVia>FXSP</ShipVia>
                            <PackagingType>FXSPCARTON</PackagingType>
                          </CarrierPackagingType>
                        </CarrierPackagingTypes>
------------------------------------------------------------------------------*/
Create Table CartonTypes (
    RecordId                 TRecordId      identity (1,1) not null,

    CartonType               TCartonType    not null,
    Description              TDescription   not null,
    EmptyWeight              TWeight        default 0.0,

    InnerLength              TLength        default 1.0,
    InnerWidth               TLength        default 1.0,
    InnerHeight              TLength        default 1.0,
    InnerVolume              as (InnerLength * InnerWidth * InnerHeight),
    InnerDimensions          as coalesce(cast(InnerLength as varchar), '_') + ' x ' +
                                coalesce(cast(InnerWidth  as varchar), '_') + ' x ' +
                                coalesce(cast(InnerHeight as varchar), '_'),

    /* Not used as of now - may be in future */
    OuterLength              TLength        default 1.0,
    OuterWidth               TLength        default 1.0,
    OuterHeight              TLength        default 1.0,
    OuterVolume              as (OuterLength * OuterWidth * OuterHeight),
    OuterDimensions          as coalesce(cast(OuterLength as varchar), '_') + ' x ' +
                                coalesce(cast(OuterWidth  as varchar), '_') + ' x ' +
                                coalesce(cast(OuterHeight as varchar), '_'),

    CarrierPackagingType     varchar(max)   not null,

    Account                  TAccount,      -- deprecated, use CartonGroups table
    SoldToId                 TCustomerId,   -- deprecated, use CartonGroups table
    ShipToId                 TShipToId,     -- deprecated, use CartonGroups table

    AvailableSpace           TInteger,
    MaxWeight                TWeight,       -- future use, max weight the carton can hold
    MaxUnits                 TInteger,

    CartonTypeFilter         TDescription,  -- Deprecated, not used
    Ownership                TOwnership,    -- Deprecated, not used
    Warehouse                TWarehouse,    -- Deprecated, not used

    Status                   TStatus        not null default 'A' /* Active */,
    SortSeq                  TSortSeq                default 0,
    Visible                  TBoolean       not null default 1,

    CT_UDF1                  TUDF,
    CT_UDF2                  TUDF,
    CT_UDF3                  TUDF,
    CT_UDF4                  TUDF,
    CT_UDF5                  TUDF,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkCartonTypes_RecordId    PRIMARY KEY (RecordId),
    constraint ukCartonTypes_Code        UNIQUE (CartonType, BusinessUnit),
    constraint ukCartonTypes_Description UNIQUE (Description, BusinessUnit)
);

create index ix_CartonTypes_Status               on CartonTypes (Status);
create index ix_CartonTypes_Visible              on CartonTypes (Visible, CartonType);

Go
