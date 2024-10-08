/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/31  RKC     Receivers & ReceiptHeaders: Add ModifiedOn computed column and index (CIMS-3118)
  2020/06/25  NB      Receivers: Added Warehouse field(CIMSV3-987)
  2016/02/20  AY      Receivers: CreateDate defaults to current timestamp
  2014/04/23  SV      Receivers: Added Archived field.
  2014/04/14  VM      Receivers: Added Reference fields
  2014/03/01  PKS     Receivers: Added
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: Receivers
------------------------------------------------------------------------------*/
Create Table Receivers (
    ReceiverId     TRecordId                identity (1,1) not null,

    ReceiverNumber           TReceiverNumber,
    ReceiverDate             TDateTime,
    Status                   TStatus,

    BoLNumber                TBoLNumber,
    Container                TContainer,
    Warehouse                TWarehouse,

    Reference1               TDescription,
    Reference2               TDescription,
    Reference3               TDescription,
    Reference4               TDescription,
    Reference5               TDescription,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      default current_timestamp,
    CreatedBy                TUserId,
    ModifiedDate             TDateTime,
    ModifiedBy               TUserId,

    CreatedOn                as cast (CreatedDate as date),
    ModifiedOn               as cast (ModifiedDate as date),

    constraint pkReceivers_ReceiverId    PRIMARY KEY (ReceiverId),
    constraint ukReceivers_ReceiverNumer UNIQUE (ReceiverNumber, BusinessUnit)
);

/* Used in pr_Archive_Receivers */
create index ix_Receivers_Archived        on Receivers (Archived, Status) Include (ModifiedOn);

Go
