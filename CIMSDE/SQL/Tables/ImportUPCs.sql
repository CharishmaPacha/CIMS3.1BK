/*------------------------------------------------------------------------------
 Table: ImportUPCs
------------------------------------------------------------------------------*/
declare @ttImportUPC TUPCImportType;

select * into ImportUPCs
from @ttImportUPC;

Go

alter table ImportUPCs drop column RecordId;

alter table ImportUPCs add RecordId        TRecordId identity (1,1),
                           ExchangeStatus  TStatus   DEFAULT 'N',
                           InsertedTime    TDateTime DEFAULT current_timestamp,
                           ProcessedTime   TDateTime,
                           Reference       TDescription,
                           Result          TVarchar;

create index ix_ImportUPCs_ExchangeStatus        on ImportUPCs (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportUPCs_KeyField              on ImportUPCs (SKU, ExchangeStatus) Include (RecordId, ProcessedTime);

Go

