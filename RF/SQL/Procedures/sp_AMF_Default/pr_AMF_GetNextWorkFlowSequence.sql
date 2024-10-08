/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_AMF_GetNextWorkFlowSequence: modified to send FormSequence in output,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_GetNextWorkFlowSequence') is not null
  drop Procedure pr_AMF_GetNextWorkFlowSequence;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_GetNextWorkFlowSequence:

  Processes the input xml
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_GetNextWorkFlowSequence
  (@DataXML       TXML,
   @WorkFlowXML   TXML output)
as
  declare @vDataXML                 xml,
          @vWorkFlowXML             xml,
          @vCurrentWorkFlowName     TName,
          @vCurrentFormName         TName,
          @vNextFormName            TName,
          @vWorkFlowName            TName,
          @vFormName                TName,
          @vFormSequence            TSortSeq,
          @vNextFormSequence        TSortSeq,
          @vFormCondition           TQuery,
          @vFormConditionDataXML    TXML,
          @vFormConditionResult     TResult;
begin /* pr_AMF_GetNextWorkFlowSequence */
  select @vDataXML      = convert(xml, @DataXML),
         @vWorkFlowXML  = convert(xml, @WorkFlowXML);

  select @vFormConditionDataXML = replace(@DataXML, 'Data>', 'RootNode>');

  /* read ui information */
  select @vCurrentWorkFlowName = Record.Col.value('WorkFlowName[1]', 'TName'),
         @vCurrentFormName     = Record.Col.value('FormName[1]',     'TName')
  from @vWorkFlowXML.nodes('UIInfo') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vWorkFlowXML = null ) );

  select @vFormSequence = 0, @vNextFormName = null;
  while (exists (select RecordId from AMF_WorkFlowDetails where WorkFlowName = @vCurrentWorkFlowName and FormSequence > @vFormSequence))
    begin
      select top 1 @vFormSequence  = FormSequence,
                   @vFormCondition = FormCondition,
                   @vFormName      = FormName,
                   @vWorkFlowName  = WorkFlowName
      from AMF_WorkFlowDetails
      where (WorkFlowName = @vCurrentWorkFlowName) and (FormSequence > @vFormSequence)
      order by FormSequence;

      if (@vFormCondition is null) continue; /* Continue to next condition */

      /* Build the condition with the values from the Input Data */
      select @vFormCondition = dbo.fn_SubstituteXMLValues(@vFormCondition, @vFormConditionDataXML);

      /* Verify Condition */
      if (@vFormCondition is not null) exec pr_ExecuteSQL @vFormCondition, @vFormConditionResult output;

      if (@vFormConditionResult = '0' /* Condition successful */)
        begin
          select @vNextFormName     = @vFormName,
                 @vNextFormSequence = @vFormSequence;
          break;
        end
    end

  if (@vNextFormName is not null)
    begin
      select @vWorkFlowXML = (select @vCurrentWorkFlowName as WorkFlowName, @vNextFormName as FormName,  @vNextFormSequence as FormSequence
                              for xml raw('UIInfo'), elements)
      select @WorkFlowXML = convert(varchar(max), @vWorkFlowXML);
    end

end /* pr_AMF_GetNextWorkFlowSequence */

Go

