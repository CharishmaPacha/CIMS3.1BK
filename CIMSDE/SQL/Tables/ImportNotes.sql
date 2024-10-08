/*------------------------------------------------------------------------------
 Table: ImportNotes
------------------------------------------------------------------------------*/
declare @ttImportNotes TNoteImportType;

select * into ImportNotes
from @ttImportNotes;

Go

alter table ImportNotes drop column RecordId;

alter table ImportNotes add RecordId        TRecordId identity (1,1),
                            ExchangeStatus  TStatus,
                            InsertedTime    TDateTime DEFAULT current_timestamp,
                            ProcessedTime   TDateTime,
                            Reference       TDescription,
                            Result          TVarchar;

create index ix_ImportNotes_ExchangeStatus       on ImportNotes (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportNotes_KeyField             on ImportNotes (RecordType, EntityKey, NoteType, ExchangeStatus) Include (RecordId, ProcessedTime);

Go

