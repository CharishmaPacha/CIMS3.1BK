/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/15  MS      pr_Printing_InsertSupplementReport: Added new proc to get append report (CIMSV3-1234)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_InsertSupplementReport') is not null
  drop Procedure pr_Printing_InsertSupplementReport;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_InsertSupplementReport: For some reports, there may be a supplement
   page to be printed and this procedure identifies the records in PrintList
   that have a supplement page and adds them when necessary.

   Procedure will insert the append file for the main RDLC

  #PrintList      : TPrintList
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_InsertSupplementReport
as
  declare @vReturnCode  TInteger,
          @vMessageName TMessageName,
          @vMessage     TDescription;
begin
  SET NOCOUNT ON;

  /* Insert Supplement file if the NumDetails is greaterthan NumRecordsPerPage */
  insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType,
                          DocumentFormat, DocumentSchema, ParentEntityKey, InputRecordId, SortSeqNo)
    select PL.EntityType, PL.EntityId, PL.EntityKey, PL.DocumentClass, PL.DocumentSubClass, PL.DocumentType, PL.DocumentSubType,
           RPT.AdditionalReportName, PL.DocumentSchema, PL.ParentEntityKey, PL.InputRecordId,
           case when dbo.fn_IsInList('A', RPT.PageModel) > 0 then PL.SortSeqNo + 1 else PL.SortSeqNo - 1 end
    from #PrintList PL
      join Reports RPT on (PL.DocumentFormat = RPT.ReportName)
    where (PL.NumDetails > RPT.NumRecordsPerPage);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_InsertSupplementReport */

Go
