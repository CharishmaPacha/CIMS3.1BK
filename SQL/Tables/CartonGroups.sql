/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/29  HYP     CartonGroups: Removed the fields (HA-796)
  2019/02/04  AY      CartonGroups: Added (HPI-2380)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: Carton Groups
 Notes: The table is for listing various carton groups used and the carton types within each of those groups

------------------------------------------------------------------------------*/
Create Table CartonGroups (
    RecordId                 TRecordId      identity (1,1) not null,

    CartonGroup              TDescription   not null,
    CartonType               TCartonType    not null,
    Description              TDescription   not null,

    AvailableSpace           TInteger,
    MaxWeight                TWeight,       -- future use, max weight the carton can hold
    MaxUnits                 TInteger,

    Status                   TStatus        not null default 'A' /* Active*/,
    SortSeq                  TSortSeq               default 0,
    Visible                  TBoolean       not null default 1,

    CG_UDF1                  TUDF,
    CG_UDF2                  TUDF,
    CG_UDF3                  TUDF,
    CG_UDF4                  TUDF,
    CG_UDF5                  TUDF,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkCartonGroup_RecordId PRIMARY KEY (RecordId),
    constraint ukCartonGroup_Code     UNIQUE (CartonGroup, CartonType, BusinessUnit)
);

Go
