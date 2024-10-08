/*------------------------------------------------------------------------------
 Table: Controls
------------------------------------------------------------------------------*/
declare @ttTControlsTable TControlsTable;

select * into Controls
from @ttTControlsTable;

alter table Controls add CategorySortSeq          TSortSeq  not null DEFAULT 0,
                         BusinessUnit             TBusinessUnit,
                         CreatedDate              TDateTime DEFAULT current_timestamp,
                         ModifiedDate             TDateTime,
                         CreatedBy                TUserId,
                         ModifiedBy               TUserId;

alter table Controls add constraint pkControls_RecordId                 primary key (RecordId);
alter table Controls add constraint ukControls_CategoryCodeBusinessUnit unique (ControlCategory, ControlCode, BusinessUnit);

Go
