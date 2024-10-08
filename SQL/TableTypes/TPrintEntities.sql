/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/23  OK      TPrintEntities: Added table type (BK-263)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
if type_id('dbo.TPrintEntities') is not null drop type TPrintEntities;
Create Type TPrintEntities as Table (
    EntityType               TEntity,
    EntityId                 TRecordId,
    EntityKey                TEntityKey,

    LPNId                    TRecordId,
    LPN                      TLPN,

    OrderId                  TRecordId,
    PickTicket               TPickTicket,

    TaskId                   TRecordId,

    WaveId                   TRecordId,
    WaveNo                   TWaveNo,

    RecordId                 TRecordId      Identity(1, 1),
    Primary Key              (RecordId)
);

Grant References on Type:: TPrintEntities to public;

Go
