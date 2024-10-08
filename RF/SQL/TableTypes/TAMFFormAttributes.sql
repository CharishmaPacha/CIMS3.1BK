/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/16  NB      Added TAMFFormAttributes (CIMSV3-773)
------------------------------------------------------------------------------*/


Go

Create Type TAMFFormAttributes as Table (
    RecordId                 integer    identity (1,1),
    AttributeName            varchar(128),
    AttributeValue           varchar(1000),
    
    Primary Key              (RecordId),
    Unique                   (AttributeName)
);

Grant References on Type:: TAMFFormAttributes to public;

Go
