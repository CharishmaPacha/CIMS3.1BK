/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TEDIProcessMap: Added for EDI processing
  Create Type TEDIProcessMap as Table
  Grant References on Type:: TEDIProcessMap to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TEDIProcessMap as Table
  (
    ProcessAction            TAction,

    SegmentId                TName,
    ProcessConditions        TQuery,
    ElementId                TName,
    CIMSXMLField             TName,
    CIMSFieldName            TName,
    DefaultValue             TControlValue,
    CIMSXMLPath              TName,

    EDIElementDesc           TDescription,

/*
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
*/
    RecordId                 TRecordId identity (1,1),
    Primary Key              (RecordId)
  );

Grant References on Type:: TEDIProcessMap to public;

Go
