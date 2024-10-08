/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/03  VS      Get the ShipVia based on the OrderTotal weight (BK-465)
  2018/12/27  OK      Added seperate RuleSets and Rules for Replenish and Bulk orders (HPI-2235)
  2017/08/22  YJ      Migrated from Onsite Prod: Set Rules ShipVia_Culvers to inactive (HPI-1558)
  2017/03/20  ??      update to Rule Condition for UPS GROUND (HPI-GoLive)
  2016/12/08  ??      Changed UPS GROUND rule condition (HPI-GoLive)
  2016/11/18  AY      Blank and -1 shipvias to be converted to UPSG (HPI-GoLive)
  2016/10/24  TK      Modified rules for Culvers
  2016/10/22  AY      Initial version
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
/* Rules for : Determine ShipVia for Orders */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'GetShipVia';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set 1: Rules to determine Shipvia for Replenish Orders */
/******************************************************************************/
select @vRuleSetName        = 'ShipVia_DetermineOnPreprocess',
       @vRuleSetDescription = 'Determine ShipVia during Order preprocess',
       @vRuleSetFilter      = '~Operation~ = ''OrderPreprocess''',
       @vSortSeq            = 100,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Replenish orders */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~OrderType~ in (''R'', ''RU'', ''RP'')',
       @vRuleDescription = 'No Shipvia for Replenish Orders',
       @vRuleQuery       = 'select ''''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Bulk Orders */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~OrderType~ = ''B''',
       @vRuleDescription = 'No Shipvia for Bulk Orders',
       @vRuleQuery       = 'select ''''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: select shipVia based on Order Weight */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(coalesce(~ShipVia~, '''') = '''') and (cast(~OrderWeight~ as float) > 100)',
       @vRuleDescription = 'If OrderTotal Weight greater than 100 lbs then ShipVia should be LTL',
       @vRuleQuery       = 'select ''LTL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for UPS GROUND */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~ShipVia~ in (''UPS GROUND'', ''UPSGR'', '''', ''-1'')',
       @vRuleDescription = 'Invalid UPS Ground codes mapped to UPSG',
       @vRuleQuery       = 'select ''UPSG''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for FedEx Ground  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~ShipVia~ in (''FEDEXGR'', ''FEDXGR'', ''FDXGRD'', ''FEDEXG'', ''FEDEXGR'')',
       @vRuleDescription = 'Invalid FedEx Ground codes mapped to FEDXG',
       @vRuleQuery       = 'select ''FEDXG''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for International */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'All Internationals go thru Specials station',
       @vRuleQuery       = 'select ''SPECIAL''
                            from OrderHeaders OH
                              join Contacts CNT on (OH.ShipToId = CNT.ContactRefId)
                           where (OH.OrderId = ~OrderId~) and (CNT.AddressRegion = ''I'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I'/* In-Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to have no further change */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'No change on other ShipVias',
       @vRuleQuery       = 'select ~ShipVia~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set: Change Culvers to high priority if late */
/******************************************************************************/
select @vRuleSetName        = 'ShipVia_Culvers',
       @vRuleSetDescription = 'Late Culvers orders to be upgraded to UPS1',
       @vRuleSetFilter      = '~Account~ = ''09'' and ~Operation~ in (''Packing'', ''ShippingDocs'', ''PickTasks'')',
       @vSortSeq            = 400,
       @vStatus             = 'NA' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: If the order is delayed by more than two days then upgrade to UPS1 */
select @vRuleCondition   = 'dbo.fn_WorkDays(~OrderDate~, null) >= 2',
       @vRuleDescription = 'If Order is more than 2 days old, then ship by UPS1',
       @vRuleQuery       = 'select ''UPS1''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I'/* InActive */,
       @vSortSeq         = 08;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Special Orders are not upgraded to UPS1 */
select @vRuleCondition   = '~OrderCategory1~ in (''Special Order'')',
       @vRuleDescription = 'Special Orders ship as is, no change to ShipVia',
       @vRuleQuery       = 'select ''''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I'/* Active */,
       @vSortSeq         = 09;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: If the order requires VAS & is delayed by more than two days then upgrade to UPS1 */
select @vRuleCondition   = '~OrderCategory1~ not in (''Special Order'') and
                            ~OrderCategory2~ in (''Production'', ''Engraving'') and
                            dbo.fn_OrderDays(~CreatedDate~, ''16:00'') >= 2',
       @vRuleDescription = 'If Order requires Production/Engraving and is more than 2 days old, then ship by UPS1',
       @vRuleQuery       = 'select ''UPS1''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I'/* Active */,
       @vSortSeq         = 10;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: If the order doesn't require VAS & is delayed by more than one day then upgrade to UPS1 */
select @vRuleCondition   = '~OrderCategory1~ not in (''Special Order'') and
                            ~OrderCategory2~ = ''None'' and
                            dbo.fn_OrderDays(~CreatedDate~, ''16:00'') >= 1',
       @vRuleDescription = 'If Order requires no Production/Engraving and is more than a day old, then ship by UPS1',
       @vRuleQuery       = 'select ''UPS1''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I'/* Active */,
       @vSortSeq         = 20;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
