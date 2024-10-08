/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/15  RV      Carrier_AddressValidation: Added rules to evaluate the address status (BK-997)
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
        @vRuleSetType         TRuleSetType,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,

        @vBusinessUnit        TBusinessUnit,

        @vRuleCondition       TQuery,
        @vRuleQuery           TQuery,
        @vRuleQueryType       TTypeCode,
        @vRuleDescription     TDescription,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/******************************************************************************/
/******************************************************************************/
/* Rules for : Address validation status: To Determine address is valid or not
               based upon the mismatch between the current address and the new
               address returned from the carrier address validation API */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Carrier_AddressValidation';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Carrier AddressValidation */
/******************************************************************************/
select @vRuleSetName        = 'Carrier_UPS_AddressValidation',
       @vRuleSetFilter      = '~Carrier~ = ''UPS''',
       @vRuleSetDescription = 'UPS Address validations to determine based upon the address',
       @vStatus             = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq            = 100; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Address is Invalid when the mismatch between the City, State and Zip */
select @vRuleCondition   = '~AddressValidationStatus~ = ''Valid''',
       @vRuleDescription = 'Address is Invalid when the mismatch between the City, State and Zip',
       @vRuleQuery       = 'select ''Invalid''
                            from Contacts
                            where (ContactId = ~ContactId~) and
                                  ((AddressLine1 <> ~ValidatedAddressLine1~) or
                                   (coalesce(AddressLine2, '''') <> coalesce(~ValidatedAddressLine2~, '''') or
                                   (City  <> ~ValidatedCity~) or
                                   (State <> ~ValidatedState~) or
                                   (Zip   <> ~ValidatedZip~))
                           ',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default to return the input validation status */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default to return the input validation status',
       @vRuleQuery       = 'select ~AddressValidationStatus~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
