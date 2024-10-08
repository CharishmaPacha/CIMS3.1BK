/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/04/19  TD      Added TLPNTasksTable.
  Create Type TLPNTasksTable as Table (
  Grant References on Type:: TLPNTasksTable to public;
------------------------------------------------------------------------------*/

Go

Create Type TLPNTasksTable as Table (
    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,

    TaskId                   TRecordId,
    TaskDetailId             TRecordId,

    LPNId                    TRecordId,
    LPNDetailId              TRecordId,

    FromLPNId                TRecordId,

    DestZone                 TZoneId,

    Warehouse                TWarehouse,
    BusinessUnit             TBusinessUnit,

    RecordId                 TRecordId      identity (1,1)
);

Grant References on Type:: TLPNTasksTable to public;

Go
