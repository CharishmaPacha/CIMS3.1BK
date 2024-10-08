/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/16  RT      Rules to get the Report Name to print the UCC Labels on Packing List (S2GCA-629)
  2018/07/24  RT      Made changes in the Rules for PCPK, PTS and LTL Wave Types to print Order PL and LPN PL for ASD(S2GCA-85)
  2018/07/12  RT      Reverted changes and Added Rules to PCPK and PTS Wave Types with respect to Packing List types (S2GCA-61)
  2018/06/07  RV      Added rules to PackingList_Info1 to send dynamic height based upon the details count (S2G-927)
  2018/04/24  RT      Added TSC drop ship packing list rules (SRI-860)
  2018/04/09  CK/RT   Added LPN Packing list Rules for Dungarees drop Ship customer (SRI-819)
  2018/04/05  VM      Organize file with adding descriptions and setup PTL/Auto for order PL (S2G-573)
  2018/03/31  TK      Changes to print PTL wave packing list (S2G-535)
  2016/09/08  KL      Changed the rule query for PackingList_GROUPONGoods
  2016/09/08  PSK     Added GROUPON goods related code.(FsB-748)
  2016/06/13  KN      Added: DHL related code (NBD-554)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2016/03/15  KL      Added rule for Working Person's packing list (SRI-515).
  2015/08/12  RV      Added rules for SAMS Customers (FB-286)
  2015/03/11  DK      Added rules to print ReturnPackingList.
  2015/02/26  AK      Splitted Rules,RuleSets(Init_Rules) based on RuleSetType.
  2014/12/19  AK      Changes made to control data using procedure
  2014/11/06  SV      Added packing list and ship label rules for Cabela's drop Ship customer.
  2014/05/13  SV      Initial version
------------------------------------------------------------------------------*/

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
/* Rules for : PackingList */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PackingList';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - LPN PackingList */
/******************************************************************************/
select @vRuleSetName        = 'PackingList_LPN',
       @vRuleSetDescription = 'RuleSet for LPN Packing list',
       @vRuleSetFilter      = '~PackingListType~ = ''LPN'' or (~DocumentType~ = ''PL'' and ~EntityType~ = ''LPN'')',
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Packing List by Owner */
select @vRuleDescription = 'Packing list rule by Owner',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''PackingList_'' + OH.Ownership
                           from OrderHeaders OH
                           where (OH.OrderId  = ~OrderId~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I'; /* Active */

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Packing List for PTL wave by Owner */
select @vRuleDescription = 'Packing list for PTL wave types by Owner',
       @vRuleCondition   = '~WaveType~ = ''PTL''',
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_WithShipLabel_'' + ~Ownership~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Packing List for Piece Pick and Pick To Ship wave by Owner */
select @vRuleDescription = 'Packing list for PiecePick wave types by Owner',
       @vRuleCondition   = '~WaveType~ in (''PCPK'', ''PTS'')',
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_'' + ~Ownership~ + ''_LPN''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Packing List for LTL wave by Owner */
select @vRuleDescription = 'Packing list for LTL wave types by Owner',
       @vRuleCondition   = '~WaveType~ in (''LTL'')',
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_'' + ~Ownership~ + ''_ORD''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Packing List for Automation wave by Owner */
select @vRuleDescription = 'Packing list for AUTO wave types by Owner',
       @vRuleCondition   = '~WaveType~ = ''AUTO''',
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_Auto_'' + ~Ownership~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Generic for the particular business */
select @vRuleDescription = 'Print generic packing list for the BusinessUnit',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 96;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Generic */
select @vRuleDescription = 'Print CIMS generic packing list',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''PackingList_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 97;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - LPNWithLDs PackingList */
/******************************************************************************/
select @vRuleSetName        = 'PackingList_LPNWithLDs',
       @vRuleSetDescription = 'RuleSet for LPN Details Packing list',
       @vRuleSetFilter      = '~PackingListType~ = ''LPNWithLDs''' ,
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Packing List for Piece Pick and Pick To Ship wave by Owner */
select @vRuleDescription = 'Packing list for PiecePick and Pick To ship wave types by Owner',
       @vRuleCondition   = '~WaveType~ in (''PCPK'', ''PTS'')',
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_'' + ~Ownership~ + ''_LPN''',
       @vStatus          = 'A' /* Active */,
       @vStatus          = 'I' /* In-Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #3 - Order PackingList */
/******************************************************************************/
select @vRuleSetDescription = 'Packing list rule for Orders',
       @vRuleSetName        = 'PackingList_ORD',
       @vRuleSetFilter      = '~PackingListType~ = ''ORD''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Packing List for particular Owner */
select @vRuleDescription = 'Packing list rule by Ownership',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''PackingList_'' + OH.Ownership
                           from OrderHeaders OH
                           where (OH.OrderId  = ~OrderId~)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I' /* In-Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Common Order Packing List for Piece Pick, Pick To Ship and LTL wave by Owner */
select @vRuleDescription = 'Packing list for PiecePick wave types by Owner',
       @vRuleCondition   = '~WaveType~ in (''PCPK'', ''PTS'', ''LTL'')',
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_'' + ~Ownership~ + ''_ORD''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Packing List for PTL wave */
select @vRuleDescription = 'Packing list for PTL wave types by Owner',
       @vRuleCondition   = '~WaveType~ = ''PTL''',
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_Auto_'' + ~Ownership~',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Generic for the particular business */
select @vRuleDescription = 'Packing list rule for orders by BusinessUnit',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 98;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Generic */
select @vRuleDescription = 'Packing list rule for generic order packing list',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ''PackingList_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I'/* Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #4 - Load Packing List */
/******************************************************************************/
select @vRuleSetName        = 'PackingList_Load',
       @vRuleSetDescription = 'Packing list RuleSet for Loads',
       @vRuleSetFilter      = '~PackingListType~ = ''Load''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set #3 Rules - Load Packing List */
/*----------------------------------------------------------------------------*/
select @vRuleDescription = 'Packing list generic rule for Loads',
       @vRuleCondition   = '~Carriersintegration~ = ''Y''',
       @vRuleQuery       = 'select ~BusinessUnit~ + ''LoadShippingManifest_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #1 - LPN ReturnPacking List */
/******************************************************************************/
select @vRuleSetDescription = 'Packing list rule for ReturnLPN',
       @vRuleSetName        = 'PackingList_Return',
       @vRuleSetFilter      = '~PackingListType~ = ''ReturnLPN''',
       @vSortSeq            = null,
       @vStatus             = 'I' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Generic return Packing List */
select @vRuleDescription = 'Packing list rule to get return packing list by BusinessUnit',
       @vRuleCondition   = null,
       @vRuleQuery       = 'select ~BusinessUnit~ + ''_ReturnPackingList_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* In-Active */
       @vSortSeq         = 100;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/* PackingList_Info1: Using these rules to determine Height of the Packing list report to print in dynamic sizes */
/******************************************************************************/
select @vRuleSetType = 'PackingList_Info1';

delete from @RuleSets;
delete from @Rules;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 - Additional Packing List info */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'PackingList_Info',
       @vRuleSetDescription = 'Additional info to determine the PL height to generate from Label generator tool',
       @vRuleSetFilter      = '~PackingListType~ = ''LPN'' and ~Source~ = ''ShippingDocsExport'' ',
       @vSortSeq            = null,
       @vStatus             = 'NA' /* A-Active, I-In-Active, NA-Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules - Additional info to determine the PL height */
select @vRuleCondition   = null,
       @vRuleDescription = 'Print the PL with 6inches Height if details count between 2 and 3',
       @vRuleQuery       = 'select 6 from vwLPNPackingListDetails where LPNId = ~LPNId~ having count(*) between 2 and 13',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rules - Additional info to determine the PL height */
select @vRuleCondition   = null,
       @vRuleDescription = 'Print the PL with 8 inches Height if details count between 14 and 26',
       @vRuleQuery       = 'select 8 from vwLPNPackingListDetails where LPNId = ~LPNId~ having count(*) between 14 and 26',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rules - Additional info to determine the PL height */
select @vRuleCondition   = null,
       @vRuleDescription = 'Print the PL with 11inches Height if details count between 26 and 44',
       @vRuleQuery       = 'select 11 from vwLPNPackingListDetails where LPNId = ~LPNId~ having count(*) between 26 and 44',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rules - Additional info to determine the PL height   */
select @vRuleCondition   = null,
       @vRuleDescription = 'Print the PL with 4inches Height if details count is 1 or morethan 44',
       @vRuleQuery       = 'select 4',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

/******************************************************************************/
/* PackingList_Comments1: Using these rules to determine the EntityType being sent */
/******************************************************************************/
select @vRuleSetType = 'PackingList_Comments1';

delete from @RuleSets;
delete from @Rules;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 - Notes info */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'PackingList_Notes',
       @vRuleSetDescription = 'RuleSet for Dynamic Notes for Packing List',
       @vRuleSetFilter      = '~DocumentType~ = ''PL''',
       @vSortSeq            = null, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules - To print Notes dynamically based on note type */
select @vRuleCondition   = null,
       @vRuleDescription = 'Print the PL with dynamic notes with respect to header or body or footer',
       @vRuleQuery       = 'select OH.UDF5
                            from OrderHeaders OH
                            where (OH.OrderId  = ~OrderId~) and
                                  (coalesce(OH.UDF5,'''') <> '''')',
       @vStatus          = 'A' /* Active */,
       @vRuleQueryType   = 'Select',
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

/******************************************************************************/
/* Packing List to print the MH10/UCC12988/ASNType Labels */
/******************************************************************************/
select @vRuleSetType = 'PackingListUCC';

delete from @RuleSets;
delete from @Rules;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 - PackingList UCC Labels To print */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'PackingList_UCCLabel',
       @vRuleSetDescription = 'PackingList for MH10/UCC128/ASNType Labels To Print',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'I' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules - PackingList for MH10/UCC128/ASNType Labels To Print */
select @vRuleCondition   = null,
       @vRuleDescription = 'PackingList for MH10/UCC128/ASNType Labels To Print',
       @vRuleQuery       = 'select ''PackingList_''+ ~BusinessUnit~ + ''_LPN_MH10_'' + OH.UDF16
                            from OrderHeaders OH
                            where (OH.OrderId  = ~OrderId~) and
                                  (OH.UDF16 like ''A%'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleDescription, RuleCondition, RuleQuery, SortSeq, Status)
 select @vRuleSetName, @vRuleDescription, @vRuleCondition, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
