/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/24  PKK     TWavesToAllocate: Included CartonizationModel (HA-2664)
  2020/05/04  TK      TWavesToAllocate: Added InvAllocationModel (HA-382)
  2018/11/01  AY      TWavesToAllocate (OB2-706)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
Allocation
------------------------------------------------------------------------------*/
/* Table Type to use for collecting all the waves to allocate */
Create Type TWavesToAllocate as Table (
    WaveId                   TRecordId,
    WaveNo                   TWaveNo,
    WaveType                 TTypeCode,
    WaveStatus               TStatus,
    Account                  TAccount,
    IsAllocated              TFlags,
    InvAllocationModel       TDescription,
    CartonizationModel       TDescription,
    Warehouse                TWarehouse,
    AllocPriority            TInteger,

    RecordId                 TRecordId      Identity(1,1)
);

Grant References on Type:: TWavesToAllocate to public;

Go
