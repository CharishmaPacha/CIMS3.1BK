/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/12  RKC    Initial revision. (HA-890)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* NoteType: PF */
/*------------------------------------------------------------------------------*/
declare @NoteType   TTypeCode = 'PF',
        @EntityType TEntity   = 'ShipFrom';
delete from Notes where NoteType = 'PF';

insert into Notes
                 (NoteType,    Note,  EntityType,        EntityId, EntityKey, PrintFlags, VisibleFlags, Status, SortSeq, BusinessUnit)
          select  @NoteType,   'Return Instruction:||Returns sent back to the manufacturer or any other address will result in delayed processing and restock fees.||For Our return Policy: www.scrubsgiant.com|Exchange/return Form: support@scrubsgiant.com| Or Contact us @ 866-422-7278 for more information on returns or exchanges.|',
                                      @EntityType,       null,     '08',      'P',        'O',          'A',    1,       BusinessUnit from vwBusinessUnits

--select @EntityType = 'ShipToState';
/* The following Note is printing only when ShipToState is 'CA' */
---insert into Notes
--                 (NoteType,    Note,  EntityType,        EntityId, EntityKey, PrintFlags, VisibleFlags, Status, SortSeq, BusinessUnit)
--          select  @NoteType,   'WARNING !!!: This product may contain a chemical known to the state of California to cause cancer or birth defects or other reproductive harm.',
--                                      @EntityType,       null,     'CA',       'P',        'O',          'A',    26,      BusinessUnit from vwBusinessUnits

Go
