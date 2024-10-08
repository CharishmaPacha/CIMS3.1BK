/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_EDI_GetProfileName') is not null
  drop Procedure pr_EDI_GetProfileName;
Go
/*------------------------------------------------------------------------------
  Proc pr_EDI_GetProfileName: Procedure to find the applicable profile for the given inputs
------------------------------------------------------------------------------*/
Create Procedure pr_EDI_GetProfileName
  (@EDISenderId      TName,
   @EDIReceiverId    TName,
   @EDITransaction   TName,
   @EDIFileName      TName,
   @EDIProfileName   TName output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vBusinessUnit      TBusinessUnit,

          @vEDIProfileRuleRecId  TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select @vBusinessUnit = TargetValue
  from dbo.fn_GetMappedValues('CIMS', @EDIReceiverID, 'EDI', 'BusinessUnit', 'GetProfile', 'CIMS');

  select @vBusinessUnit = 'NBD';

  /* Check if there is a profile for the particular sender and transaction */
  select @vEDIProfileRuleRecId = RecordId
  from EDIProfileRules
  where (Status         = 'A' /* Active */) and
        (EDISenderId    = @EDISenderId    ) and
        (EDITransaction = @EDITransaction ) and
        (BusinessUnit   = @vBusinessUnit  );

  /* If there is no transaction specific profile for the Sender, then get default profile of sender */
  if (@vEDIProfileRuleRecId is null)
    select @vEDIProfileRuleRecId = RecordId
    from EDIProfileRules
    where (Status         = 'A' /* Active */) and
          (EDISenderId    = @EDISenderId    ) and
          (EDITransaction is null           ) and
          (BusinessUnit   = @vBusinessUnit  );

  /* If there is no transaction/sender specific profile, then get generic profile of the transaction */
  if (@vEDIProfileRuleRecId is null)
    select @vEDIProfileRuleRecId = RecordId
    from EDIProfileRules
    where (Status         = 'A' /* Active */) and
          (EDISenderId    is null           ) and
          (EDITransaction = @EDITransaction ) and
          (BusinessUnit   = @vBusinessUnit  );

  /* If there is no transaction/sender specific profile, then get generic EDI profile */
  if (@vEDIProfileRuleRecId is null)
    select @vEDIProfileRuleRecId = RecordId
    from EDIProfileRules
    where (Status         = 'A' /* Active */) and
          (EDISenderId    is null           ) and
          (EDITransaction is null           ) and
          (BusinessUnit   = @vBusinessUnit  );

  /* Return the profile name */
  select @EDIProfileName = EDIProfileName
  from EDIProfileRules
  where (RecordId = @vEDIProfileRuleRecId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_EDI_GetProfileName */

Go
