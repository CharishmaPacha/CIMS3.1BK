/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/13  RV      In active rules which are not applicable for V3 (HA-1545)
  2019/06/15  RV      CreateSPGShipment_FEDEX: Made changes to create multi package shipments for FEDEX (CID-176)
  2019/06/08  RV      CreateSPGShipment_FEDEX: Corrected to rules to create single shipment from packing and
                        multi shipment from Label generator (CID-506)
  2019/06/07  RV      CreateSPGShipment_USPS: Setup rules for USPS (CID-388)
  2019/05/30  RV      CreateSPGShipment_UPS: Cleaned up un necessary rules, which are not required and we create always multishipments by excluding the packages,
                        which are already having valid shipment (CID-463)
  2019/05/24  RV      Enabled and disabled required rules (CID-435)
  2019/05/17  RV/SV   Resolved the issue with joins as it is being returned with value 'M' and creating shipments when
                        printing SLs(not SPLs) from ShippingDocs page (S2GCA-680)
  2019/05/21  RV      Made changes to create multishipment for FedEx (CID-176)
  2019/05/15  RKC     Resolve duplicate RuleDescription issues (CID-387)
  2016/09/15  DK      Added rules to print label for Pick To Ship wave if Status of LPN is picked.(HPI-GoLive)
  2016/08/30  AY      Corrected rule to not depend upon LPNsassigned passed in. (HPI-529).
  2016/08/26  RV      Corrected rules to create and print labels for small package shipments while packing (HPI-529)
  2016/08/25  AY      Corrected rules to create and print labels for small package shipments (HPI-529)
  2016/08/24  DK      Added rules to print label for Single package order from Shipping Docs(HPI-519)
  2016/08/05  RV      Initial version
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
/* Rules for : CreateSPGShipment */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'CreateSPGShipment';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #0 - No shipments needed for Non SPG Orders */
/******************************************************************************/
select @vRuleSetName        = 'CreateSPGShipment_NonSmallPackage',
       @vRuleSetDescription = 'Shipment creation for non-small package Orders',
       @vRuleSetFilter      = '~IsSmallPackageCarrier~ = ''N''', /* Yes */
       @vSortSeq            = 0, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* No shipment labels for non SPG Orders */
select @vRuleCondition   = null,
       @vRuleDescription = 'Do not need to create a shipment label for non Small Package Order',
       @vRuleQuery       = 'select ''N''', /* Do not attempt to create Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #1 - UPS Create SPG Shipment */
/******************************************************************************/
select @vRuleSetName        = 'CreateSPGShipment_UPS',
       @vRuleSetFilter      = '~Carrier~ = ''UPS''',
       @vRuleSetDescription = 'For UPS, determine when to generate Smallpackage labels and what type of shipment labels',
       @vSortSeq            = 0, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Create Multiple Shipment Labels With UPS for PickTicket while Packing */
select @vRuleCondition   = '(charindex(~OrderStatus~, ''KLSD'') > 0) and (~Operation~ = ''Packing'')',
       @vRuleDescription = 'If printing labels for UPS PT while Packing last package, create multi shipment labels',
       @vRuleQuery       = 'select ''M''', /* Multiple Shipment Labels */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Create Shipment Labels with UPS */
select @vRuleCondition   = '(~Entity~ in (''PickTicket'', ''LPN'')) and (~Operation~ <> ''Packing'')',
       @vRuleDescription = 'Create multi shipment if entity is PickTicket and ship label not exists while printing from ShippingDocs',
       @vRuleQuery       = 'select top 1 ''M''
                            from LPNs L
                              left join ShipLabels SL on (L.LPN = SL.EntityKey)
                            where (L.OrderId = ~OrderId~) and (L.LPNType = ''S'') and ((SL.IsValidTrackingNo = ''N'') or (SL.IsValidTrackingNo is null))', /* Create multi Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* UPS No Shipment label */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule to do not create shipment for UPS',
       @vRuleQuery       = 'select ''N''', /* No Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - USPS Create SPG Shipment */
/******************************************************************************/
select @vRuleSetName        = 'CreateSPGShipment_USPS',
       @vRuleSetFilter      = '~Carrier~ = ''USPS''',
       @vRuleSetDescription = 'Shipment creation rules for USPS Orders',
       @vSortSeq            = 0, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Create Shipment Labels with USPS */
select @vRuleCondition   = '(~Operation~ = ''Packing'')',
       @vRuleDescription = 'Create single shipment for each LPN of USPS Order',
       @vRuleQuery       = 'select ''Y''', /* Create Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Create Shipment Labels with USPS */
select @vRuleCondition   = '(~Entity~ in (''LPN'', ''PickTicket''))',
       @vRuleDescription = 'Create Shipment for each LPN of USPS Orders LPN',
       @vRuleQuery       = 'select ''Y''
                            from LPNs L
                              left join ShipLabels SL on (L.LPN = SL.EntityKey)
                            where (L.LPNId = ~LPNId~) and ((SL.IsValidTrackingNo = ''N'') or (SL.IsValidTrackingNo is null))', /* Create Shipment Label */
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default rule to do not create shipment */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule to do not create shipment for USPS',
       @vRuleQuery       = 'select ''N''', /* Do not Create Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #3 - FEDEX Create SPG Shipment */
/******************************************************************************/
select @vRuleSetName        = 'CreateSPGShipment_FEDEX',
       @vRuleSetFilter      = '~Carrier~ = ''FEDEX''',
       @vRuleSetDescription = 'Verify carrier for create FEDEX SPG shipment labels',
       @vSortSeq            = 0, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Create Single Shipment Labels with FEDEX for each package from packing, because few of the Shipvias not supported */
select @vRuleCondition   = '(~Operation~ = ''Packing'') and (~ShipVia~ in (''FEDX1F'', ''FEDX2F'', ''FEDX3F'', ''FEDX1''))', /* Need to include ShipVias, which are not supported MPS */
       @vRuleDescription = 'Create single shipment for each LPN for MPS not supported FedEx Order while packing',
       @vRuleQuery       = 'select ''Y''', /* Create Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Create Multiple Shipment Labels With FEDEX for PickTicket while Packing */
select @vRuleCondition   = '(charindex(~OrderStatus~, ''KLSD'') > 0) and (~Operation~ = ''Packing'')',
       @vRuleDescription = 'If printing labels for FEDEX PT while Packing last package, create multi shipment labels',
       @vRuleQuery       = 'select ''M''', /* Multiple Shipment Labels */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Create Single Shipment Labels with FEDEX, otherthan packing, because few of the FEDEX Shipvias not supported MPS */
select @vRuleCondition   = '(~Operation~ <> ''Packing'') and (~Entity~ in (''LPN'', ''PickTicket'') and ~ShipVia~ in (''FEDX1F'', ''FEDX2F'', ''FEDX3F'', ''FEDX1''))', /* Need to include ShipVias, which are not supported MPS */
       @vRuleDescription = 'Create single shipments for each LPN for MPS not supported FedEx Order otherthan packing',
       @vRuleQuery       = 'select ''Y''
                            from LPNs L
                              left join ShipLabels SL on (L.LPN = SL.EntityKey)
                            where (L.LPNId = ~LPNId~) and ((SL.IsValidTrackingNo = ''N'') or (SL.IsValidTrackingNo is null))', /* Create Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Create multi Shipment Labels with FEDEX, otherthan packing, because few of the FEDEX Shipvias not supported MPS */
select @vRuleCondition   = '(~Operation~ <> ''Packing'') and (~Entity~ in (''PickTicket'', ''LPN''))',
       @vRuleDescription = 'Create multi shipments for of FedEx Order otherthan packing',
       @vRuleQuery       = 'select ''M''
                            from LPNs L
                              left join ShipLabels SL on (L.LPN = SL.EntityKey)
                            where (L.OrderId = ~OrderId~) and (L.LPNType = ''S'') and ((SL.IsValidTrackingNo = ''N'') or (SL.IsValidTrackingNo is null))', /* Create Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;
 /*----------------------------------------------------------------------------*/
/* Default rule to not create shipments with FEDEX */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule - do not create shipment',
       @vRuleQuery       = 'select ''N''', /* Do not Create Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A' /* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #4 - ADSI Create SPG Shipment */
/******************************************************************************/
select @vRuleSetName        = 'CreateSPGShipment_ADSI',
       @vRuleSetFilter      = '~CarrierInterface~ = ''ADSI''',
       @vRuleSetDescription = 'Shipment creation rules for ADSI Orders',
       @vSortSeq            = 0, -- as we update RecordId, we do not need to specify this
       @vStatus             = 'NA' /* Not Applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Create Shipment Labels with ADSI */
select @vRuleCondition   = '(~Entity~ = ''PickTicket'')',
       @vRuleDescription = 'Create multi shipment if entity is PickTicket and ship label not exists',
       @vRuleQuery       = 'select ''M''
                            from ShipLabels
                            where (OrderId = ~OrderId~) and (Status = ''A'') and
                                  ((coalesce(TrackingNo, '''') = '''') or ((Label is null) and (ZPLLabel is null)))', /* Create multi Shipment Label */
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA' /* Not Applicable */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default rule for create Shipment Labels with ADSI */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default rule to do not create shipment for ADSI',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA' /* Not Applicable */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
