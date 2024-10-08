/*------------------------------------------------------------------------------
 Table: ExportTransactions

 CIMSRecId and reference fields are already in domain, so no need to add again here
------------------------------------------------------------------------------*/
declare @ttCIMSExports TExportsType;

select * into ExportTransactions
from @ttCIMSExports;

Go

alter table ExportTransactions drop column RecordId;

alter table ExportTransactions add RecordId        TRecordId identity (1,1),
                                   ExchangeStatus  TStatus   DEFAULT 'N',
                                   InsertedTime    TDateTime DEFAULT current_timestamp,
                                   ProcessedTime   TDateTime,
                                   --Reference       TDescription, There is already a reference field
                                   Result          TVarchar;
                                   --CIMSRecId       TRecordId

/* Client side would be using to mark the record as processed for each record id */
create index ix_ExportTrans_RecordId             on ExportTransactions (RecordId);
create index ix_ExportTrans_ExchangeStatus       on ExportTransactions (ExchangeStatus, SourceSystem, RecordType, BusinessUnit) Include (RecordId, SKU, PickTicket, LPN);
create index ix_ExportTrans_TransType            on ExportTransactions (RecordType, RecordId) Include (SKU, TransQty);
create index ix_ExportTrans_ExportBatch          on ExportTransactions (ExportBatch, RecordId) Include (SKU, TransQty);
create index ix_ExportTrans_SKUId                on ExportTransactions (SKU, RecordType) Include (RecordId, TransQty, TransDateTime, ExchangeStatus);
create index ix_ExportTrans_LPNId                on ExportTransactions (LPN, RecordType) Include (RecordId, TransQty, TransDateTime, ExchangeStatus);
create index ix_ExportTrans_RecordType           on ExportTransactions (RecordType, SourceSystem, ExchangeStatus) Include (RecordId, TransQty, TransDateTime);
create index ix_ExportTrans_PickTicket           on ExportTransactions (PickTicket, RecordType) Include (RecordId, TransQty, TransDateTime, ExchangeStatus);

Go

