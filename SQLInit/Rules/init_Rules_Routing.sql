/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/26  RV      Initial Revision (HA-2682)
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
/* Rule Set : Determine Routing rules */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'GetRouting';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Determine ShipVia using Routing Rules */
/******************************************************************************/
select @vRuleSetName        = 'RoutingRule',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Determine the routing rules',
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 100; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Apply routing based upon the #OrdersToRoute, which may not be individual orders
         but a summary of a group of orders */
select @vRuleCondition   = 'object_id(''tempdb..#OrdersToRoute'') is not null',
       @vRuleDescription = 'Route #OrdersToRoute: Find routing rule using OrdersToRoute',
       @vRuleQuery       = 'select top 1 cast(RR.RecordId as varchar)
                            from vwRoutingRules RR join #OrdersToRoute OTR on
                                 (coalesce(OTR.ShipVia,       '''')  = coalesce(RR.InputShipVia,      OTR.ShipVia,       '''')) and
                                 (coalesce(OTR.SoldToId,      '''')  = coalesce(RR.SoldToId,          OTR.SoldToId,      '''')) and
                                 (coalesce(OTR.Account,       '''')  = coalesce(RR.Account,           OTR.Account,       '''')) and
                                 (coalesce(OTR.ShipToId,      '''')  = coalesce(RR.ShipToId,          OTR.ShipToId,      '''')) and
                                 (coalesce(OTR.ShipToState,   '''')  = coalesce(RR.ShipToState,       OTR.ShipToState,   '''')) and
                                 (coalesce(OTR.ShipToZip,     '''') >= coalesce(RR.ShipToZipStart,    OTR.ShipToZip,     '''')) and
                                 (coalesce(OTR.ShipToZip,     '''') <= coalesce(RR.ShipToZipEnd,      OTR.ShipToZip,     '''')) and
                                 (coalesce(OTR.ShipToCountry, '''')  = coalesce(RR.ShipToCountry,     OTR.ShipToCountry, '''')) and
                                 (coalesce(OTR.FreightTerms,  '''')  = coalesce(RR.InputFreightTerms, OTR.FreightTerms,  '''')) and
                                 (coalesce(OTR.Carrier,       '''')  = coalesce(RR.InputCarrier,      OTR.Carrier,       '''')) and
                                 (coalesce(nullif(cast(OTR.TotalWeight as float), ''''), 0) >= coalesce(RR.MinWeight, 0)) and
                                 (coalesce(nullif(cast(OTR.TotalWeight as float), ''''), 0) <= coalesce(RR.MaxWeight, 99999))
                            where (OTR.RecordId = ~RecordId~)
                            order by RR.SortSeq, RR.RecordId',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: select Routing rule based upon SoldTo and ShipTo */
select @vRuleCondition   = '~OrderId~ is not null',
       @vRuleDescription = 'Route Order: Find routing rule for the specific Order',
       @vRuleQuery       = 'select top 1 cast(RecordId as varchar)
                            from vwRoutingRules RR join vwOrderHeaders OH on
                              (OH.ShipVia       = coalesce(RR.InputShipVia,      OH.ShipVia)) and
                              (OH.SoldToId      = coalesce(RR.SoldToId,          OH.SoldToId)) and
                              (OH.Account       = RR.Account) and
                              (OH.ShipToId      = coalesce(RR.ShipToId,          OH.ShipToId)) and
                              (OH.ShipToState   = coalesce(RR.ShipToState,       OH.ShipToState)) and
                              (OH.ShipToZip    >= coalesce(RR.ShipToZipStart,    OH.ShipToZip)) and
                              (OH.ShipToZip    <= coalesce(RR.ShipToZipEnd,      OH.ShipToZip)) and
                              (OH.ShipToCountry = coalesce(RR.ShipToCountry,     OH.ShipToCountry)) and
                              (OH.FreightTerms  = coalesce(RR.InputFreightTerms, OH.FreightTerms)) and
                              (OH.Carrier       = coalesce(RR.InputCarrier,      OH.Carrier)) and
                              (coalesce(nullif(cast(~OrderWeight~ as float), ''''), 0) >= coalesce(RR.MinWeight, 0)) and
                              (coalesce(nullif(cast(~OrderWeight~ as float), ''''), 0) <= coalesce(RR.MaxWeight, 99999))
                            where (OH.OrderId = ~OrderId~)
                            order by SortSeq, RecordId',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
