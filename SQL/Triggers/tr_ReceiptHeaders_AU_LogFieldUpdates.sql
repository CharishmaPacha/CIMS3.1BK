/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_ReceiptHeaders_AU_LogFieldUpdates') is not null
  drop Trigger tr_ReceiptHeaders_AU_LogFieldUpdates;
Go
/*------------------------------------------------------------------------------
  After Update Trigger tr_ReceiptHeaders_AU_LogFieldUpdates to log changes to
    Date shipped on PO.
------------------------------------------------------------------------------*/
Create Trigger [tr_ReceiptHeaders_AU_LogFieldUpdates] on [ReceiptHeaders] for Update
As
begin
  /* When ROH has been updated, log to FieldUpdateLog - if there is a change to DateShipped */
  insert into FieldUpdateLog (TableName, FieldName, EntityId, EntityKey, OldValue, NewValue, BusinessUnit, CreatedBy)
    select 'RH', 'DateShipped', INS.ReceiptId, INS.ReceiptNumber, convert(varchar, cast(DEL.DateShipped as date), 101),
           convert(varchar, cast(INS.DateShipped as date), 101), INS.BusinessUnit, 'cimsTrigger'
    from Inserted INS join Deleted DEL on INS.ReceiptId = DEL.ReceiptId
    where (DEL.DateShipped <> INS.DateShipped);
end /* tr_ReceiptHeaders_AU_LogFieldUpdates */

Go

