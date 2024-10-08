/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/07  AY      PickBatchDetails: Added unique index by OrderDetailId to prevent OD on two diff. waves, added CustPO
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: PickBatchDetails
------------------------------------------------------------------------------*/
Create Table PickBatchDetails (
    RecordId                 TRecordId      identity (1,1) not null,

    /* PickBatchRelated */
    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,

    /* order related */
    OrderId                  TRecordId,

    /* Order Details related */
    OrderDetailId            TRecordId,

    Status                   TStatus        not null default 'A' /* Active */,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    UDF6                     TUDF,
    UDF7                     TUDF,
    UDF8                     TUDF,
    UDF9                     TUDF,
    UDF10                    TUDF,

    RuleId                   TRecordId,     /* For future use */

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkPickBatchDetails_RecordId      PRIMARY KEY (RecordId),
    constraint ukPickBatchDetails_OrderDetailId UNIQUE (OrderDetailId) -- Same (order)orderdetail cannot be repeated on another wave
);

create index ix_PBDetails_PickBatchId            on PickBatchDetails (PickBatchId) Include (OrderId, OrderDetailId);
create index ix_PBDetails_PickBatchNo            on PickBatchDetails (PickBatchNo) Include (OrderId, OrderDetailId);
create index ix_PBDetails_WaveId                 on PickBatchDetails (WaveId) Include (OrderId, OrderDetailId);
create index ix_PBDetails_WaveNo                 on PickBatchDetails (WaveNo) Include (OrderId, OrderDetailId);
create index ix_PBDetails_OrderId                on PickBatchDetails (OrderId) Include (PickBatchId, PickBatchNo);
create index ix_PBDetails_OrderDetailId          on PickBatchDetails (OrderDetailId, OrderId) Include (PickBatchId, PickBatchNo);
create index ix_PBDetails_Status                 on PickBatchDetails (Status) Include (PickBatchId, PickBatchNo, OrderId, OrderDetailId);

Go
