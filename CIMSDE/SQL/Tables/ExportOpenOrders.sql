/*------------------------------------------------------------------------------
 Table: ExportOpenOrders
------------------------------------------------------------------------------*/
declare @ttExportOpenOrders TOpenOrderExportType;

select * into ExportOpenOrders
from @ttExportOpenOrders;

Go

alter table ExportOpenOrders drop column RecordId;

alter table ExportOpenOrders add RecordId        TRecordId identity (1,1),
                                 ExchangeStatus  TStatus    DEFAULT 'N',
                                 InsertedTime    TDateTime  DEFAULT current_timestamp,
                                 ProcessedTime   TDateTime,
                                 Reference       TDescription,
                                 Result          TVarchar,
                                 CIMSRecId       TRecordId;

create index ix_ExportOpenOrders_ExchangeStatus  on ExportOpenOrders (ExchangeStatus, BusinessUnit) Include (RecordId);
create index ix_ExportOpenOrders_PickTicket      on ExportOpenOrders (PickTicket, RecordId) Include (RecordType);

Go

