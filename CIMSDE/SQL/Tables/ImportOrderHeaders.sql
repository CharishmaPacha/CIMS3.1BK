/*------------------------------------------------------------------------------
 Table: ImportOrderHeaders
------------------------------------------------------------------------------*/
declare @ttImportOrderHeaders TOrderHeaderImportType;

select * into ImportOrderHeaders
from @ttImportOrderHeaders;

Go

alter table ImportOrderHeaders drop column RecordId;

alter table ImportOrderHeaders add RecordId        TRecordId identity (1,1),
                                   ExchangeStatus  TStatus,
                                   ImportBatch     TBatch,
                                   InsertedTime    TDateTime DEFAULT current_timestamp,
                                   ProcessedTime   TDateTime,
                                   Reference       TDescription,
                                   Result          TVarchar;

create index ix_ImportOrderHeaders_ExchangeStatus     on ImportOrderHeaders (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportOrderHeaders_KeyField           on ImportOrderHeaders (PickTicket, ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportOrderHeaders_ImportBatch        on ImportOrderHeaders (ImportBatch) Include (RecordId, ExchangeStatus);

Go

