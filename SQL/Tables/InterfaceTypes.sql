/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2010/12/13  PK      Created table : InterfaceTypes, InterfaceLog.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: InterfaceTypes
------------------------------------------------------------------------------*/
Create Table InterfaceTypes (
    RecordId                 TRecordId      identity (1,1) not null,

    TransferType             TTransferType, /* E - (Export), I - (Import) */
    RecordType               TRecordType,   /* SKU, Receipts... ect */

    Description              TDescription,

    ProcedureName            TProcedureName,

    SortSeq                  TSortSeq,
    Status                   TStatus        not null default 'A',

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkInterfaceTypes                                  PRIMARY KEY (RecordId),
    constraint ukInterfaceTypes_TransferRecordTypeBusinessUnit   UNIQUE (TransferType, RecordType, BusinessUnit)
);

Go
