/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_Rules_AIU_ValidateRuleSets') is not null
  drop Trigger tr_Rules_AIU_ValidateRuleSets;
Go
/*------------------------------------------------------------------------------
  After Insert update Trigger tr_Rules_AIU_ValidateRuleSets to validate the RuleSets
  being inserted or Updated
------------------------------------------------------------------------------*/
Create Trigger [tr_Rules_AIU_ValidateRuleSets] on [RuleSets]  After Insert, Update
As
  declare @ttRuleSets TEntityKeysTable;
begin
  /* Get all rules being inserted/Updated to be validated */
  insert into @ttRuleSets (EntityId)
    select RuleSetId
    from Inserted;

  /* Validate SQL Conditions */
  exec pr_Rules_Validate 'RuleSets', @ttRuleSets;
end /* tr_Rules_AIU_ValidateRuleSets */

Go

