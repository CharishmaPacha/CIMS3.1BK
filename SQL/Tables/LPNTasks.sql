/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/09/05  AY      LPNTasks: Added ix_LPNTasks_TaskId
  2014/04/18  TD      Added LPNTasks.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: LPN Tasks : This table will contains the data for label generated.
------------------------------------------------------------------------------*/
Create Table LPNTasks (
    RecordId                 TRecordId      identity (1,1) not null,

    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,

    TaskId                   TRecordId      not null,
    TaskDetailId             TRecordId      not null,

    LPNId                    TRecordId      not null,
    LPNDetailId              TRecordId      not null,

    DestZone                 TZoneId,

    Status                   TStatus        not null default 'A' /* Acitve */,

    Warehouse                TWarehouse,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkLPNTasks_RecordId PRIMARY KEY (RecordId)
);

create index ix_LPNTasks_TaskDetailId            on LPNTasks (TaskDetailId, TaskId);
create index ix_LPNTasks_LPNId                   on LPNTasks (LPNId) Include (RecordId, TaskId, TaskDetailId, LPNDetailId);
create index ix_LPNTasks_TaskId                  on LPNTasks (TaskId) Include (LPNId);

Go
