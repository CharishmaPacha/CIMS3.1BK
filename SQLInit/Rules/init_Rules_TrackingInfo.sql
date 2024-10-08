/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/29  VS      Updated UPS URL to track the tracking numbers (BK-117)
  2016/08/29  PK      Updated URLs to track multiple tracking numbers.
  2016/08/17  DK      Initial version(HPI-457)
------------------------------------------------------------------------------*/

declare @vRuleSetType  TRuleSetType = 'TrackingURLs';

declare @vRecordId            TRecordId,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,

        @vBusinessUnit        TBusinessUnit,

        @vRuleCondition       TQuery,
        @vRuleQuery           TQuery,
        @vRuleDescription     TDescription,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/******************************************************************************/
/* Rule Set: Tracking URLs */
/******************************************************************************/
select @vRuleSetName        = 'CarrierTrackingUrls',
       @vRuleSetDescription = 'Rule Set to evaluate carrier Tracking Url',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: FEDEX */
select @vRuleCondition   = '~Carrier~ = ''FEDEX''',
       @vRuleDescription = 'Tracking URL for FedEx',
       @vRuleQuery       = 'select ''"https://www.fedex.com/apps/fedextrack/?action=track&trackingnumbers=TrackingNoLink&cntry_code=us"''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: UPS*/
select @vRuleCondition   = '~Carrier~ = ''UPS''',
       @vRuleDescription = 'Tracking URL for UPS',
       @vRuleQuery       = 'select ''"https://www.ups.com/track?loc=en_US&tracknum=TrackingNoLink"''',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = null;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go

/******************************************************************************/
/* Rule Set: Hyperlink w/ Tracking Nos for UPS */
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'TrackingNo_HyperLink';

declare @vRecordId            TRecordId,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,

        @vBusinessUnit        TBusinessUnit,

        @vRuleCondition       TQuery,
        @vRuleQuery           TQuery,
        @vRuleDescription     TDescription,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

select @vRuleSetName        = 'TrackingNo_HyperLink',
       @vRuleSetDescription = 'Get the tracking numbers hyperlink for UPS order Shipment notification',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Build hyperlink to be linked in the shipment notification */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the list of tracking numbers to build hyperlink on shipment notification',
       @vRuleQuery       = 'select stuff((select distinct (case
                                                             when SV.Carrier = ''UPS'' then
                                                                ''$ '' + nullif(TrackingNo, '''')
                                                             else
                                                                '', '' + nullif(LPD.TrackingNo, '''')
                                                           end)
                                          from vwLPNs LPD
                                            join orderheaders OH on (LPD.OrderId = OH.OrderId)
                                            join ShipVias     SV on (OH.ShipVia = SV.ShipVia)
                                          where (LPD.OrderId =~OrderId~ )
                                          FOR XML PATH('''')), 1, 2,'''')',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go

/******************************************************************************/
/* Rule Set: Get the tracking numbers */
/******************************************************************************/
declare @vRuleSetType  TRuleSetType = 'TrackingNos';

declare @vRecordId            TRecordId,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,

        @vBusinessUnit        TBusinessUnit,

        @vRuleCondition       TQuery,
        @vRuleQuery           TQuery,
        @vRuleDescription     TDescription,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

select @vRuleSetName        = 'TrackingNos',
       @vRuleSetDescription = 'Get the tracking numbers to show on Shipping Notification email',
       @vRuleSetFilter      = null,
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Get the TrackingNos to Show on ShippingNotification email */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the list of tracking numbers to Show on ShippingNotification email',
       @vRuleQuery       = 'select stuff((select distinct '', '' + nullif(TrackingNo, '''')
                                          from vwLPNs
                                          where (OrderId = ~OrderId~ )
                                          FOR XML PATH('''')), 1, 2,'''')',
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
