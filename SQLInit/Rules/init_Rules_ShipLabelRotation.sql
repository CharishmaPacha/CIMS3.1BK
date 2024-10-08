/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/03  RV      Made changes to decide is carrier small package or not based on the IsSmallPackageCarrier flag
                        instead of mention each carrier (S2GCA-236)
  2018/04/25  RV      Initial version (S2G-699)
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'ShipLabelRotation';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;

  declare @vRecordId           TRecordId,
          @vRuleSetId          TRecordId,
          @vRuleSetName        TName,
          @vRuleSetDescription TDescription,
          @vRuleSetFilter      TQuery,

          @vBusinessUnit       TBusinessUnit,

          @vRuleCondition      TQuery,
          @vRuleQuery          TQuery,
          @vRuleDescription    TDescription,

          @vSortSeq            TSortSeq,
          @vStatus             TStatus;

  declare @RuleSets            TRuleSetsTable,
          @Rules               TRulesTable;

/******************************************************************************/
/* Rule Set #1 - Ship Label Rotation: This returns the label rotation value to rotate
   Acceptable rotation values: Rotation_0_Degrees:   Rotate   0 degrees
                               Rotation_90_Degrees:  Rotate  90 degrees
                               Rotation_180_Degrees: Rotate 180 degrees
                               Rotation_270_Degrees: Rotate 270 degrees
                               Empty (''): Don't required rotate */
/******************************************************************************/
select @vRuleSetName        = 'Ship Label Rotation',
       @vRuleSetDescription = 'Get ship label rotation value to rotate for small package carriers',
       @vRuleSetFilter      = '~IsSmallPackageCarrier~ = ''Y''',
       @vSortSeq            = null,
       @vStatus             = 'A';

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule 1.1 - Rotate 90 degrees for XYZ and XYZ waves for UPS, USPS and DHL */
select @vRuleCondition   = '~BatchType~ in (''XYZ'', ''XYZ'') and ~Carrier~ in (''UPS'', ''USPS'', ''DHL'')',
       @vRuleDescription = 'Rotate 90 degrees for XYZ and XYZ waves for UPS, USPS and DHL',
       @vRuleQuery       = 'select ''Rotation_90_Degrees''',
       @vSortSeq         = 1,
       @vStatus          = 'A';

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription,  @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.1 - Rotate 0 degrees for non automation waves PTL and PTLC for FEDEX */
select @vRuleCondition   = '~BatchType~ in (''XYZ'', ''XYZ'') and ~Carrier~ = ''FEDEX''',
       @vRuleDescription = 'Rotate 0 degrees for XYZ and XYZ waves for FEDEX',
       @vRuleQuery       = 'select ''Rotation_0_Degrees''',
       @vSortSeq        += 1,
       @vStatus          = 'A';

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription,  @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.1 - Rotate not required for some wave types */
select @vRuleCondition   = '~BatchType~ in (''XYZ'', ''XYZ'', ''XYZ'')',
       @vRuleDescription = 'Rotation not required for some wave types',
       @vRuleQuery       = 'select ''''',
       @vSortSeq        += 1,
       @vStatus          = 'A';

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription,  @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

  ----------------------------------------------------------------------------*/
/* Rule 1.2 - Default to rule to do not required to rotate */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule - No Rotation required',
       @vRuleQuery       = 'select ''''',
       @vSortSeq        += 1,
       @vStatus          = 'A';

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription,  @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
