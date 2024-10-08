/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/07/01  OK      Added the TCartonTypesValidation,TCartonTypesImportType types.
  Create Type TCartonTypesImportType as Table (
  Grant References on Type:: TCartonTypesImportType  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in CartonTypes type Import
   This table structure mimics the record structure of CartonTypes table, with few additional fields
   to capture key fields, etc.. */
Create Type TCartonTypesImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

    CartonType               TCartonType,
    Description              TDescription,
    EmptyWeight              TWeight,

    InnerLength              TLength,
    InnerWidth               TLength,
    InnerHeight              TLength,
    InnerVolume              TVolume,
    OuterLength              TLength,
    OuterWidth               TLength,
    OuterHeight              TLength,
    OuterVolume              TVolume,

    CarrierPackagingType     varchar(max),
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    AvailableSpace           TInteger,
    MaxWeight                TWeight,
    Status                   TStatus,
    SortSeq                  TSortSeq,
    Visible                  TBoolean,

    CT_UDF1                  TUDF,
    CT_UDF2                  TUDF,
    CT_UDF3                  TUDF,
    CT_UDF4                  TUDF,
    CT_UDF5                  TUDF,

    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    CartonTypeId             TRecordId,
    EntityKey                TEntityKey,
    InputXML                 TXML,
    ResultXML                TXML,
    HostRecId                TRecordId,
    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
  );

Grant References on Type:: TCartonTypesImportType  to public;

Go
