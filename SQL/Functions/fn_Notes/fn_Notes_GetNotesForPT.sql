/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/02/10  TK      fn_Notes_GetNotesAsHTML: replace &amp;lt; & &amp;gt; with < & > respectively
                      fn_Notes_GetNotesForPT: Consider only Active notes (HPI-1365)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Notes_GetNotesForPT') is not null
  drop Function fn_Notes_GetNotesForPT;
Go
/*------------------------------------------------------------------------------
  Func fn_Notes_GetNotesForPT
------------------------------------------------------------------------------*/
Create Function fn_Notes_GetNotesForPT
  (@OrderId        TRecordId,
   @SoldToId       TCustomerId,
   @ShipToId       TShipToId,
   @Operation      TOperation,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
  -------------------------------------------------------
   returns         @ttNotes table(NoteType     TTypeCode,
                                  Note         TNote,
                                  NoteFormat   TDescription,
                                  PrintFlags   TFlags,
                                  VisibleFlags TFlags,
                                  SortSeq      TSortSeq)
as
begin
  declare @vPickTicket TPickTicket;

  /* Get info based upon OrderId */
  if (@OrderId is not null)
    select @SoldToId    = SoldToId,
           @ShipToId    = ShipToId,
           @vPickTicket = PickTicket
    from OrderHeaders
    where (OrderId = @OrderId);

  /* Insert all PT related notes first */
  insert into @ttNotes
    select NoteType, Note, NoteFormat, PrintFlags, VisibleFlags, SortSeq
    from Notes
    where (EntityType = 'PT') and
          ((EntityId   = @OrderId) or (EntityKey = @vPickTicket)) and
          (Status = 'A'/* Active */);

  /* Fetch any notes related to Customer of the PT */
  insert into @ttNotes
    select NoteType, Note, NoteFormat, PrintFlags, VisibleFlags, SortSeq
    from Notes
    where (EntityType = 'Cust') and
          (EntityKey  = @SoldToId) and
          (Status = 'A'/* Active */);

   return;

end /* fn_Notes_GetNotesForPT */

Go
