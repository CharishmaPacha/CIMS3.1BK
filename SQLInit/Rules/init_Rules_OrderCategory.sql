/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/04  MS      return default OrderType (HA-1231)
  2019/05/21  AY      Do not set Order category on Bulk Orders (CID-376)
  2018/12/06  RIA     Made changes for Pick To Cart type (OB2-666)
  2017/03/03  AY      Prevent Order Type change on Bulk & Replenish Orders
  2016/11/27  AY      Changed rules to categorize SingleLine requiring production as PTS (HPI-GoLive)
  2016/11/23  AY      Changed OC1 to not impact Replenish Orders and changes SortSeqno (HPI-GoLive)
  2016/11/16  AY      Changed rules to classify SingleLine Priority orders as PTS
  2016/11/13  AY      Changed rules for single-line as well as categorize PTS/PTC in pre-process for manual waving.
  2016/10/03  TK      Added rules to determine OrderCategory5 (HPI-794)
  2016/09/29  AY      Consider LinesToShip for single line orders and not NumLines (HPI-GoLive)
  2016/09/13  AY      Consider NumLines for single line orders and not SKUsToShip (HPI-GoLive)
  2016/08/09  AY      Change sort sequence of Order Category 1
  2016/07/27  AY      Setup Order Category for Large Orders (HPI-366)
              TK      Added rules for OrderCategory3 (HPI-378)
  2016/06/21  AY      Consider SKUsToShip to determine SingleLine Orders
  2016/05/30  AY      Changed rules for performance optimization
  2016/02/03  KL      Initial version
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
/* Rules for : Rules to determine Order Category 1 */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OrderCategory1';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1: Order category for SingleLine and Regular Orders */
/******************************************************************************/
select @vRuleSetName        = 'OrderCategory1',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Determine Order Category1',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Replenish order: which is Min-Max or On-Demand */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~OrderType~ in (''RU'',''R'', ''RP'', ''B'')',
       @vRuleDescription = 'Do not change Order Category on Bulk & Replenish Orders',
       @vRuleQuery       = 'select ~OrderCategory1~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Order Category determined by Order Type */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~OrderType~ = ''XYZ''',
       @vRuleDescription = 'Order Type of XYZ is Special Order',
       @vRuleQuery       = 'select ''Special Order''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Order Category based upon Account */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~Account~ = ''123''',
       @vRuleDescription = 'Account 123 is Special Account',
       @vRuleQuery       = 'select ''Special Account''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule; Determine Pick To Cart orders by Account  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(~Account~ = ''123'')',
       @vRuleDescription = 'All 123 account Orders to be waved as Pick To Cart',
       @vRuleQuery       = 'select ''Pick To Cart''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Scan To Ship Orders */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(~Account~ = ''123'')',
       @vRuleDescription = 'Some O''Reilly is going to processed as Scan To Ship',
       @vRuleQuery       = 'select ''Scan To Ship''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Single line order. Single Line order with atmost 5 units */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '(~SKUsToShip~ = 1) and (~NumUnits~ <= 5)',
       @vRuleDescription = 'Any Order which has only one SKU and NumUnits not more than 5',
       @vRuleQuery       = 'select ''Single Line''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 20;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Large order  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~LinesToShip~ > 1 and ~NumUnits~ > 350',
       @vRuleDescription = 'Any Order which has NumUnits greater than 350 is a Large Order',
       @vRuleQuery       = 'select ''Large Order''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Pick To Ship */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '((~LinesToShip~ > 1) or (~NumUnits~ > 3))',
       @vRuleDescription = 'Determine if Order is Pick To Ship',
       @vRuleQuery       = 'select ''Pick To Ship''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Pick To Cart */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '((~LinesToShip~ > 1) or (~NumUnits~ > 5))',
       @vRuleDescription = 'Any Order which has NumUnits greater than 5 is Pick To Cart',
       @vRuleQuery       = 'select ''Pick To Cart''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Pick To Cart */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Any Order that does not satisfy above conditions',
       @vRuleQuery       = 'select ''Pick To Cart''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for Order Category2 : VAS Requirements */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OrderCategory2';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'Order Category2',
       @vRuleSetDescription = 'Determine Order Category2',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Rule Condition for VAS Orders  */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Any Order which has a OrderDetail.UDF4 starting with [ is a VAS Order',
       @vRuleQuery       = 'select ''VAS''
                            where (exists
                                     (select *
                                      from OrderDetails OD
                                      where (OD.OrderId = ~OrderId~) and
                                            (OD.UDF5    = ''BDGE'') and
                                            (charindex(''['', OD.UDF4) > 0)
                                      )
                                   )',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Default Orders  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Rule',
       @vRuleQuery       = 'select ''None''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

/******************************************************************************/
/******************************************************************************/
/* Rules for Order Category3 */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'OrderCategory3';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'Order Category3',
       @vRuleSetDescription = 'Determine Order Category3',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Employee Orders  */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Any Order which has a OrderDetail.UDF2 & OrderDetail.UDF3 value requires Employee Label',
       @vRuleQuery       = 'select ''Employee Labels''
                            where (exists
                                     (select count(OD.UDF1)
                                      from OrderDetails OD
                                        join Orderheaders OH on (OD.OrderId = OH.OrderId)
                                      where (OD.OrderId = ~OrderId~) and
                                            (coalesce(nullif(OD.UDF1, ''''), '''') <> '''') and
                                            (coalesce(nullif(OD.UDF2, ''''), '''') <> '''') and
                                            ((OH.ShipFrom = ''DC1'') or
                                             (OH.ShipFrom = ''DC2''))
                                      having count(distinct OD.UDF1) > 2
                                      )
                                   )',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Default Orders  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Rule',
       @vRuleQuery       = 'select ''None''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'

/******************************************************************************/
/******************************************************************************/
/* Rules for Order Category4 */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OrderCategory4';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'Order Category4',
       @vRuleSetDescription = 'Determine Order Category4',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Default Orders  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Rule',
       @vRuleQuery       = 'select ''None''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

/******************************************************************************/
/******************************************************************************/
/* Rules for Order Category5 */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OrderCategory5';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'Order Category5',
       @vRuleSetDescription = 'Determine Order Category5',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Production Orders  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Any Order which has OrderDetail.UDF4 starting with [ is a Production Order',
       @vRuleQuery       = 'select ''Production''
                            where (exists
                                     (select *
                                      from OrderDetails OD
                                      where (OD.OrderId = ~OrderId~) and
                                            (OD.UDF5    <> ''BDGE'') and
                                            (charindex(''['', OD.UDF4) > 0)
                                      )
                                   )',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Default Orders  */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Rule',
       @vRuleQuery       = 'select ''None''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

/******************************************************************************/
/******************************************************************************/
/* Rule Set #3: Order Type for Special order  */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'OrderType';

delete from @RuleSets;
delete from @Rules;

select @vRuleSetName        = 'Order Type',
       @vRuleSetDescription = 'Determine Order Type',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Replenish/Bulk Orders  */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = '~OrderType~ in (''RU'',''R'', ''RP'', ''B'')',
       @vRuleDescription = 'Do not change Order Type of Replenish or Bulk Orders',
       @vRuleQuery       = 'select ~OrderType~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule Condition for Special Orders */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Any Order which has a SKU starting with * is a Special Order',
       @vRuleQuery       = 'select ''G''
                            where (exists
                                     (select *
                                      from OrderDetails OD join SKUs S on OD.SKUId = S.SKUId
                                      where (OD.OrderId = ~OrderId~) and
                                            (S.SKU  like ''*%'')))',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
/* Rule: Return the input OrderType */
/*------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'OrderType: Return input OrderType',
       @vRuleQuery       = 'select ~OrderType~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*------------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

Go
