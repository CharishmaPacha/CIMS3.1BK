/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/22  AY      pr_AMF_EvaluateExecResult: Changed to return success message as well
  2019/06/18  AY      pr_AMF_EvaluateExecResult: Consoldiated procedure to return TransactionFailed, ErrorXML and Data XML (WIP)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_EvaluateExecResult') is not null
  drop Procedure pr_AMF_EvaluateExecResult;
Go
/*------------------------------------------------------------------------------
  pr_AMF_EvaluateExecResult: procedure takes the V2 result XML and parses it to
   check for errors and returns the results
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_EvaluateExecResult
  (@xmlExecResult    xml,
  ------------------------------------------
  @TransactionFailed TInteger output,
  @ErrorXML          TXML     = null output,
  @DataXML           TXML     = null output,
  @InfoXML           TXML     = null output)
as
  declare @vErrorMessage    TMessage,
          @vSuccessMessage  TMessage;
begin /* pr_AMF_EvaluateExecResult */
  /* Parse input for errors */
  select @vErrorMessage = Record.Col.value('ErrorMessage[1]',    'TMessage')
  from @xmlExecResult.nodes('/ERRORDETAILS/ERRORINFO') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlExecResult = null));

  /* Evalaute if Transaction failed */
  select @TransactionFailed = case when (@vErrorMessage is not null) then 1 else 0 end;

  /* Build error XML in AMF Format */
  if (@vErrorMessage is not null)
    begin
      /* Remove any special characters which may mess up the Xml format */
      select @vErrorMessage = replace(replace(replace(@vErrorMessage, '<', ''), '>', ''), '$', '');
      select @ErrorXML      = '<Errors><Messages>' +
                                dbo.fn_AMF_GetMessageXML(@vErrorMessage) +
                              '</Messages></Errors>';
    end

  /* If the transaction was successful, transform V2 format response into AMF Format Info element */
  if (@TransactionFailed <= 0)
    begin
      /* read the success message */
      select @vSuccessMessage = Record.Col.value('(SUCCESSINFO/Message)[1]', 'TDescription')
      from @xmlExecResult.nodes('/SUCCESSDETAILS') as Record(Col);

      select @vSuccessMessage = replace(replace(replace(@vSuccessMessage, '<', ''), '>', ''), '$', '');
      select @InfoXML         = '<Info><Messages>' +
                                   dbo.fn_AMF_GetMessageXML(@vSuccessMessage) +
                                '</Messages></Info>';
    end

  select @DataXML = coalesce(@DataXML, '');
end /* pr_AMF_EvaluateExecResult */

Go

