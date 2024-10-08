/*------------------------------------------------------------------------------
 Table: ImportReceiptHeaders
------------------------------------------------------------------------------*/
declare @ttImportReceiptHeaders TReceiptHeaderImportType;

select * into ImportReceiptHeaders
from @ttImportReceiptHeaders;

Go

alter table ImportReceiptHeaders drop column RecordId;
alter table ImportReceiptHeaders drop column InputXML;
alter table ImportReceiptHeaders drop column ResultXML;

alter table ImportReceiptHeaders add RecordId        TRecordId identity (1,1),
                                     ExchangeStatus  TStatus,
                                     InsertedTime    TDateTime DEFAULT current_timestamp,
                                     ProcessedTime   TDateTime,
                                     Reference       TDescription,
                                     Result          TVarchar;

create index ix_ImportReceiptHeaders_ExchangeStatus   on ImportReceiptHeaders (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportReceiptHeaders_KeyField         on ImportReceiptHeaders (ReceiptNumber, ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);

Go

