/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/17  RV      Revised the rules to retrieve active shipping accounts (CIMSV3-3395)
  2018/02/09  RV      Removed double quotations for dynamic variable (S2G-110)
  2017/04/18  NB      Added Rule to read ADSI specific account(CIMS-1259)
  2017/03/28  NB      Included ADSI into Rule Set filter(CIMS-1259)
  2016/06/13  KN      Added: DHL related code (NBD-554).
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2016/03/18  VM      Bug-fix: Cannot insert value into RuleSetId as it is identity column.
  2016/02/26  TK      Initial version
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'ShippingAccounts';

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
/* Rule Set #1 - UPS/FedEx/USPS Carrier */
/******************************************************************************/
select @vRuleSetDescription = 'Verify if the shipping account is  UPS/ FedEx, etc',
       @vRuleSetName        = 'ShippingAccountDetails',
       @vRuleSetFilter      = '~Carrier~ in (''UPS'', ''FEDEX'', ''USPS'', ''DHL'', ''Generic'')',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule 1.1 - ShipToId as AccountName */
select @vRuleDescription = 'Get shipping account name based on ShipToId ',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ~Carrier~ and ShippingAcctName like ''ShipTo_'' + ~ShipToId~ and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.2 - SoldToId as AccountName */
select @vRuleDescription = 'Get shipping account name based on SoldToId',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ~Carrier~ and ShippingAcctName like ''SoldTo_'' + ~SoldToId~ and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.3 - Order Account as AccountName */
select @vRuleDescription = 'Get shipping account name based on Order Account',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ~Carrier~ and ShippingAcctName like ''Account_'' + ~Account~ and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.4 - Order AccountName as AccountName */
select @vRuleDescription = 'Get shipping account name based on Order AccountName',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ~Carrier~ and ShippingAcctName like ''AccountName_'' + ~AccountName~ and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName,RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.80 -  Ownership as AccountName */
select @vRuleDescription = 'Get shipping account name based on Ownership',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ~Carrier~ and ShippingAcctName like ''Owner_'' + ~Ownership~ and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq          = 80;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.81 - Warehouse as AccountName */
select @vRuleDescription = 'Get shipping account name based on Warehouse',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ~Carrier~ and ShippingAcctName = ''WH_'' + ~Warehouse~ and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 81;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.98 - Penultimate rule is to use the default account information of the ShipVia */
select @vRuleDescription = 'Get default shipping account name based on ShipVia',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ~Carrier~ and ShipVia = ~ShipVia~ and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 98;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule 1.99 - Final rule is to use the default account information of the carrier */
select @vRuleDescription = 'Get default shipping account name based on carrier only',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ~Carrier~ and ShipVia is null and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;
/*----------------------------------------------------------------------------*/
/* Rule: Default account for all Carriers */
select @vRuleCondition   = '~Carrier~ in (''UPS'', ''FEDEX'', ''USPS'', ''DHL'', ''Generic'')',
       @vRuleDescription = 'Use ADSI Account for Shipping',
       @vRuleQuery       = 'select ShippingAcctName
                            from ShippingAccounts
                            where Carrier = ''ADSI'' and Status = ''A''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 100;

insert into @Rules (RuleSetName, RuleCondition, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
