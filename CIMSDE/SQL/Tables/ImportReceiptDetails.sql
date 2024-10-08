/*------------------------------------------------------------------------------
 Table: ImportReceiptDetails
------------------------------------------------------------------------------*/
declare @ttImportReceiptDetails TReceiptDetailImportType;

select * into ImportReceiptDetails
from @ttImportReceiptDetails;

Go

alter table ImportReceiptDetails drop column RecordId;

alter table ImportReceiptDetails add RecordId        TRecordId identity (1,1),
                                     ExchangeStatus  TStatus,
                                     InsertedTime    TDateTime  DEFAULT current_timestamp,
                                     ProcessedTime   TDateTime,
                                     Reference       TDescription,
                                     Result          TVarchar;

create index ix_ImportReceiptDetails_ExchangeStatus   on ImportReceiptDetails (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportReceiptDetails_KeyField         on ImportReceiptDetails (ReceiptNumber, SKU, ExchangeStatus) Include (RecordId, ProcessedTime);

Go

