/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_EDI_ManageProfileRule') is not null
  drop Procedure pr_EDI_ManageProfileRule;
Go
/*------------------------------------------------------------------------------
  Proc pr_EDI_ManageProfileRule: Procedure to add/Update/delete profile rules
------------------------------------------------------------------------------*/
Create Procedure pr_EDI_ManageProfileRule
  (@EDISenderId      TName,
   @EDITransaction   TName,
   @EDIDirection     TName,
   @EDIProfileName   TName,
   @Action           TAction,
   @BusinessUnit     TBusinessUnit)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vEDIProfileRuleRecId  TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Check if the mapping already exists */
  select @vEDIProfileRuleRecId = RecordId
  from EDIProfileRules
  where (EDISenderId     = @EDISenderId) and
        (coalesce(EDITransaction, '') = coalesce(@EDITransaction, ''));

  /* Validations */
  if (@Action = 'A' /* Add */) and (@vEDIProfileRuleRecId is not null)
    select @vMessageName = 'EDIProfileRuleAlreadyExists'

  if (@vMessageName is not null)
    goto ErrorHandler;

  if (@Action = 'D' /* Delete */)
    --delete from EDIProfileRules where RecordId = @vEDIProfileRuleRecId;
    update EDIProfileRules
    set Status          = 'O' /* Obsolete */,
        EDIProfileName += cast(getdate() as varchar(20))
    where RecordId = @vEDIProfileRuleRecId;

  /* Insert or Update the criteria */
  if (@Action = 'A' /* Add */) or
     (@Action = 'U' and @vEDIProfileRuleRecId is null)
    insert into EDIProfileRules (EDISenderId, EDITransaction, EDIDirection, EDIProfileName, BusinessUnit)
      select @EDISenderId, @EDITransaction, @EDIDirection, @EDIProfileName, @BusinessUnit;

  if (@Action = 'U' /* Update */)
    update EDIProfileRules
    set EDIProfileName = @EDIProfileName
    where (RecordId = @vEDIProfileRuleRecId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_EDI_ManageProfileRule */

Go
