/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/10/10  PKS     PT_PickBatch and PT_PackingCloseLPN changed to PT_Picking and PT_Packing respectively.
  2013/10/03  PKS     Added message PackingCloseLPN.
  2013/07/20  PKS     Comment corrected for PT_PickBatch.
  2013/07/24  TD      Initial revision.
------------------------------------------------------------------------------*/

Go

/* Create temp table */
select MessageName, Description into #ProductivityComments from Messages where MessageName = '#';

insert into #ProductivityComments
            (MessageName,      Description)

/*------------------------------------------------------------------------------*/
/* Batch Picking */
/*------------------------------------------------------------------------------*/
      select 'PT_Picking',     'Picked %2 units from %1 Locations for %3 different SKUs for %5 PickBatch'
union select 'PT_Packing',     'Packed %2 units for %3 different SKUs for PickBatch %5';

Go

/*------------------------------------------------------------------------------*/
/* Delete any existing audit comments */
delete from Messages where MessageName like 'PT_%';

/* Add the new messages */
insert into Messages (MessageName, Description, NotifyType, Status, BusinessUnit)
select MessageName, Description, 'I' /* Info */, 'A' /* Active */, (select Top 1 BusinessUnit from vwBusinessUnits order by SortSeq)
from #ProductivityComments;

Go
