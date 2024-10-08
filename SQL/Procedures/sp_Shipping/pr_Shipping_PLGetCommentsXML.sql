/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/01  RV/RT   pr_Shipping_GetPackingListData: Refactor the code to get the ship label xml and comments xml by
                        adding procedures pr_Shipping_PLGetCommentsXML and pr_Shipping_PLGetShipLabelsXML (HPI-1498)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_PLGetCommentsXML') is not null
  drop Procedure pr_Shipping_PLGetCommentsXML;
Go
/*------------------------------------------------------------------------------
  pr_Shipping_PLGetCommentsXML:

  Returns order comments with respect to the rules.
  We have implemented the new functionality here i.e., Dynamic Notes.
  We return Notes on PackingList based on the NoteType which was given by Client

  Note_PH: Note to print on Header of PL when the NoteType is 'PH'
  Note_PB: Note to print on Body   of PL when the NoteType is 'PB'
  Note_PF: Note to print on Footer of PL when the NoteType is 'PF'
  PL1 to PL5: These are specific for PLs because sometimes we have to print some specific notes on PLs.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_PLGetCommentsXML
  (@xmlData           TXML,
   @Commentsxml       TXML output)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vMessage      TDescription,
          @vNote_PH      TVarchar,
          @vNote_PB      TVarchar,
          @vNote_PF      TVarchar,
          @vPL1          TVarchar,
          @vPL2          TVarchar,
          @vPL3          TVarchar,
          @vPL4          TVarchar,
          @vPL5          TVarchar;

  declare @ttNotes  table (NoteType       TTypeCode,
                           Note           TNote,
                           EntityType     TEntity,
                           EntityId       TRecordId,
                           EntityKey      TEntityKey,
                           PrintFlags     TPrintFlags,
                           VisibleFlags   TFlags);
begin
  SET NOCOUNT ON;

  /* select to create table structure for #ttNotes */
  select * into #ttNotes from @ttNotes

  /* Update Packing List comments - eventually, there could be several comments i.e on header, footer etc.
     and hence we are numbering them as Commments1 etc. */
  exec pr_RuleSets_ExecuteRules 'PackingList_Comments1' /* RuleSetType */, @xmlData;

  /* Returning the dataset from temp table by formating the NoteType */
  select @vNote_PH = PH,
         @vNote_PB = PB,
         @vNote_PF = PF,
         @vPL1     = PL1,
         @vPL2     = PL2,
         @vPL3     = PL3,
         @vPL4     = PL4,
         @vPL5     = PL5
  from (select NoteType,
               Note,
               EntityType,
               EntityId,
               EntityKey,
               PrintFlags,
               VisibleFlags
        from #ttNotes) up
  PIVOT (max(Note) For NoteType in (PH, PB, PF, PL1, PL2, PL3, PL4, PL5)) as pvt;

  /* To build the comments xml */
  set @Commentsxml = dbo.fn_XMLNode('Comments',
                        dbo.fn_XMLNode('Note_PH',     @vNote_PH) +
                        dbo.fn_XMLNode('Note_PB',     @vNote_PB) +
                        dbo.fn_XMLNode('Note_PF',     @vNote_PF) +
                        dbo.fn_XMLNode('PL1',         @vPL1    ) +
                        dbo.fn_XMLNode('PL2',         @vPL2    ) +
                        dbo.fn_XMLNode('PL3',         @vPL3    ) +
                        dbo.fn_XMLNode('PL4',         @vPL4    ) +
                        dbo.fn_XMLNode('PL5',         @vPL5    ));

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_PLGetCommentsXML */

Go
