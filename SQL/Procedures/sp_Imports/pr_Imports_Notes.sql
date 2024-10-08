/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/22  TD      pr_Imports_Notes- Changes to update EntityLineNo(HPI-2530)
  2018/06/13  OK      pr_Imports_Notes: Excluded to insert Notes to prevent unique constraint error in further updates (S2G-952)
  2018/03/08  TD      pr_Imports_Notes:bug fix - unable to import when we have duplicate records (S2G-378)
  2018/01/19  PK      pr_Imports_Notes: Defaulting status to active if nothing is passed from host.
  2018/01/18  PK      pr_Imports_Notes: Enhanced to consider notes for Receipts.
  2018/01/09  PK      pr_Imports_Notes: Code optimization.
  2017/11/22  PK      Added pr_Imports_ValidateNote, pr_Imports_Notes (CIMS-1722).
                      pr_Imports_ImportRecord: Enhanced to call pr_Imports_Notes (CIMS-1722).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_Notes') is not null
  drop Procedure pr_Imports_Notes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_Notes:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_Notes
  (@xmlData         Xml             = null,
   @documentHandle  TInteger        = null,
   @InterfaceLogId  TRecordId       = null,
   @Action          TFlag           = null,
   @NoteType        TTypeCode       = null,
   @Note            TNote           = null,
   @NoteFormat      TDescription    = null,
   @EntityType      TTypeCode       = null,
   @EntityKey       TEntity         = null,
   @EntityLineNo    THostOrderLine  = null,
   @PrintFlags      TFlags          = null,
   @VisibleFlags    TFlags          = null,
   @Status          TStatus         = null,
   @SortSeq         TSortSeq        = null,
   @BusinessUnit    TBusinessUnit   = null,
   @CreatedDate     TDateTime       = null,
   @ModifiedDate    TDateTime       = null,
   @CreatedBy       TUserId         = null,
   @ModifiedBy      TUserId         = null,
   @HostRecId       TRecordId       = null)
as
  declare @vReturnCode              TInteger,

          /* Table variables for Notes, AuditTrail */
          @ttNoteImports            TNoteImportType,
          @ttNotesValidation        TImportValidationType,
          @ttAuditInfo              TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  if (@xmldata is not null) and (@InterfaceLogId is null)
    begin
      select @InterfaceLogId = Record.Col.value('ParentLogId[1]',  'TRecordId')
      from @xmlData.nodes('//msg/msgHeader') as Record(Col);
    end

  /* Populate the temp table */
  if (@documentHandle is not null)
    begin
      insert into @ttNoteImports (
        InputXML,
        RecordType,
        RecordAction,
        NoteType,
        Note,
        NoteFormat,
        EntityType,
        EntityKey,
        EntityLineNo,
        PrintFlags,
        VisibleFlags,
        Status,
        SortSeq,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId)
      select
        *
      from OPENXML(@documentHandle, '//msg/msgBody/Record[RecordType/text()="NOTE"]', 2) -- condition forces to read only Records with RecordType NOTE
      with (InputXML              nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType            TRecordType,
            Action                TFlag      'Action',
            NoteType              TTypeCode,
            Note                  TNote,
            NoteFormat            TDescription,
            EntityType            TTypeCode,
            EntityKey             TEntity,
            EntityLineNo          THostOrderLine,
            PrintFlags            TFlags,
            VisibleFlags          TFlags,
            Status                TStatus,
            SortSeq               TSortSeq,
            BusinessUnit          TBusinessUnit,
            CreatedDate           TDateTime  'CreatedDate/text()',  -- returns null when CreatedDate is blank node. Acts a NullIf Blank
            ModifiedDate          TDateTime  'ModifiedDate/text()', -- returns null when CreatedDate is blank node. Acts a NullIf Blank
            CreatedBy             TUserId,
            ModifiedBy            TUserId,
            RecordId              TRecordId);
    end
  else
    begin
      insert into @ttNoteImports (
        RecordAction, NoteType, Note, NoteFormat, EntityType, EntityKey, EntityLineNo,
        PrintFlags, VisibleFlags, Status, SortSeq, BusinessUnit, CreatedDate,
        ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action, @NoteType, @Note, @NoteFormat, @EntityType, @EntityKey, @EntityLineNo,
        @PrintFlags, @VisibleFlags, @Status, @SortSeq, @BusinessUnit, @CreatedDate,
        @ModifiedDate, @CreatedBy, @ModifiedBy, @HostRecId;
    end

  /* Update with EntityId of Notes */
  update ttNotes
  set ttNotes.EntityId = case
                           when ttNotes.EntityType = 'PT' /* PickTicket */ then
                             OH.OrderId
                           when ttNotes.EntityType = 'RO' /* Receipt Order */ then
                             RH.ReceiptId
                         end
  from @ttNoteImports ttNotes
    left outer join OrderHeaders OH on (OH.PickTicket      = ttNotes.EntityKey) and
                                       (ttNotes.EntityType = 'PT' /* PickTicket */)
    left outer join ReceiptHeaders RH on (RH.ReceiptNumber = ttNotes.EntityKey) and
                                         (ttNotes.EntityType = 'RO' /* Receipt Order */);

  /* Validating the Notes */
  insert @ttNotesValidation
    exec pr_Imports_ValidateNotes @ttNoteImports;

  /* Set RecordAction for Notes Records  */
  update ttNotes
  set ttNotes.RecordAction = NV.RecordAction
  from @ttNoteImports ttNotes
    join @ttNotesValidation NV on (NV.RecordId = ttNotes.RecordId);

  /* Insert the notes if the records doesn't exists or else if the notes already exists then
     delete all existing notes and re-insert the latest ones */
  if (exists(select * from @ttNoteImports where (RecordAction in ('I' /* Insert */, 'U' /* Update */))))
    begin
      if (exists(select * from @ttNoteImports where (RecordAction = 'U' /* Update */)))
        begin
          /* Capture audit info */
          insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
            select distinct 'Note', EntityId, EntityKey, 'AT_NoteModified', RecordAction, BusinessUnit, ModifiedBy
            from @ttNoteImports
            where (RecordAction = 'U' /* Update */);

          /* Update the records as In-actiave in the database and then re-insert the updated
             version into the database */
          update N1
            set N1.Status = 'I' /* In-active */
          from Notes N1
            join @ttNoteImports N2 on (N1.NoteType   = N2.NoteType) and
                                      (N1.EntityType = N2.EntityType) and
                                      (N1.EntityKey  = N2.EntityKey)
          where (N2.RecordAction = 'U' /* Update */) and (N1.Status = 'A' /* Active */);

          /* Update the RecordAction to Insert after deleting the existing records from notes */
          update @ttNoteImports
            set RecordAction = 'I' /* Insert */
          where (RecordAction = 'U' /* Update */);
        end

      /* Insert the records */
      insert into Notes (
        NoteType,
        Note,
        NoteFormat,
        EntityType,
        EntityId,
        EntityKey,
        EntityLineNo,
        PrintFlags,
        VisibleFlags,
        Status,
        SortSeq,
        BusinessUnit,
        CreatedDate,
        CreatedBy)
      select
        NoteType,
        Note,
        NoteFormat,
        EntityType,
        EntityId,
        EntityKey,
        EntityLineNo,
        PrintFlags,
        VisibleFlags,
        coalesce(nullif(Status, ''), 'A' /* Active */),
        SortSeq,
        BusinessUnit,
        coalesce(CreatedDate, current_timestamp),
        coalesce(CreatedBy, System_User)
      from @ttNoteImports
      where ( RecordAction = 'I' /* Insert */);
    end

  /* process deletes by just marking them as inactive */
  if (exists(select * from @ttNoteImports where (RecordAction = 'D' /* Delete */)))
    begin
      /* Capture audit info */
      /* Excluded inserting Note in a comment field because it is raising unique constraint error if one order has two different types of Notes */
      insert into @ttAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
        select distinct 'Note', EntityId, EntityKey, 'AT_NoteDeleted', RecordAction, BusinessUnit, ModifiedBy
        from @ttNoteImports
        where (RecordAction = 'D' /* Delete */);

      /* Update the deleted records with in-active status */
      update N1
      set N1.Status = 'I' /* Inactive */
      from Notes N1
        join @ttNoteImports N2 on (N1.NoteType   = N2.NoteType) and
                                  (N1.EntityType = N2.EntityType) and
                                  (N1.EntityKey  = N2.EntityKey)
      where (N2.RecordAction = 'D' /* Delete */);
    end

  /* Verify if Audit Trail should be updated */
  if (exists(select * from @ttAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      update @ttAuditInfo
      set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'Note', EntityKey /* PickTicket */, null, null, null, null, null, null, null, null, null, null);

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttNotesValidation;

end /* pr_Imports_Notes */

Go
