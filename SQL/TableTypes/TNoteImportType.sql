/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/22  TD      TNoteImportType:Added EntityLineNo(HPI-2530)
  2017/12/22  PK      Added TNoteImportType (CIMS-1722).
  Create Type TNoteImportType as Table (
  Grant References on Type:: TNoteImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type used in Note Import
   This table structure mimics the record structure of Note import, with few additional fields
   to capture key fields, etc.,. */

Create Type TNoteImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,
    NoteType                 TTypeCode,
    Note                     TNote,
    NoteFormat               TDescription,
    EntityType               TTypeCode,
    EntityId                 TRecordId,
    EntityKey                TEntity,
    EntityLineNo             THostOrderLine,

    PrintFlags               TFlags,
    VisibleFlags             TFlags,
    Status                   TStatus,
    SortSeq                  TSortSeq,

    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    InputXML                 TXML,
    ResultXML                TXML,

    HostRecId                TRecordId,

    Primary Key              (RecordId),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TNoteImportType   to public;

Go
