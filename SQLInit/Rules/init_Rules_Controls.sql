/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/16  PK      Generate Temp LPNs: Ported changes done by Pavan (HA-2287)
  2021/02/03  PK      Added rule for Temp Carton(LPN_Temp) (HA-1970)
  2019/03/26  VS      Control Added for Totes (CID-208)
  2018/01/10  TK      Added ReceiveToLPN Category rules (S2G-20)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2015/08/05  VM      Added LPN category rules (FB-288)
  2015/07/29  TK      Initial version
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'ControlCategory';

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
/* Rule Set - LPN Category */ -- Generated LPN to be of which category
/******************************************************************************/
select @vRuleSetName        = 'LPN_Category',
       @vRuleSetDescription = 'Validate the operation for GenerateLPN',
       @vRuleSetFilter      = '~Operation~ =''GenerateLPN''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule # - Generate LPN - Default LPN Category */
select @vRuleDescription = 'Generate shipping LPN',
       @vRuleCondition   = '~LPNType~ = ''S''',
       @vRuleQuery       = 'select ''LPN_Ship''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule # - Generate Totes */
select @vRuleDescription = 'Generate Totes',
       @vRuleCondition   = '~LPNType~ = ''TO''',
       @vRuleQuery       = 'select ''LPN_Tote''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule # - Generate Temp Cartons */
select @vRuleDescription = 'Generate Temp Cartons',
       @vRuleCondition   = '~LPNType~ = ''T''',
       @vRuleQuery       = 'select ''LPN_Temp''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule # - Generate LPN - Default LPN Category */
select @vRuleDescription = 'Get default category for generating LPN',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''LPN''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

/******************************************************************************/
/* Rule Set ReceiveToLPN_Controls */
/******************************************************************************/
select  @vRuleSetType = 'ReceiveToLPN_Controls';

Delete R from Rules R join RuleSets RS on (R.RuleSetName = RS.RuleSetName) where (RS.RuleSetType = @vRuleSetType);
delete from RuleSets where RuleSetType = @vRuleSetType;
delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'ReceiveToLPN_Controls',
       @vRuleSetDescription = 'Determine Control Category for Receive external LPN',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Validate by Warehouse */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Validate scanned LPN by Warehouse',
       @vRuleQuery       = 'select ''ReceiveToLPN_'' + ~Warehouse~',
       @vStatus          = 'I'/* In - Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Validate by Ownership */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Validate scanned LPN by Ownership',
       @vRuleQuery       = 'select ''ReceiveToLPN_'' + ~Ownership~',
       @vStatus          = 'I'/* In - Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Validate by Vendor */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Validate scanned LPN by Vendor',
       @vRuleQuery       = 'select ''ReceiveToLPN_'' + ~VendorId~',
       @vStatus          = 'I'/* In - Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Default control category */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Category',
       @vRuleQuery       = 'select ''ReceiveToLPN_Default''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
