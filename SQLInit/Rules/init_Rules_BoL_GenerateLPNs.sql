/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/21  SK/AY   Updated the group criteria (HA-2676)
  2021/02/03  RT      Initial version (FB-2225)
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
/* Rules for : Get the LPNs Info for the assosiated BoL */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'BoLLPNs';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Update the customized details on the LPNs assosiated with the BoLs */
/******************************************************************************/
select @vRuleSetName        = 'BoLLPNs_Updates',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update the fields on BoL LPNs',
       @vStatus             = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq            = 200;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Update LPN and associated info.
     BoD: For some customers typically we summarize by CustPO + Dept and Ship To Store,
     BCD: Typically we summarize by Load */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~Account~ in (''ABC'')',
       @vRuleDescription = 'Group Criteria: Update any customized details on the BoL LPNs',
       @vRuleQuery       = 'Update BL
                            set BOD_Reference1    = OH.UDF3  /* Dept. Number */,
                                BOD_Reference2    = OH.ShipToStore /* DC */,
                                BOD_Reference3    = right(B.VICSBoLNumber, 7),
                                BOD_GroupCriteria = OH.CustPO + coalesce (OH.UDF3, '''') + coalesce(OH.ShipToStore, ''''),
                                BOD_ShipperInfo   = ''DEPT: '' + OH.UDF3 + '' DC: '' + OH.ShipToStore + '' DTL: '' + right(B.VICSBoLNumber, 7)
                            from #BoLLPNs BL
                              join OrderHeaders OH on (OH.OrderId = BL.OrderId)
                              left outer join Shipments S on (BL.ShipmentId = S.ShipmentId)
                              left outer join BoLs B on (B.BoLId = S.BoLId);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Update LPN and associated info.
     For BOD typically we summarize by CustPO
     For BCD typically we summarize by Load */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Group Criteria: Just Cust PO',
       @vRuleQuery       = 'Update BL
                            set CustPO            = case when ~BOD_GroupCriteria~ = ''CustPO'' then OH.CustPO else ''Multiple POs'' end,
                                BOD_Reference1    = '''',
                                BOD_Reference2    = '''',
                                BOD_Reference3    = '''',
                                BOD_GroupCriteria = case when ~BOD_GroupCriteria~ = ''CustPO'' then OH.CustPO else ''Multiple POs'' end,
                                BOD_ShipperInfo   = ''''
                            from #BoLLPNs BL join OrderHeaders OH on (OH.OrderId = BL.OrderId)
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
