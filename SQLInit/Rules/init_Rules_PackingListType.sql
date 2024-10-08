/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/26  AY      Print LPN Packing list for PTS Wave (HPI-2050)
  2018/09/20  NB      changes to separate V3 and V2 RuleSets, Other syntax corrections (CIMSV3-221)
  2018/08/23  RT      Added rule PickTasks_PackingListType to print the Order Details info for PCPK and PTS wave type for ASD Walmart PL(S2GCA-205)
  2018/07/14  RT      Made changes by adding rules to PickTasks_PackingListType to print the Details info for PCPK and PTS wave(S2GCA-61)
  2017/07/12  RV      Packing_PackingListType: Modified rule to do not print packing list if bulk order packing (SRI-793)
  2017/07/03  KL      Added the rule to print the order packing list conditionally
                        for the packed order which is on Bulk wave (SRI-793)
  2016/04/28  TK      Initial version
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
/* Rules for : PackingListType*/
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PackingListType';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - Packing - What type of packing lists to print from Packing */
/******************************************************************************/
select @vRuleSetName        = 'Packing_PackingListType',
       @vRuleSetDescription = 'Packing list type to print from Packing screen',
       @vRuleSetFilter      = '~Operation~ = ''Packing'' and ~Version~ <> ''V3''',
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Print LPN Packing List for each LPN, except for last one */
select @vRuleDescription = 'Print LPN Packing list, except for last carton, print Order packing list when Order is completely packed',
       @vRuleCondition   = 'not ((~PackageSeqNo~ <> 1) and (~OrderStatus~ in (''K'')))',
       @vRuleQuery       = 'select ''LPN''',
       @vStatus          = 'I'; /* In Active */

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Print Order Packing List when Order is packed, otherthan Bulk order packing */
select @vRuleDescription = 'Print Order packing list when Order is completely packed/shipped',
       @vRuleCondition   = '~OrderStatus~ in (''K'', ''S'')',
       @vRuleQuery       = 'select ''ORD''
                            where ~BulkOrderId~ is null',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*---------------------------------------------------------------------------------------*/
/* Rule Set #1 Rules - In the case of Bulk Pull Picking, the Packing List is already Printed
                       Therefore, the Order Packing List must be printed only when
                       there is a difference between the printed Packing List and the contents packed for the order
                       This is mostly the case when the units packed are less the ordered units, and
                       there are no more units remaining to be packed */
/*---------------------------------------------------------------------------------------*/
select @vRuleDescription = 'Print order packing list when there is a difference between units packed and ordered',
       @vRuleCondition   = '~BulkOrderId~ is not null',
       @vRuleQuery       = 'select ''ORD''
                            from OrderDetails OD
                            where (OrderId = ~OrderId~) and (UnitsToAllocate > 0) and
                                  (not exists (select OPD.OrderDetailId
                                               from vwOrderToPackDetails OPD
                                               where (OPD.OrderId = ~BulkOrderId~) and (OPD.UnitsAssigned > 0) and
                                                     (OPD.SKUId in (select SKUId
                                                                     from OrderDetails
                                                                     where OrderId = ~OrderId~))))',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - What type of packing lists to print when printing for LPNs */
/******************************************************************************/
select @vRuleSetName        = 'ShippingDocs_PackingListType',
       @vRuleSetDescription = 'Packing list type to print when printing from Ship Docs screen',
       @vRuleSetFilter      = '~Operation~ = ''ShippingDocs'' and ~Version~ <> ''V3''',
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - No Packing list for replenish orders */
select @vRuleDescription = 'Do not print packing lists for Bulk or Replenish Orders',
       @vRuleCondition   = '~OrderType~ in (''B'', ''RU'', ''RP'')',
       @vRuleQuery       = 'select ''''',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Print ORD Packing List for last LPN on the order when printing from Shipping Docs page */
select @vRuleDescription = 'Print Order Packing list when printing from Shipping Docs for last Carton on the Order when Order is completely packed/loaded/shipped',
       @vRuleCondition   = '(~EntityType~ = ''LPN'') and (~PackageSeqNo~ = ~LPNsAssigned~) and (~OrderStatus~ in (''K'', ''L'', ''S''))',
       @vRuleQuery       = 'select ''ORD''',
       @vStatus          = 'I'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Print ORD Packing List for last LPN on the order when printing from Shipping Docs page
   Currently when user keys in Order in Shipping Docs page, it gets all LPNs on the Orders and tries to print PL
   for each of them. However, we are managing with these rules such that first two LPNs do not print anything
   and for last LPN the ORD packing list is printed
*/
select @vRuleDescription = 'Print Order Packing list when Order is completely packed/loaded/shipped',
       @vRuleCondition   = '(~EntityType~ = ''PickTicket'') and (~OrderStatus~ in (''K'', ''L'', ''S''))',
       @vRuleQuery       = 'select ''ORD''',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Print LPN Packing List when LPN is given */
select @vRuleDescription = 'Always print LPN Packing list when user has given LPN',
       @vRuleCondition   = '(~EntityType~ = ''LPN'')',
       @vRuleQuery       = 'select ''LPN''',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

 /*----------------------------------------------------------------------------*/
/* Rule - Print LPN Packing List for Pick To Ship */
select @vRuleDescription = 'Print LPN Packing list for Pick To Ship Wave when user has given LPN',
       @vRuleCondition   = '(~EntityType~ = ''LPN'') and (~WaveType~ = ''PP'')',
       @vRuleQuery       = 'select ''LPN''',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Print ORD Packing List when order is given */
select @vRuleDescription = 'Print Order Packing list for given Order',
       @vRuleCondition   = '(~EntityType~ = ''PickTicket'')',
       @vRuleQuery       = 'select ''ORD''',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Print ORD Packing List for last LPN on the order */
select @vRuleDescription = 'Print Order Packing list for last Carton on the Order when Order is completely packed/loaded/shipped',
       @vRuleCondition   = '(~PackageSeqNo~ = ~LPNsAssigned~) and (~OrderStatus~ in (''K'', ''L'', ''S''))',
       @vRuleQuery       = 'select ''ORD''',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Print ORD Packing List when order is given */
select @vRuleDescription = 'Print Order Packing list for given Order when Order is completely packed/loaded/shipped',
       @vRuleCondition   = '(~EntityType~ = ''PickTicket'') and (~OrderStatus~ in (''K'', ''L'', ''S''))',
       @vRuleQuery       = 'select ''ORD''',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #3 - What type of packing lists to print from PickTasks */
/******************************************************************************/
select @vRuleSetName        = 'PickTasks_PackingListType',
       @vRuleSetDescription = 'Packing list type to print from Pick Tasks screen',
       @vRuleSetFilter      = '~Operation~ = ''PickTasks'' and ~Version~ <> ''V3''',
       @vSortSeq            = 100, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Print LPN Packing List with Order Details for Piece Pick and PTS Wave for ASD Walmart PL */
select @vRuleCondition   = '~PackageSeqNo~ = 1 and ~BatchType~ in (''PCPK'', ''PTS'')',
       @vRuleDescription = 'Print Order Details for the LPN Packing list for PiecePick and PTS wave types',
       @vRuleQuery       = 'select ''LPNWithODs''
                            from vwOrderHeaders OH
                            where (OH.OrderId  = ~OrderId~) and
                                  (OH.OH_UDF17 = ''ASDWM1'')',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Print LPN Packing List with LPN Details for Piece Pick and PTS Wave*/
select @vRuleCondition   = '~PackageSeqNo~ = 1 and ~BatchType~ in (''PCPK'', ''PTS'')',
       @vRuleDescription = 'Print LPN Details for the LPN Packing list for PiecePick and PTS wave types',
       @vRuleQuery       = 'select ''LPNWithLDs''',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule - Print LPN Packing List */
select @vRuleDescription = 'Print LPN Packing list',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''LPN''',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #1 - Packing - What type of packing lists to print from Packing */
/******************************************************************************/
select @vRuleSetName        = 'SLPacking_PackingListType',
       @vRuleSetDescription = 'Packing list type to print from Packing screen',
       @vRuleSetFilter      = '~Operation~ = ''LPNs'' and ~Version~ <> ''V3''',
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Print LPN Packing List for each LPN, except for last one */
select @vRuleDescription = 'Print LPN Packing list, except for last carton, print Order packing list when Order is completely packed',
       @vRuleCondition   = 'not ((~PackageSeqNo~ <> 1) and (~OrderStatus~ in (''K'')))',
       @vRuleQuery       = 'select ''LPN''',
       @vStatus          = 'I'; /* In Active */

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Print Order Packing List when Order is packed */
select @vRuleDescription = 'Print Order packing list when Order is completely packed/shipped',
       @vRuleCondition   = null, --'~OrderStatus~ in (''K'', ''S'')',
       @vRuleQuery       = 'select ''LPN''',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #1 - Packing - What type of packing lists to print from Packing */
/******************************************************************************/
select @vRuleSetName        = 'SLOrderPacking_PackingListType',
       @vRuleSetDescription = 'Packing list type to print from Packing screen',
       @vRuleSetFilter      = '~Operation~ = ''SingleLineOrderPacking'' and ~Version~ <> ''V3''',
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Print LPN Packing List for each LPN, except for last one */
select @vRuleDescription = 'Print LPN Packing list, except for last carton, print Order packing list when Order is completely packed',
       @vRuleCondition   = 'not ((~PackageSeqNo~ <> 1) and (~OrderStatus~ in (''K'')))',
       @vRuleQuery       = 'select ''LPN''',
       @vStatus          = 'I'; /* In Active */

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Print Order Packing List when Order is packed */
select @vRuleCondition   = '~OrderStatus~ in (''K'', ''G'', ''L'',''S'')',
       @vRuleDescription = 'Print Order packing list when Order is completely packed/shipped',
       @vRuleQuery       = 'select ''ORD''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #3 - Default Rule */
/******************************************************************************/
select @vRuleSetName        = 'DefaultPackingListType',
       @vRuleSetDescription = 'Packing list type to print from Packing screen',
       @vRuleSetFilter      = '~Version~ <> ''V3''',
       @vSortSeq            = 110, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* In-Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set #3 Rules - Print LPN Packing List */
select @vRuleCondition   = null,
       @vRuleDescription = 'Print LPN Packing list',
       @vRuleQuery       = 'select ''LPN''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
