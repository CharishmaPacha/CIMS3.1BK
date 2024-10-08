/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2020/12/15  RT      Initial revision for V2 clients to upgrade with V3 (CID-1569)
------------------------------------------------------------------------------*/

Go

/* Create temp table */
select MessageName, Description into #AuditComments from Messages where MessageName = '#';

insert into #AuditComments
            (MessageName,                 Description)
      select 'AT_TaskDetail_Export',      'Task Detail %1 scheduled for export via API'

Go

/* Add the new messages */
insert into Messages (MessageName, Description, NotifyType, Status, BusinessUnit)
select MessageName, Description, 'I' /* Info */, 'A' /* Active */, (select Top 1 BusinessUnit from vwBusinessUnits order by SortSeq)
from #AuditComments;

/*------------------------------------------------------------------------------*/
/* Replace the captions for fields like SKU, LPN, Pallet, PickBatch, PickTicket
   Note this has to be done after messages are inserted above as fn_Messages_GetDescription
   gets from Messages table and not from # table */
update Messages
set Description = replace(Description, '#SKU', dbo.fn_Messages_GetDescription('AT_SKU'));

update Messages
set Description = replace(Description, '#PickBatches', dbo.fn_Messages_GetDescription('AT_PickBatches'));

update Messages
set Description = replace(Description, '#PickBatch', dbo.fn_Messages_GetDescription('AT_PickBatch'));

update Messages
set Description = replace(Description, '#LPN', dbo.fn_Messages_GetDescription('AT_LPN'));

update Messages
set Description = replace(Description, '#Pallet', dbo.fn_Messages_GetDescription('AT_Pallet'));

update Messages
set Description = replace(Description, '#Location', dbo.fn_Messages_GetDescription('AT_Location'));

update Messages
set Description = replace(Description, '#Order', dbo.fn_Messages_GetDescription('AT_Order'));

Go
