/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/03  HB      Added QCHeaders, QCDetails (HPI-2283).
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: QC Details

   QCCheck - ItemCount or the additional Checks that are configured
   QCComment- This field determines the QC result for that particular item
               Verified, Wrong Item, Extra Item, Missing Item, Not on Order, etc.
------------------------------------------------------------------------------*/
Create Table QCDetails (
    RecordId                 TRecordId      identity(1,1) not null,
    QCRecordId               TRecordId      not null,

    LPNId                    TRecordId,
    SKUId                    TRecordId,
    ExpectedQty              TQuantity,
    ConfirmedQty             TQuantity,

    QCCheck                  TDescription,
    QCStatus                 TStatus,
    QCComment                TNote,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkQCDetails_RecordId PRIMARY KEY (RecordId)
);

create index ix_QCDtl_QCRecordId                 on QCDetails(QCRecordId);

Go
