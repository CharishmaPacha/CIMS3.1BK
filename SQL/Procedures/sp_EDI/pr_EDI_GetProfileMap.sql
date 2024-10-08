/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/01/07   NB      pr_EDI_GetProfileMap - Changes to read EDIDirection of the Profile
                         instead of hardcoding(NBD-43)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_EDI_GetProfileMap') is not null
  drop Procedure pr_EDI_GetProfileMap;
Go
/*------------------------------------------------------------------------------
  Proc pr_EDI_GetProfileMap: Procedure to find the applicable profile for the given inputs
------------------------------------------------------------------------------*/
Create Procedure pr_EDI_GetProfileMap
  (@EDISenderId      TName,
   @EDIReceiverId    TName,
   @EDITransaction   TName,
   @EDIFileName      TName,
   @EDIMap           TVarchar output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vBusinessUnit      TBusinessUnit,
          @vEDIDirection      TName,
          @vEDIProfileName    TName;

  declare @ttEDIPM              TEDIProcessMap;

  declare @ttEDIMap table
  (
    ProcessAction      TAction,

    SegmentId          TName,
    ProcessConditions  TQuery,
    ElementId          TName,
    CIMSXMLField       TName,
    CIMSFieldName      TName,
    DefaultValue       TControlValue,
    CIMSXMLPath        TName,

    EDIElementDesc     TDescription,
    ProcessSeq         TInteger,

    RecordId           TRecordId identity (1,1),
    Primary Key        (RecordId)
  );

begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the profile to use for the given inputs */
  exec pr_EDI_GetProfileName @EDISenderId, @EDIReceiverId, @EDITransaction, @EDIFileName,
                             @vEDIProfileName output;

  /* Read EDIDirection from ProfileRules - This is needed to be sent in the result */
  select Top 1 @vEDIDirection = EDIDirection
  from EDIProfileRules
  where (EDIProfileName = @vEDIProfileName);

  /* Insert the EDI map records
     The CIMSXMLPath is unknown to users and hence we set the path when data is returned instead of
     setting it in the data */
  insert into @ttEDIMap (ProcessSeq, ProcessAction, SegmentId, ProcessConditions, ElementId, CIMSXMLPath,
                        CIMSXMLField, DefaultValue, CIMSFieldName, EDIElementDesc)
    select SortSeq*100, ProcessAction, EDISegmentId, ProcessConditions, EDIElementId,
           case when EDISegmentId <> 'ST' and ProcessAction = 'AddXMLField' then 'msg/msgBody/Record'
                when ProcessAction = 'NEWREC' then 'msg/msgBody/Record'
                else CIMSXMLPath
           end,
           CIMSXMLField, DefaultValue, CIMSFieldName, EDIElementDesc
    from EDIProfileMaps
    where (Status = 'A' /* Active */) and
          (EDIProfileName = @vEDIProfileName) and
          (ProcessAction <> 'TEMPLATE')
    order by SortSeq;

  /* Insert the ISA, GS and BCT segment template
     When copying the template records into the original take care of the following
     -- Check: Process condition has to be copied
     -- XMLPath: To be returned accurately
     -- DefaultValue: replace tags
  */
  insert into @ttEDIMap (ProcessSeq, ProcessAction, SegmentId, ProcessConditions, ElementId, CIMSXMLPath,
                        CIMSXMLField, DefaultValue, CIMSFieldName, EDIElementDesc)
    select E1.SortSeq*100+E2.SortSeq, E2.ProcessAction, E2.EDISegmentId,
           case when E2.EDISegmentId = 'ST' and E2.ProcessAction = 'Check' then E1.ProcessConditions
                else E2.ProcessConditions
           end /* Process Conditions */,
           E2.EDIElementId,
           case when E2.EDISegmentId = 'ST' and E2.ProcessAction = 'AddXMLField' then 'msg/msgHeader'
                else E2.CIMSXMLPath
           end /* CIMS XML Path */,
           E2.CIMSXMLField,
           case when E2.EDISegmentId = 'ST' and E2.ProcessAction = 'AddXMLField' then
                  replace(E2.DefaultValue, '<Import>', E1.DefaultValue)
                else
                  E2.DefaultValue
           end,
           E2.CIMSFieldName,
           E2.EDIElementDesc
    from EDIProfileMaps E1 join EDIProfileMaps E2 on (E1.EDIProfileName = @vEDIProfileName  ) and
                                                     (E2.EDIProfileName = 'StandardSegments') and
                                                     (E1.EDISegmentId   = E2.EDISegmentId   )
    where (E1.Status = 'A' /* Active */) and
          (E1.ProcessAction = 'TEMPLATE')
    order by E1.SortSeq;

  select * from @ttEDIMap order by ProcessSeq;

  --select 'Import' EDIDirection, '832' EDITransaction, * from @ttEDIMap
  select RecordId, ProcessSeq, ProcessAction, upper(@vEDIDirection) EDIDirection, @EDITransaction EDITransaction, SegmentId, ElementId, ProcessConditions,
  CIMSXMLPath, CIMSXMLField, DefaultValue, CIMSFieldName CIMSField, EDIElementDesc from @ttEDIMap
  order by ProcessSeq
  for XML Raw('EDIProcessDetails') , TYPE, ELEMENTS XSINIL, ROOT('EDIProcess'), XMLSCHEMA;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_EDI_GetProfileMap */

Go
