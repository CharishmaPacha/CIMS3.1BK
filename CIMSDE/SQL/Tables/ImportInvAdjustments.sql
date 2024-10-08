/*------------------------------------------------------------------------------
 Table: ImportInvAdjustments

 UpdateOption   - This field should have =, +, -.
                    If the UpdateOption is '=' then update the inventory with specified quantity for the LPN/Location.
                    If the UpdateOption is '+' then add specified quantity to the existing inventory.
                    If the UpdateOption is '-' then reduce specified quantity to the existing inventory.

 Quantity       - Quantity to the adjust the inventory
 ExchangeStatus - This field have the information regarding whether these adjustments are done in CIMS or not.
                    If adjustments are done then then value should be 'Y' otherwise 'N'
 ReceiptNumber   - Usually adjustment may happened because of returns, so we may insert the Receipt against this
                  inventory adjust.

 RecordType - There could be different reasons to import inventory into CIMS and so RecordType would be used
              to identify the process this applies to. There would be a procedure to handle different processes
------------------------------------------------------------------------------*/

declare @ttImportInvAdjustments TImportInvAdjustments;

select * into ImportInvAdjustments
from @ttImportInvAdjustments;

Go

alter table ImportInvAdjustments drop column RecordId;

alter table ImportInvAdjustments add RecordId        TRecordId identity (1,1),
                                     ExchangeStatus  TStatus,
                                     InsertedTime    TDateTime DEFAULT current_timestamp,
                                     ProcessedTime   TDateTime;
 /* Constraints */
alter table ImportInvAdjustments add constraint pk_ImportInvAdjustments_RecordId  PRIMARY KEY (RecordId)

create index ix_ImportInvAdjustments_ExchangeStatus   on ImportInvAdjustments (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);

Go
