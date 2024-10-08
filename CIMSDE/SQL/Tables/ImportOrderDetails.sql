/*------------------------------------------------------------------------------
 Table: ImportOrderDetails
------------------------------------------------------------------------------*/
declare @ttImportOrderDetails TOrderDetailsImportType;

select * into ImportOrderDetails
from @ttImportOrderDetails;

Go

alter table ImportOrderDetails drop column RecordId;

alter table ImportOrderDetails add RecordId        TRecordId identity (1,1),
                                   ExchangeStatus  TStatus,
                                   ImportBatch     TBatch,
                                   InsertedTime    TDateTime DEFAULT current_timestamp,
                                   ProcessedTime   TDateTime,
                                   Reference       TDescription,
                                   Result          TVarchar;

create index ix_ImportOrderDetails_ExchangeStatus     on ImportOrderDetails (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportOrderDetails_KeyField           on ImportOrderDetails (PickTicket, ExchangeStatus) Include (RecordId, ProcessedTime);
create index ix_ImportOrderDetails_ImportBatch        on ImportOrderDetails (ImportBatch) Include (RecordId, ExchangeStatus);

Go

