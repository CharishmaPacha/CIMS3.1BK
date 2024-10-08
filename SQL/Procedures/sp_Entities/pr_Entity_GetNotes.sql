/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/22  RV      pr_Entity_GetNotes: Initial version (OB2-1883)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entity_GetNotes') is not null
  drop Procedure pr_Entity_GetNotes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entity_GetNotes: Return the data set with respect to the Entity key and type.
------------------------------------------------------------------------------*/
Create Procedure pr_Entity_GetNotes
  (@InputXML     TXML)
as
  declare @EntityType   TEntity,
          @EntityId     TRecordId,
          @EntityKey    TEntityKey,

          @xmlData      xml,

          @BusinessUnit TBusinessUnit,
          @UserId       TUserId;
begin

  set @xmlData = cast(@InputXML as xml);

  /* extract session info */
  select @BusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]',       'TUserId')
  from @xmlData.nodes('/Root/SessionInfo') as Record(Col);

  select @EntityType = Record.Col.value('EntityType[1]', 'TEntity'),
         @EntityId   = Record.Col.value('EntityId[1]',   'TRecordId'),
         @EntityKey  = Record.Col.value('EntityKey[1]',  'TEntityKey')
  from @xmlData.nodes('/Root/EntityInfo') as Record(Col);

  if ((coalesce(@EntityType, '') = '') or ((coalesce(@EntityId, 0) = 0) and coalesce(@EntityKey, '') = ''))
    return;

  if (@EntityType in ('Order', 'PT', 'PickTicket'))
    select @EntityType = 'PT';

  select dbo.fn_Notes_GetNotesAsHTML(@EntityType, @EntityId, @EntityKey, 'Default', @BusinessUnit, @UserId) as Notes

end /* pr_Entity_GetNotes */

Go
