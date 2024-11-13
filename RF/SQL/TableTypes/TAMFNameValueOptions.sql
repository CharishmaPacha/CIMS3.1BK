/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/07/27  RV      Added TAMFNameValueOptions (FBV3-1611)
------------------------------------------------------------------------------*/


Go

Create Type TAMFNameValueOptions as Table (
    RecordId      TRecordId identity(1,1),
    Name          TName,
    Value         TName,
    Reference1    TVarchar,
    Reference2    TVarchar,
    Reference3    TVarchar,
    Reference4    TVarchar,
    Reference5    TVarchar,
    
    primary key   (RecordId),
    unique        (Name)
);

grant references on Type:: TAMFNameValueOptions to public;

Go
