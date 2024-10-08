/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/07/01  OK      Added the TCartonTypesValidation,TCartonTypesImportType types.
  Create Type TCartonTypesValidation as Table
  Grant References on Type:: TCartonTypesValidation  to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in Validation of data being imported, capture the validations, use to update the CartonTypes */
Create Type TCartonTypesValidation as Table
  (
    RecordId                 TRecordId,
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
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,
    EntityKey                TEntityKey,
    InputXML                 TXML,
    ResultXML                TXML,
    HostRecId                TRecordId,
    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
  );

Grant References on Type:: TCartonTypesValidation  to public;

Go
