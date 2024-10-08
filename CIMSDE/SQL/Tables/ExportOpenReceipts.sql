/*------------------------------------------------------------------------------
 Table: ExportOpenReceipts
------------------------------------------------------------------------------*/
declare @ttCIMSExportOpenReceipt TOpenReceiptExportType;

select * into ExportOpenReceipts
from @ttCIMSExportOpenReceipt;

Go

alter table ExportOpenReceipts drop column RecordId;

alter table ExportOpenReceipts add RecordId        TRecordId identity (1,1),
                                   ExchangeStatus  TStatus   DEFAULT 'N',
                                   InsertedTime    TDateTime DEFAULT current_timestamp,
                                   ProcessedTime   TDateTime,
                                   Reference       TDescription,
                                   Result          TVarchar,
                                   CIMSRecId       TRecordId;

create index ix_ExportOpenReceipts_ExchangeStatus     on ExportOpenReceipts (ExchangeStatus, BusinessUnit) Include (RecordId);
create index ix_ExportOpenReceipts_ReceiptNumber      on ExportOpenReceipts (ReceiptNumber, RecordId) Include (RecordType);

Go

