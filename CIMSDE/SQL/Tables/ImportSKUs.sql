/*------------------------------------------------------------------------------
 Table: ImportSKUs
------------------------------------------------------------------------------*/
declare @ttImportSKUs TSKUImportType;

select * into ImportSKUs
from @ttImportSKUs;

Go

alter table ImportSKUs drop column RecordId;

alter table ImportSKUs add RecordId        TRecordId identity (1,1),
                           ExchangeStatus  TStatus,
                           ImportBatch     TBatch,
                           InsertedTime    TDateTime DEFAULT current_timestamp,
                           ProcessedTime   TDateTime,
                           Reference       TDescription,
                           Result          TVarchar;

create index ix_ImportSKUs_ExchangeStatus        on ImportSKUs (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportSKUs_KeyField              on ImportSKUs (SKU, ExchangeStatus) Include (RecordId, ProcessedTime);
create index ix_ImportSKUs_ImportBatch           on ImportSKUs (ImportBatch) Include (RecordId, ExchangeStatus);

Go

