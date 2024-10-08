/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/03  HB      Added QCHeaders, QCDetails (HPI-2283).
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: QC Headers

  QCMode - SEU (Scan Each unit), SSO (Scan SKU once)
  QCCategory - Receiving/Shipping/InventoryQC
------------------------------------------------------------------------------*/
Create Table QCHeaders (
    QCRecordId               TRecordId      identity(1,1) not null,

    LPNId                    TRecordId      not null,
    LPN                      TLPN           not null,
    TrackingNo               TTrackingNo,
    OrderId                  TRecordId,
    PickTicket               TPickTicket,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    WaveType                 TTypeCode,

    ReceiptId                TRecordId,
    ReceiptNumber            TReceiptNumber,
    ReceiverNumber           TReceiverNumber,
    ROType                   TTypeCode,

    QCMode                   TTypeCode,
    QCCategory               TCategory,

    PickedBy                 TUserId,
    PackedBy                 TUserId,
    QCDate                   TDate          default current_timestamp,
    QCStatus                 TStatus,
    NumErrors                TCount,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkQCHeaders_QCRecordId PRIMARY KEY (QCRecordId)
);

create index ix_QCHdr_LPNId                      on QCHeaders(LPNId);
create index ix_QCHdr_LPN                        on QCHeaders(LPN, BusinessUnit) include (LPNId);
create index ix_QCHdr_QCDate                     on QCHeaders(QCDate, LPN, BusinessUnit) include (LPNId);

Go
