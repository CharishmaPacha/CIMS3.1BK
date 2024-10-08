/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/01/13  VK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* StatusBitType */
/*------------------------------------------------------------------------------*/
declare @StatusBitTypeStatuses TStatusesTable, @Entity TEntity = 'StatusBitType';

insert into @StatusBitTypeStatuses
       (StatusCode,  StatusDescription,  Status)
values ('1',         'Active',           'A'),
       ('0',         'Inactive',         'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @StatusBitTypeStatuses;

Go
