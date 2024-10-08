/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetInstructions') is not null
  drop Procedure pr_Packing_GetInstructions;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_GetInstructions:
    This procedure is invoked from V3 UI Packing
    The procedure returns all the packing instructions for the input
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetInstructions
  (@InputXML      TXML,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit)
as
  declare @vInputXml        xml,
          @vSQL             TSQL,
          @vFieldName       TName,
          @vFilterOperation TName,
          @vFilterValue     TName,

          @vDatasetName     TName,
          @vEntity          TName,
          @vEntityType      TName;

  -- declare @ttNotes          TNotes; TODO TODO
begin /* pr_Packing_GetInstructions */
  /* TODO TODO TODO
     Future Implementation..Implement Rules to build Notes for any EntityType, EntityId or EntityKey given in the inputs

  Create temp table
  select * into #ttNotes from @ttNotes;
  */

  select @vInputXml = cast(@InputXml as xml);

  /* Get the filter values */
  select @vFieldName       = Record.Col.value('FieldName[1]',       'TName'),
         @vFilterOperation = Record.Col.value('FilterOperation[1]', 'TName'),
         @vFilterValue     = Record.Col.value('FilterValue[1]',     'TName')
  from @vInputXml.nodes('Root/SelectionFilters/Filter') as Record(Col);

  /* Get the EntityType */
  select @vEntityType = Record.Col.value('EntityType[1]', 'TName')
  from @vInputXml.nodes('Root') as Record(Col);

  if (@vEntityType = 'Packing_Instructions_Order')
    begin
      select * from dbo.fn_Notes_GetNotesForPT(@vFilterValue /* OrderId */, null /* SoldToId */, null/* ShipToId */, 'Packing', @BusinessUnit, @UserId);
    end
  else
    begin
      select @vEntityType = replace(@vEntityType, 'Packing_Instructions_', '');
      select * from dbo.fn_Notes_GetNotesForEntity(@vFilterValue, @vFilterValue, @vEntityType, null /* NoteType */, null /* VisibleFlags */, null /* PrintFlags */, @BusinessUnit, @UserId);
    end

end /* pr_Packing_GetInstructions */

Go
