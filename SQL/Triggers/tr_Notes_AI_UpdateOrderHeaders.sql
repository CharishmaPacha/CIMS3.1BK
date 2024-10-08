/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_Notes_AI_UpdateOrderHeaders') is not null
  drop Trigger tr_Notes_AI_UpdateOrderHeaders;
Go

Create Trigger [tr_Notes_AI_UpdateOrderHeaders] on [Notes] for Insert
As
begin

  if (exists (select * from Inserted where EntityType in ('Cust', 'PT')))
    begin
      update OH
      set OH.HasNotes = 'Y' /* Yes */
      from OrderHeaders OH
           join Inserted INS on ((INS.EntityType = 'Cust'       ) and
                                 (OH.SoldToId    = INS.EntityKey))
      where (OH.HasNotes = 'N' /* No */) and
            (OH.Status not in ('S' /* Shipped */,
                               'X' /* Cancelled */,
                               'D' /* Completed */)) and
            (INS.EntityType = 'Cust') and
            (INS.Status = 'A' /* Active */);

      update OH
      set HasNotes = 'Y' /* Yes */
      from OrderHeaders OH
           join Inserted INS on ((INS.EntityType = 'PT') and
                                 ((OH.OrderId = INS.EntityId) or (OH.PickTicket = INS.EntityKey)))
      where (OH.HasNotes = 'N' /* No */) and
            (OH.Status not in ('S' /* Shipped */,
                               'X' /* Cancelled */,
                               'D' /* Completed */)) and
            (INS.EntityType = 'PT') and
            (INS.Status = 'A' /* Active */);
    end
end /* tr_Notes_AI_UpdateOrderHeaders */

Go

alter table Notes Disable trigger tr_Notes_AI_UpdateOrderHeaders;

Go

