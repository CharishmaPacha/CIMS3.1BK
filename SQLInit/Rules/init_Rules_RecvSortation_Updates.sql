/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/05  MS      Moved custom updates to Rules (JL-286)
  2020/02/25  MS      Initial version (JL-127)
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
/* Rules for RecvSortation Updates to be done */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'RecvSortation_Updates';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rules to sort the Pallets to respective Lanes */
/******************************************************************************/
select @vRuleSetName        = 'RecvSortation_Updates',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Recv Sortation: Updates to be done for Sorting the Pallets to Lanes',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update PalletGroup on #Pallets, to use in Sorting the LPNs */
select @vRuleCondition   = null,
       @vRuleDescription = 'Recv Sortation: Update PalletGroup on #Pallets, to use in Sorting the LPNs',
       @vRuleQuery       = 'Update P
                            set P.UDF1 = '''',  /* No lane assigned yet */
                                P.UDF2 = LTS.PalletGroup
                            from #Pallets P
                              left outer join #LPNsToSort LTS on (P.EntityId = LTS.PalletId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to Sort all Cross Dock Pallets to Lanes 04/06 */
select @vRuleCondition   = null,
       @vRuleDescription = 'Recv Sortation: Sort all Cross Dock Pallets to Lanes 04/06',
       @vRuleQuery       = 'Update #Pallets set UDF1 = ''#'' where UDF2 like ''Y%'' and UDF1 = '''';
                            update #Lanes set Status = ''E'' where Lane in (''L04'', ''L06'');

                            exec pr_Receipts_SortPalletsToLanes ~BusinessUnit~, ~UserId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to sort remaining Cross Dock Pallets to Lane 06 */
select @vRuleCondition   = null,
       @vRuleDescription = 'Recv Sortation: If any remaining Cross Dock Pallets, then sort to Lane 6 only, ignoring the max pallets',
       @vRuleQuery       = 'Update #Pallets set UDF1 = ''#'' where UDF2 like ''Y%'' and UDF1 = '''';
                            update #Lanes set Status = ''E'', MaxPallets = 100 where Lane in (''L06'');

                            exec pr_Receipts_SortPalletsToLanes ~BusinessUnit~, ~UserId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to Sort all Inventory Pallets to Lanes 01-03 & 05 */
select @vRuleCondition   = null,
       @vRuleDescription = 'Recv Sortation: Sort all Inventory Pallets to Lanes 01-03 & 05',
       @vRuleQuery       = 'Update #Pallets set UDF1 = ''#'' where UDF2 like ''N%'' and UDF1 = '''';
                            update #Lanes set Status = ''E'' where Lane not in (''L04'', ''L06'');

                            exec pr_Receipts_SortPalletsToLanes ~BusinessUnit~, ~UserId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to sort to Lane 1 & 2 only, ignoring the max pallets */
select @vRuleCondition   = null,
       @vRuleDescription = 'Recv Sortation: If any remaining inventory Pallets, then sort to Lane 1 & 2 only, ignoring the max pallets',
       @vRuleQuery       = 'Update #Pallets set UDF1 = ''#'' where UDF2 like ''N%'' and UDF1 = '''';
                            update #Lanes set Status = ''E'', MaxPallets = 100 where Lane in (''L01'', ''L02'');

                            exec pr_Receipts_SortPalletsToLanes ~BusinessUnit~, ~UserId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to sort to any lane, ignoring the max pallets */
select @vRuleCondition   = null,
       @vRuleDescription = 'Recv Sortation:  If any remaining Pallets, then sort to any lane, ignoring the max pallets',
       @vRuleQuery       = 'Update #Pallets set UDF1 = ''#'' where UDF1 = '''';
                            update #Lanes set Status = ''E'', MaxPallets = 100;

                            exec pr_Receipts_SortPalletsToLanes ~BusinessUnit~, ~UserId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

/******************************************************************************/
/* Rules to finlaize Updates on LPNs & Pallets  */
/******************************************************************************/
select @vRuleSetName        = 'RecvSortation_FinalizeUpdates',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Recv Sortation: Updates to be done on LPNs & Pallets after LPNs are sorted',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to do required updates on Pallets after Sortation */
select @vRuleCondition   = null,
       @vRuleDescription = 'Recv Sortation: Update required fields on Pallets table',
       @vRuleQuery       = 'Update P1
                            set P1.ReceiptId     = L.ReceiptId,
                                P1.ReceiptNumber = L.ReceiptNumber,
                                P1.Warehouse     = L.DestWarehouse,
                                P1.DestLocation  = P2.UDF1
                            from Pallets P1
                              join #Pallets P2 on (P1.PalletId = P2.EntityId)
                              join LPNs     L  on (P1.PalletId = L.PalletId);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to do required updates on LPNs after Sortation */
select @vRuleCondition   = null,
       @vRuleDescription = 'Recv Sortation: Update required fields on LPNs table',
       @vRuleQuery       = 'Update L
                            set L.DestLocation = P.UDF1
                            from LPNs L join #Pallets P on (L.PalletId = P.EntityId);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

Go
