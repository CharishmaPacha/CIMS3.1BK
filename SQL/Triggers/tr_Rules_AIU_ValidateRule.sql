/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_Rules_AIU_ValidateRule') is not null
  drop Trigger tr_Rules_AIU_ValidateRule;
Go
/*------------------------------------------------------------------------------
  After Insert update Trigger tr_Rules_AIU_ValidateRule to validate the rules being
  inserted or Updated
------------------------------------------------------------------------------*/
Create Trigger [tr_Rules_AIU_ValidateRule] on [Rules]  After Insert, Update
As
  declare @ttRules TEntityKeysTable;
begin
  /* Get all rules being inserted/Updated to be validated */
  insert into @ttRules (EntityId)
    select RuleId
    from Inserted;

  /* Validate SQL Conditions */
  exec pr_Rules_Validate 'Rules', @ttRules;
end /* tr_Rules_AIU_ValidateRule */

Go

