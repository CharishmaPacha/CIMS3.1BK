/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/08  TK      pr_Shipping_BuildAdditionalFields: Changes to Rules_GetRules procedure (CID-833)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_BuildAdditionalFields') is not null
  drop Procedure pr_Shipping_BuildAdditionalFields;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_BuildAdditionalFields: This procedure takes rules xml data and return
    the additional fields for the Carriers based on the rules. For ADSI integration,
    we need to have send some data in name value pairs.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_BuildAdditionalFields
  (@InputXML            TXML,
  ----------------------------------
   @AdditionalFieldsXML TXML output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TDescription,

          @vRuleRecordId            TRecordId,
          @vRuleId                  TRecordId,
          @vRuleSetId               TRecordId,
          @vRuleSetName             TName,

          @vAdditionalKeyValuePairs TName,
          @vAdditionalFieldsXML     TXML;

  declare @ttRules                  TRules;
  declare @ttAdditionalFields       table
          (Name                     varchar(max),
           Value                    varchar(max));

begin /* pr_Shipping_BuildAdditionalFields */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRuleRecordId = 0;

  /* Find the RuleSet to get the AdditionalFields */
  exec pr_RuleSets_Find 'ShippingAdditionalFields', @InputXML, @vRuleSetId output, @vRuleSetName output;

  if (coalesce(@vRuleSetName, '') = '') goto Exithandler;

  insert into @ttRules(RuleId, RuleSetId, RuleSetName, TransactionScope)
    exec pr_Rules_GetRules @vRuleSetName;

  while (exists(select * from @ttRules where RecordId > @vRuleRecordId))
    begin
      select top 1 @vRuleRecordId            = RecordId,
                   @vRuleId                  = RuleId,
                   @vRuleSetId               = RuleSetId,
                   @vAdditionalKeyValuePairs = null
      from @ttRules
      where RecordId > @vRuleRecordId
      order by RecordId;

      /* Process the rule and see if the rule is applicable */
      exec pr_Rules_Process @vRuleSetId, @vRuleId, @InputXML, @vAdditionalKeyValuePairs output;

      /* Split the Name and Value by using delimiter #, as already setup rules for additional key value pairs with delimiter # */
      insert into @ttAdditionalFields (Name, Value)
        select substring(@vAdditionalKeyValuePairs, 1, charindex('#', @vAdditionalKeyValuePairs) - 1),
               substring(@vAdditionalKeyValuePairs, charindex('#', @vAdditionalKeyValuePairs) +1, len(@vAdditionalKeyValuePairs))
    end /* while end */

  set @vAdditionalFieldsXML = (select * from @ttAdditionalFields
                               for xml raw('NameValuePair'), elements );

  set @AdditionalFieldsXML = dbo.fn_XMLNode('ADDITIONALFIELDS', @vAdditionalFieldsXML)

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_BuildAdditionalFields */

Go
