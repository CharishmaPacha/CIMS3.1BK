/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/26  RV      TRouterConfirmationImportType: Intial version (S2G-233)
  Create Type TRouterConfirmationImportType as Table (
  Grant References on Type:: TRouterConfirmationImportType to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TRouterConfirmationImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNStatus                TStatus,
    ActualWeight             TWeight,
    Destination              TLocation,
    DivertDateTime           varchar(50),
    DivertDate               TDate,
    DivertTime               TTime,
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    BusinessUnit             TBusinessUnit,
    InputXML                 TXML,
    ResultXML                TXML,

    Primary Key              (RecordId)
);

Grant References on Type:: TRouterConfirmationImportType to public;

Go
