/*------------------------------------------------------------------------------
 Table: ExportOpenOrderSummary
------------------------------------------------------------------------------*/
declare @ttOpenOrdersSummary TOpenOrdersSummary;

select * into ExportOpenOrdersSummary
from @ttOpenOrdersSummary;

Go

alter table ExportOpenOrdersSummary drop column OrderId;
alter table ExportOpenOrdersSummary drop column CreatedOn;
alter table ExportOpenOrdersSummary drop column ModifiedOn;

alter table ExportOpenOrdersSummary add CreatedOn   as convert(date, CreatedDate),
                                        ModifiedOn  as convert(date, ModifiedDate);

create index ix_ExportOpenOrdersSummary_ExchangeStatus on ExportOpenOrdersSummary (ExchangeStatus, BusinessUnit) Include (RecordId);
create index ix_ExportOpenOrdersSummary_CreatedOn      on ExportOpenOrdersSummary (CreatedOn) Include (Archived, OrderStatus);
create index ix_ExportOpenOrdersSummary_Archived       on ExportOpenOrdersSummary (Archived) Include (ExchangeStatus);

Go

