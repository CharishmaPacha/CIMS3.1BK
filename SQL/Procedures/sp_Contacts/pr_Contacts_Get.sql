/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_Get') is not null
  drop Procedure pr_Contacts_Get;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_Get:
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_Get
  (@ContactId     TRecordId)
as
begin
  select *
  from vwContacts
  where ContactId = @ContactId
end /* pr_Contacts_Get */

Go
