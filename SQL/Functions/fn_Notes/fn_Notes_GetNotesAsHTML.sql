/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this function exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

  2021/06/22  RV      fn_Notes_GetNotesAsHTML: Bug fixed return the html tags in data (OB2-1883)
  2017/02/10  TK      fn_Notes_GetNotesAsHTML: replace &amp;lt; & &amp;gt; with < & > respectively
  2014/01/22  NB      fn_Notes_GetNotesAsHTML: removed font color setting from formatting
  2013/09/16  VM      fn_Notes_GetNotesAsHTML: Return formatted by Operation
  2013/08/03  PKS     fn_Notes_GetNotesAsHTML: Added Style to output HTML Table.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Notes_GetNotesAsHTML') is not null
  drop Function fn_Notes_GetNotesAsHTML;
Go
/*------------------------------------------------------------------------------
  Func fn_Notes_GetNotesAsHTML: Returns all notes for the given Entity as one
    HTML so that it can be displayed or printed as one block.

  Usage: From Packing, invoke with params ('PT', <OrderId>, <PickTicket>, 'OrderPacking', <BU>, <UserId>)
------------------------------------------------------------------------------*/
Create Function fn_Notes_GetNotesAsHTML
  (@EntityType     TEntity,
   @EntityId       TRecordId,
   @EntityKey      varchar(50) /* Have to change the type to TEntityKey */,
   @Operation      TOperation,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
  ----------------------------
   Returns       TNote
as
begin
  declare @ttNotes table(NoteType     TTypeCode,
                         Note         TNote,
                         NoteFormat   TDescription,
                         PrintFlags   TFlags,
                         VisibleFlags TFlags,
                         SortSeq      TSortSeq);

  declare @vSoldToId   TCustomerId,
          @vShipToId   TShipToId,
          @vNotesHTML  TNote;

  /* Fetch SoldToId and ShipToId */
  select @vSoldToId = SoldToId,
         @vShipToId = ShipToId
  from OrderHeaders
  where (OrderId    = @EntityId) and
        (PickTicket = coalesce(@EntityKey, PickTicket));

  if (@EntityType = 'PT')
    insert into @ttNotes
      select * from dbo.fn_Notes_GetNotesForPT(@EntityId /* OrderId */, null /* SoldToId */, null/* ShipToId */, @Operation, @BusinessUnit, @UserId);

  /* convert it into one HTML */
  select @vNotesHTML = case
                         when @Operation = 'Default' then
                           N'<table border="0">' +
                           cast ((select 'font-size:small' as [td/@style],
                                         td = Note,
                                         ''
                                  from @ttNotes
                                  for XML PATH('tr'), TYPE
                           ) AS nvarchar(max) ) +
                           N'</table>'
                         when @Operation = 'OrderPacking' then
                           --N'<H1>Packing Instructions</H1>' +
                           N'<table border="0">' +
                           cast ((select 'font-weight:bold; font-size:medium' as [td/@style],
                                         td = Note,
                                         ''
                                  from @ttNotes
                                  for XML PATH('tr'), TYPE
                           ) AS nvarchar(max) ) +
                           N'</table>'
                       end;

  set @vNotesHTML = replace(replace(@vNotesHTML, '&lt;', '<'), '&gt;', '>');

  return(coalesce(@vNotesHTML, ''));
end /* fn_Notes_GetNotesAsHTML */

Go
