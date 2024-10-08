/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_EDI_SetupProfileMap') is not null
  drop Procedure pr_EDI_SetupProfileMap;
Go
/*------------------------------------------------------------------------------
  Proc pr_EDI_SetupProfileMap:
------------------------------------------------------------------------------*/
Create Procedure pr_EDI_SetupProfileMap
  (@EDIProfileName   TName,
   @EDITransaction   TName,
   @EDIProcessMap    TEDIProcessMap READONLY,
   @Action           TAction,
   @BusinessUnit     TBusinessUnit)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vEDIMapCriteriaRecId  TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Validations */

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* If there is a request to delete the map, then just change the status and rename the profile so
     that we don't loose it forever! */
  if (@Action = 'D' /* Delete */) or (@Action = 'R' /* Replace */)
    update EDIProfileMaps
    set Status       = 'I',
        EDIProfileName += cast(current_timestamp as varchar),
        Archived     = 'Y'
    where (EDIProfileName = @EDIProfileName) and
          (EDITransaction = @EDITransaction) and
          (BusinessUnit   = @BusinessUnit);

  if (@Action = 'A' /* Add */) or (@Action = 'R' /* Replace */)
    begin
      insert into EDIProfileMaps (EDIProfileName, EDITransaction, ProcessAction, EDISegmentId, EDIElementId, ProcessConditions,
                                 CIMSXMLPath, CIMSXMLField, CIMSFieldName, DefaultValue, BusinessUnit, SortSeq)
        select @EDIProfileName, @EDITransaction, ProcessAction, SegmentId, ElementId, ProcessConditions,
               CIMSXMLPath, CIMSXMLField, CIMSFieldName, DefaultValue, @BusinessUnit, RecordId
        from @EDIProcessMap
        order by RecordId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_EDI_SetupProfileMap */

Go
