/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/13  MS      pr_Notes_GetNotesForEntity: Migrated from S2GCA (HA-1304)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Notes_GetNotesForEntity') is not null
  drop procedure pr_Notes_GetNotesForEntity;
Go
/*------------------------------------------------------------------------------
  Func pr_Notes_GetNotesForEntity: Returns the notes for the given EntityType
    using either the EntityId or the EntityKey
------------------------------------------------------------------------------*/
Create Procedure pr_Notes_GetNotesForEntity
  (@EntityId       TRecordId,
   @EntityKey      TEntityKey,
   @EntityType     TEntity,
   @NoteType       TTypeCode,
   @VisibleFlags   TFlags = '',
   @PrintFlags     TFlags = '',
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
  ---------------------------------
   @Notes          TVarchar output)
as
begin
  create table #Notes(Note varchar(max));

  declare @vNotes       TVarchar;

  /* Attempt to get the notes based on EntityId */
  if (@EntityId is not null)
    insert into #Notes (Note)
      select Note
      from Notes
      where (EntityId     = @EntityId) and
            (EntityType   = @EntityType) and
            (NoteType     = @NoteType) and
            (charindex(coalesce(@VisibleFlags, ''), coalesce(VisibleFlags, '')) >= 0) and
            (charindex(coalesce(@PrintFlags,   ''), coalesce(PrintFlags,   '')) >= 0) and
            (Status = 'A' /* Active */) and
            (BusinessUnit = @BusinessUnit)
      order by SortSeq;

  /* If there are none, then attempt to get the notes based on EntityKey */
  if (@@rowcount = 0) and (@EntityKey is not null)
    insert into #Notes (Note)
      select Note
      from Notes
      where (EntityKey    = @EntityKey) and
            (EntityType   = @EntityType) and
            (NoteType     = @NoteType) and
            (charindex(coalesce(@VisibleFlags, ''), coalesce(VisibleFlags, '')) >= 0) and
            (charindex(coalesce(@PrintFlags,   ''), coalesce(PrintFlags,   '')) >= 0) and
            (Status = 'A' /* Active */) and
            (BusinessUnit = @BusinessUnit)
      order by SortSeq;

  /* stuff all the distinct Notes for different Orders based on ShipmentId */
  select @vNotes = stuff((select distinct ',' + N.Note
                          from #Notes N
                          for XML PATH(''), type).value('.','TVarchar'), 1, 1,'');

  set @Notes = @vNotes;
end /* pr_Notes_GetNotesForEntity */

Go
