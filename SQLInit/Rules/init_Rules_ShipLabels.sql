/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/04/17  VS      FedEx Smart Post generate only single shipment labels (OBV3-2042)
  2024/04/06  RV      FEDEX: Generate single shipment for international services (FBV3-1726)
  2024/04/06  RV      Bug fixed to consider the evalue for Insert Required (SRIV3-488)
  2024/03/05  VS      Regenerate the ShipLabels through the API (HA-3966)
  2024/02/16  RV      Added rules to generate FedEx shipments using the FedEx OAuth API (CIMSV3-3395)
  2024/02/07  MS      Changes to defer label generation for large orders (JLFL-895)
  2023/11/14  SAV     Added rule to update UPC as mixed when Multiple SKUs (MBW-542)
  2023/09/23  RV      Added rule to generate always single shipment for FEDEX ONE RATE services (MBW-512)
  2023/09/08  RV      Added rules to process the UPS labels through CIMSUPS2 to use new authentication OAUTH2 (MBW-438)
  2023/04/25  RV      ShipLabelsInsert_Packing: Made changes to update the Total Package count (JLCA-777)
  2023/02/16  RV      Made changes to separate the ship label validations rules from Wave Release (OBV3-1613)
  2022/11/16  RKC     Default rule to initialize the ProcessStatus as 'Canceled' (OBV3-1445)
  2022/10/04  VS      Corrected the FedEx rules to support FedEx API (CIMSV3-1780)
  2022/09/12  RV      Added rules to generate SPL from packing if all the picked units are packed (OBV3-1176)
  2022/09/09  RV      Made changes to generate SPL from shipping docs if all the picked units are packed (OBV3-1141)
  2022/08/12  MS      GenerationMethod changed from job to APIJob (BK-893)
  2022/03/16  AY/RV   Made changes to process createshipment with different integration and generation methods (FBV3-921)
  2022/03/14  VS      Added rules for AutoShipLPN (FBV3-763)
  2022/03/11  SV      Inserted records into ShipLabels based on the Carrier.
                        Changes to generate ShipLabels on each package close for USPS orders (FBV3-921)
  2022/02/02  MS      Rule Changes to update InsertRequired as Yes during allocation (FBV3-713)
  2022/01/05  OK      Made changes to use ShipLabels_EvaluateRequirement for modify ship details action and
                      added rule to do not insert ship label records until carton type defined (HA-3287)
  2021/12/24  VS      Added new rule to process for FedEx (BK-390)
  2021/12/16  NB      ShipLabels LabelTypes used are S and RL. Corrected Rules updating LabelType as SPL,
                        which was creating duplicates in ShipLabel table(CIMSV3-1767)
  2021/12/04  AY      Added rules to process Shipping Docs requests using API (CIMSV3-1746)
  2021/12/04  RV      InsertRequired: Changed the purpose to insert ShipLabels table instead of
                        into APIOutboundTransactions (CIMSV3-1746)
  2021/11/26  NB      Changes to Rules for ShippingDocs operation (CIMSV3-1738)
  2021/11/26  VS      Added new rule to process for FedEx (BK-390)
  2021/06/25  RV      Added new rule to process PTS/BPP/BCP shipment request using UPS/API-Job for UPS (BK-378)
  2021/06/13  TK      Rules to update InsertRequired & APIWorkFlow (BK-349)
  2021/06/08  RV      Made changes to update the carrier interface to determine integration process (BK-354)
  2021/05/21  RV      Initial version (CIMSV3-1476)
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
        @vRuleDescription     TString,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/******************************************************************************/
/******************************************************************************/
/* RuleSetType 'ShipLabels_Insert': During package close, this RuleSettype is
   used to determine whether to insert records into ShipLabels based on the carrier.

   UPS/Fedex: Both are multishipment package carriers and hence the records are
   inserted into ShipLabels table during package close of the last unit of the Order.

   USSPS: For now, this is a singleshipment package carrier and hence the records
   are inserted into ShipLabels table for each package close of the Order.
*/
/******************************************************************************/
/******************************************************************************/

select @vRuleSetType = 'ShipLabels_Insert';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* RuleSet to determine and insert into ShipLabels during Packing */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabelsInsert_Packing',
       @vRuleSetFilter      = '~Module~ in (''Packing'')',
       @vRuleSetDescription = 'Insert Ship labels from Packing based on Carrier',
       @vSortSeq            =  100,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* During Packing, if it is an USPS order, insert into ShipLabels for each package close */
select @vRuleCondition   = '~Module~ in (''Packing'') and ~Carrier~ in (''USPS'')',
       @vRuleDescription = 'Packing: USPS, insert each package into ShipLabels on close',
       @vRuleQuery       = 'insert into #ShipLabelsToInsert (EntityType, EntityId, EntityKey, CartonType, OrderId, PickTicket, TaskId, WaveId, WaveNo, ShipVia, Carrier, IsSmallPackageCarrier, InsertRequired, BusinessUnit, CreatedBy)
                              select ''L'' /* LPN */, LPNId, LPN, CartonType, OrderId, ~PickTicket~, TaskId, PickBatchId, PickBatchNo, ~ShipVia~, ~Carrier~, ~IsSmallPackageCarrier~, ''Evaluate'', BusinessUnit, ~UserId~
                              from LPNs
                              where (LPNId = ~LPNId~) and
                                    (LPNType = ''S'' /* ShipCarton */)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* During Packing, if it an UPS or Fedex or ADSI order, then insert into ShipLabels only
   at the time of last package close of the Order */
select @vRuleCondition   = '~Module~ in (''Packing'') and ~Carrier~ in (''UPS'', ''Fedex'', ''Generic'')',
       @vRuleDescription = 'Packing: UPS/FedEx/Generic, insert into ShipLabels on last package close i.e. order is packed',
       @vRuleQuery       = 'insert into #ShipLabelsToInsert (EntityType, EntityId, EntityKey, CartonType, OrderId, PickTicket, TotalPackages, TaskId, WaveId, WaveNo, ShipVia, Carrier, IsSmallPackageCarrier, InsertRequired, BusinessUnit, CreatedBy)
                              select ''L'' /* LPN */, L.LPNId, L.LPN, L.CartonType, L.OrderId, OH.PickTicket, OH.LPNsAssigned, L.TaskId, L.PickBatchId, L.PickBatchNo, ~ShipVia~, ~Carrier~, ~IsSmallPackageCarrier~, ''Evaluate'', L.BusinessUnit, ~UserId~
                              from OrderHeaders OH
                                join LPNs L on (L.OrderId = OH.OrderId) and (L.LPNType = ''S'')
                            where (OH.OrderId = ~OrderId~) and (OH.Status = ''K'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* During Packing, if it an UPS or Fedex or ADSI order, then insert into ShipLabels only
   when all Picked units for Order are packed */
select @vRuleCondition   = '~Module~ in (''Packing'') and ~Carrier~ in (''UPS'', ''Fedex'', ''Generic'')',
       @vRuleDescription = 'Packing: Generate SPLs when all Picked units for Order are packed',
       @vRuleQuery       = 'insert into #ShipLabelsToInsert (EntityType, EntityId, EntityKey, CartonType, OrderId, PickTicket, TotalPackages, TaskId, WaveId, WaveNo, ShipVia, Carrier, IsSmallPackageCarrier, InsertRequired, BusinessUnit, CreatedBy)
                              select ''L'' /* LPN */, L.LPNId, L.LPN, L.CartonType, L.OrderId, OH.PickTicket, OH.LPNsAssigned, L.TaskId, L.PickBatchId, L.PickBatchNo, ~ShipVia~, ~Carrier~, ~IsSmallPackageCarrier~, ''Evaluate'', L.BusinessUnit, ~UserId~
                              from OrderHeaders OH
                                join LPNs L on (L.OrderId = OH.OrderId) and (L.LPNType = ''S'')
                            where (OH.OrderId = ~OrderId~) and (OH.Status = ''C'' /* Picking */) and (OH.UnitsPicked = OH.UnitsPacked);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

/******************************************************************************/
/******************************************************************************/
/* Rules for insert ship labels based upon the SPL generation method.
   - By default the labels will be generated by CIMSSI for which
     CarrierInterface will be CIMSSI and ProcessStatus = 'N' and Label Generator
     will batch and generate the SPL using CIMSSI

   - Labels can be generated using CIMSUPS API in a Job
     CarrierInterface will be CIMSUPS and ProcessStatus = PA and the API job
     will process those and hit the API to generate the SPLs

     Note:
     UPS won't issue any access key for new accounts and they introuduced OAUTH2,
     So we integrated new OAUTH2 in CIMS and CarrierInterface will be CIMSUPS2.
     For existing client UPS works with access key. So for older cleint we activate
     the CIMSUPS and for newer clients CIMSUPS2

   - Labels can be generated on the fly using CIMS UPS API via CLR
     CarrierInterace will be CIMSUPS and ProcessStatus = N, so that API job
     doesn't touch these records.
*/
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ShipLabels_EvaluateRequirement';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Decides whether the ship label needs to be generated during allocation or not.
   For some wave types we do and some we don't */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabels_UpdateInsertRequired',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Decide whether the ship label needs to be generated or not',
       @vSortSeq            =  100,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Initialize values if none specified by caller - just so that we don't have
   to check for Nulls all the time */
select @vRuleCondition   = null,
       @vRuleDescription = 'Initialize: Setup defaults when not specified',
       @vRuleQuery       = 'update #ShipLabelsToInsert
                            set InsertRequired = coalesce(InsertRequired, ''Evaluate''),
                                ProcessStatus  = coalesce(ProcessStatus,  ''Canceled'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* InsertRequired: Just a safety check to evaluate if it is even a small package
   carrier. , for SPG carrier and Ignore, for others. based upon other rules
   the No will be changed to Yes further down based upon the operation */
select @vRuleCondition   = null,
       @vRuleDescription = 'InsertRequired: Ignore other than Small package shipments',
       @vRuleQuery       = 'update #ShipLabelsToInsert
                            set InsertRequired = iif (IsSmallPackageCarrier = ''Y'', ''Evaluate'', ''Ignore'')
                            where InsertRequired = ''Evaluate''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* For some wave types we generate ship labels ahead of time. Here we are not considering any WaveType
   because the Allocation rules include the Operation of InsertShipLabels only for the required Wave Types */
select @vRuleCondition   = '~Module~ in (''Allocation'') and ~Operation~ in (''InsertShipLabels'')',
       @vRuleDescription = 'Allocation - Generate ship labels',
       @vRuleQuery       = 'update SLI
                            set SLI.InsertRequired = ''Yes''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired = ''Evaluate'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* At packing, for FedEx/UPS/ADSI - we insert only when order is completely packed */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Packing UPS/FedEx/ADSI: Generate ship labels only when Order is packed',
       @vRuleQuery       = 'update SLI
                            set SLI.InsertRequired = ''Yes''
                            from #ShipLabelsToInsert SLI
                              join OrderHeaders OH on (SLI.OrderId = OH.OrderId)
                            where (SLI.InsertRequired = ''Evaluate'') and
                                  (SLI.Carrier in (''UPS'', ''FEDEX'', ''Generic'')) and
                                  (OH.Status = ''K'' /* Packed */);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* At packing, for FedEx/UPS/ADSI - we insert only when all picked units are packed */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Packing UPS/FedEx/ADSI: Generate ship labels only when all picked units are packed',
       @vRuleQuery       = 'update SLI
                            set SLI.InsertRequired = ''Yes''
                            from #ShipLabelsToInsert SLI
                              join OrderHeaders OH on (SLI.OrderId = OH.OrderId)
                            where (SLI.InsertRequired = ''Evaluate'') and
                                  (SLI.Carrier in (''UPS'', ''FEDEX'', ''Generic'')) and
                                  (OH.Status = ''C'' /* Picking */) and (OH.UnitsPicked = OH.UnitsPacked);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* At packing, if needed we always generate ship labels */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Packing non UPS/FedEx/Generic: Generate ship labels for each LPN',
       @vRuleQuery       = 'update SLI
                            set SLI.InsertRequired = ''Yes''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired = ''Evaluate'') and
                                  (SLI.Carrier not in (''UPS'', ''FEDEX'', ''Generic''));',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* for shipping docs, for FedEx/UPS/ADSI - we insert only when order is completely packed or staged or ready to ship */
select @vRuleCondition   = '~Operation~ in (''ShippingDocs'')',
       @vRuleDescription = 'ShippingDocs UPS/FedEx/ADSI: Generate ship labels only when Order is packed, staged or ready to ship',
       @vRuleQuery       = 'update SLI
                            set SLI.InsertRequired = ''Yes''
                            from #ShipLabelsToInsert SLI
                              join OrderHeaders OH on (SLI.OrderId = OH.OrderId)
                            where (SLI.InsertRequired = ''Evaluate'') and
                                  (SLI.Carrier in (''UPS'', ''FEDEX'', ''USPS'', ''Generic'')) and
                                  (OH.Status in (''K'' /* Packed */, ''G'' /* Staged */, ''R'' /* Ready To Ship */));',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* for shipping docs, for FedEx/UPS/ADSI - we insert when all the picked units are packed for an Order */
select @vRuleCondition   = '~Operation~ in (''ShippingDocs'')',
       @vRuleDescription = 'ShippingDocs: Generate SPLs when all Picked units for Order are packed',
       @vRuleQuery       = 'update SLI
                            set SLI.InsertRequired = ''Yes''
                            from #ShipLabelsToInsert SLI
                              join OrderHeaders OH on (SLI.OrderId = OH.OrderId)
                            where (SLI.InsertRequired = ''Evaluate'') and
                                  (SLI.Carrier in (''UPS'', ''FEDEX'', ''USPS'', ''Generic'')) and
                                  (OH.Status = ''C'' /* Picking */) and (OH.UnitsPicked = OH.UnitsPacked);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* On Change of ShipVia or regeneration of ShipLabels, we need to insert a new ship label if it belongs to SmallPackageCarrier */
select @vRuleCondition   = '~Operation~ in (''OnChangeShipDetails'', ''VoidShipLabels'')',
       @vRuleDescription = 'On Voiding ShipLabels, we need to insert a new ship label if it belongs to SmallPackageCarrier',
       @vRuleQuery       = 'update SLI
                            set SLI.InsertRequired = iif (IsSmallPackageCarrier = ''Y'', ''Yes'', ''Ignore'')
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired = ''Evaluate'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* There may be some instances when we are not ready to generate the labels yet, if so,
   inform the same to the user with the appropriate reason.
   Example: When user changed Shipvia on order, we would want to initiate label generation only if LPNs have a Carton Type */
select @vRuleCondition   = null,
       @vRuleDescription = 'OnChangeShipDetails: Do not generate the Labels for LPN which do not proper Carton type',
       @vRuleQuery       = 'if (object_id(''tempdb..#ResultMessages'') is not null)
                              insert into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value1, Value2)
                                select distinct ''E'', EntityId, EntityKey, ''ShipLabel_NotInsertedLPN_MissingCT'', EntityKey, PickTicket
                                from #ShipLabelsToInsert SLI
                                where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                      (coalesce(SLI.CartonType, '''') = '''')

                            update SLI
                            set SLI.InsertRequired = iif (coalesce(CartonType, '''') = '''', ''No'', InsertRequired)
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate''));',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;


/******************************************************************************/
/******************************************************************************/
/* Decides whether the ship label needs to be generated or not. In Packing,
   we generate the ship labels for UPS/FedEx only when the entire order is packed
   and for other carriers for each LPN as it is packed */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetName        = 'ShipLabels_DetermineShipmentType',
       @vRuleSetFilter      = '~Module~ in (''Packing'', ''Allocation'') or ~Operation~ in (''ShippingDocs'', ''OnChangeShipDetails'', ''VoidShipLabels'', ''RegenerateTrackingNo'')',
       @vRuleSetDescription = 'Determine if ship label is a Multi-package shipment or not',
       @vSortSeq            =  200,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* For UPS & Generic (ADSI) : Generate shiplabel for all packages at once  What
   this means is that we make a single request to carrier and send multiple packages
   to generate Tracking numbers for all of them at once. example: send all the packages
   of an order to generate for all */
select @vRuleCondition   = null,
       @vRuleDescription = 'For UPS, FEDEX and Generic: Generate multi-package shipment',
       @vRuleQuery       = 'update SLI
                            set SLI.ShipmentType   = ''M'',
                                SLI.LabelsRequired = iif (OH.ReturnLabelRequired = ''Y'', ''S,RL'', ''S''),
                                SLI.LabelType      = iif (OH.ReturnLabelRequired = ''Y'', ''S,RL'', ''S'')
                            from #ShipLabelsToInsert SLI
                              join OrderHeaders OH on (SLI.OrderId = OH.OrderId)
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier in (''UPS'', ''Generic''));',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Other than UPS, ADSI: Generate shiplabel for each LPN. i.e. we send a request
   to the carrier to generae for each package one after the other */
select @vRuleCondition   = null,
       @vRuleDescription = 'Other than UPS, FEDEX and ADSI: Generate shiplabel for each LPN',
       @vRuleQuery       = 'update SLI
                            set SLI.ShipmentType   = ''S'', /* should be S for single package, but CIMSI expects Y */
                                SLI.LabelsRequired = iif (OH.ReturnLabelRequired = ''Y'', ''S,RL'', ''S''),
                                SLI.LabelType      = iif (OH.ReturnLabelRequired = ''Y'', ''S,RL'', ''S'')
                            from #ShipLabelsToInsert SLI
                              join OrderHeaders OH on (SLI.OrderId = OH.OrderId)
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier not in (''UPS'', ''Generic''));',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* For FedEx need to generate for each LPN  (done above) except for IPD we treat
   it as multi package shipment i.e. one request per Order
*/
select @vRuleCondition   = null,
       @vRuleDescription = 'FEDEXIPD: Generate shiplabels by Shipment',
       @vRuleQuery       = 'update SLI
                            set SLI.ShipmentType   = ''M'', -- should be S for single package, but CIMSI expects Y
                                SLI.LabelsRequired = iif (OH.ReturnLabelRequired = ''Y'', ''S,RL'', ''S''),
                                SLI.LabelType      = iif (OH.ReturnLabelRequired = ''Y'', ''S,RL'', ''S'')
                            from #ShipLabelsToInsert SLI
                              join OrderHeaders OH on (SLI.OrderId = OH.OrderId)
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.ShipVia in (''FedexIPD''));',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* FEDXSP: FedEx - Smart Post is not MPS, so generate single shipment labels for FEDEX */
select @vRuleCondition   = null,
       @vRuleDescription = 'FEDXSP: FedEx Smart Post Generate single shipment labels',
       @vRuleQuery       = 'update SLI
                            set SLI.TotalPackages = ''1''
                            from #ShipLabelsToInsert SLI
                            where (SLI.ShipVia = ''FEDXSP'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* FEDEX - International: Generate single shipment labels for FEDEX International
   This is a temp fix only until we enhance to process multiple packages in one
   request

   For FedEx Domestic, even for a multi-package shipment, we request one label at
   a time for each package with the first being Master. However, for international
   we cannot do that but we can request multiple labels at once - which is an
   enhancememnt yet to be done */
select @vRuleCondition   = null,
       @vRuleDescription = 'FEDEX - International - Each Package is a shipment by itself',
       @vRuleQuery       = 'update SLI
                            set SLI.TotalPackages = ''1''
                            from #ShipLabelsToInsert SLI
                            where (SLI.ShipVia like ''FEDXI%'')
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* FEDEX_ONE_RATE: Fedex One Rate not MPS, so generate single shipment labels for FEDEX */
select @vRuleCondition   = null,
       @vRuleDescription = 'FEDEX_ONE_RATE: Generate single shipment labels',
       @vRuleQuery       = 'update SLI
                            set SLI.TotalPackages = ''1''
                            from #ShipLabelsToInsert SLI
                              join OrderHeaders OH on (SLI.OrderId = OH.OrderId)
                              join vwShipVias SV on (OH.ShipVia = SV.ShipVia) and (SV.Carrier = ''FEDEX'')
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  ((dbo.fn_IsInList(''SS-FOR'' /* FEDEX ONE RATE */, OH.CarrierOptions) > 0) or
                                   (charindex(''FEDEX_ONE_RATE'', SV.SpecialServices) > 0));',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Shiplabels - determine Carrier Interface for LPNs */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabels_DetermineCarrierInterface&Status',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Shiplabels - determine Carrier Interface & Process Status for LPNs',
       @vStatus             = 'A' /* Inactive */,
       @vSortSeq            = 300;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Carrier Interface UPS-API: UPS Carrier create shipment requests thru API CLR */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Carrier Interface UPS-API: For Packing, process UPS shipment requests thru API-CLR',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''CLR'',
                                SLI.CarrierInterface  = ''CIMSUPS''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'')) and
                                  (SLI.Carrier        = ''UPS'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface FedEx-API: FedEx Carrier create shipment requests thru API CLR */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Carrier Interface FedEx-API: For Packing, process FedEx shipment requests thru API-CLR',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''CLR'',
                                SLI.CarrierInterface  = ''CIMSFedEx2''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'')) and
                                  (SLI.Carrier        = ''FedEx'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface FedEx-CIMSSI: FedEx Carrier create shipment requests thru CIMS UI */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Carrier Interface FedEx-CIMSSI: For Packing, process FedEx shipment requests thru CIMSSI-UI',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''CIMSSI'',
                                SLI.GenerationMethod  = ''UI'',
                                SLI.CarrierInterface  = ''DIRECT''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'')) and
                                  (SLI.Carrier        = ''FedEx'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface USPS-API: USPS Carrier create shipment requests thru API CLR */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Carrier Interface USPS-API: For Packing, process USPS shipment requests thru API-CLR',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''CLR'',
                                SLI.CarrierInterface  = ''CIMSUSPSEndicia''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'')) and
                                  (SLI.Carrier        = ''USPS'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface USPS-CIMSSI: USPS Carrier create shipment requests thru CIMSSI UI */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Carrier Interface USPS-CIMSSI: For Packing, process USPS shipment requests thru CIMSSI-UI',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''CIMSSI'',
                                SLI.GenerationMethod  = ''UI'',
                                SLI.CarrierInterface  = ''DIRECT''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'')) and
                                  (SLI.Carrier        = ''USPS'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface ADSI-CIMSSI: shipment requests to ADSI thru CIMSSI UI */
select @vRuleCondition   = '(~Module~ = ''Packing'') or (~Operation~ =''ShippingDocs'')',
       @vRuleDescription = 'Packing Carrier Interface-ADSI: For Packing and ShippingDocs process ADSI shipment requests thru CIMSSI-UI',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = iif (InsertRequired = ''Yes'', ''Initial'', SLI.ProcessStatus),
                                SLI.IntegrationMethod = ''CIMSSI'',
                                SLI.GenerationMethod  = ''UI'',
                                SLI.CarrierInterface  = ''ADSI''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.CarrierInterface is null) and
                                  (SLI.ShipVia like ''BEST%'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface ADSI-CIMSSI: shipment requests to ADSI thru CIMSSI LG */
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing Carrier Interface-ADSI: Use for BEST* ShipVias',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = iif (InsertRequired = ''Yes'', ''Initial'', SLI.ProcessStatus),
                                SLI.IntegrationMethod = ''CIMSSI'',
                                SLI.GenerationMethod  = ''LabelGenerator'',
                                SLI.CarrierInterface  = ''ADSI''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.CarrierInterface is null) and
                                  (SLI.ShipVia like ''BEST%'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface UPS-API: UPS Carrier create shipment requests thru API Job when labels
   are created during allocation */
select @vRuleCondition   = '(~Module~ in (''Allocation'') and ~Operation~ in (''InsertShipLabels'')) or
                            (~Operation~ in (''OnChangeShipDetails'', ''RegenerateTrackingNo''))',
       @vRuleDescription = 'Carrier Interface UPS-API-Job: For labels generated in Allocation, process shipment requests thru API Job for PTS/BPP/BCP',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''APIJob'',
                                SLI.CarrierInterface  = ''CIMSUPS''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier        = ''UPS'') and
                                  (SLI.CarrierInterface is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface FedEx-API: FedEx Carrier create shipment requests thru API Job when labels are created
   are created during allocation */
select @vRuleCondition   = '(~Module~ in (''Allocation'') and ~Operation~ in (''InsertShipLabels'')) or
                            (~Operation~ in (''OnChangeShipDetails'', ''RegenerateTrackingNo''))',
       @vRuleDescription = 'Carrier Interface FedEx-API-Job: For labels generated in Allocation, process shipment requests thru API Job',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''APIJob'',
                                SLI.CarrierInterface = ''CIMSFedEx2''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier        = ''FedEx'') and
                                  (SLI.CarrierInterface is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface USPS-API: UPS Carrier create shipment requests thru API Job when labels are created
   are created during allocation */
select @vRuleCondition   = '(~Module~ in (''Allocation'') and ~Operation~ in (''InsertShipLabels'')) or
                            (~Operation~ in (''OnChangeShipDetails'', ''RegenerateTrackingNo''))',
       @vRuleDescription = 'Carrier Interface USPS-API-Job: For labels generated in Allocation, process shipment requests thru API Job',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = iif (InsertRequired = ''Yes'', ''Initial'', ''N''), /* PA = Process through API */
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''APIJob'',
                                SLI.CarrierInterface  = ''CIMSUSPSEndicia''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier        = ''USPS'') and
                                  (SLI.CarrierInterface is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface UPS-API: UPS Carrier create shipment requests thru API CLR */
select @vRuleCondition   = '~Operation~ in (''ShippingDocs'')',
       @vRuleDescription = 'Carrier Interface UPS-API: For ShippingDocs, process UPS shipment requests thru API-CLR',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'', /* PA = Process through API */
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''CLR'',
                                SLI.CarrierInterface  = ''CIMSUPS''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier        = ''UPS'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface FedEx-API: FedEx Carrier create shipment requests thru API CLR */
select @vRuleCondition   = '~Operation~ in (''ShippingDocs'')',
       @vRuleDescription = 'Carrier Interface FedEx-API: For ShippingDocs, process FedEx shipment requests thru API-CLR',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''CLR'',
                                SLI.CarrierInterface  = ''CIMSFedEx2''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier        = ''FedEx'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface FedEx-CIMSSI: FedEx Carrier create shipment requests thru CIMSSI UI */
select @vRuleCondition   = '~Operation~ in (''ShippingDocs'')',
       @vRuleDescription = 'Carrier Interface FedEx-CIMSSI: For ShippingDocs, process FedEX shipment requests thru CIMSSI-UI',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''CIMSSI'',
                                SLI.GenerationMethod  = ''UI'',
                                SLI.CarrierInterface  = ''DIRECT''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier        = ''FedEx'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface USPS-API: USPS Carrier create shipment requests thru API CLR */
select @vRuleCondition   = '~Operation~ in (''ShippingDocs'')',
       @vRuleDescription = 'Carrier Interface USPS-API: For ShippingDocs, process USPS shipment requests thru API-CLR',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''API'',
                                SLI.GenerationMethod  = ''CLR'',
                                SLI.CarrierInterface  = ''CIMSUPSPSEndicia''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier        = ''USPS'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Carrier Interface USPS-CIMSSI: USPS Carrier create shipment requests thru CIMSSI UI */
select @vRuleCondition   = '~Operation~ in (''ShippingDocs'')',
       @vRuleDescription = 'Carrier Interface USPS-CIMSSI: For ShippingDocs, process USPS shipment requests thru CIMSSI-UI',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = ''Initial'',
                                SLI.IntegrationMethod = ''CIMSSI'',
                                SLI.GenerationMethod  = ''UI'',
                                SLI.CarrierInterface  = ''DIRECT''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.Carrier        = ''USPS'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update APITransaction based on Carrier */
select @vRuleCondition   = null,
       @vRuleDescription = 'Irrespective of the ShipmentType, APITransactionStatus for Fedex orders will be PrepareAndSend and for UPS/USPS will be Initial.',
       @vRuleQuery       = 'update SLI
                            set SLI.APITransactionStatus = iif (SLI.Carrier = ''Fedex'', ''PrepareAndSend'', ''Initial'')
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.IntegrationMethod = ''API'') and
                                  (SLI.CarrierInterface is not null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default Rule to use CIMSSI to generate SPL */
select @vRuleCondition   = null,
       @vRuleDescription = 'Carrier Interface-ADSI: Use for BEST* ShipVias',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus     = iif (InsertRequired = ''Yes'', ''N'', SLI.ProcessStatus),
                                SLI.IntegrationMethod = ''CIMSSI'',
                                SLI.GenerationMethod  = ''LabelGenerator'',
                                SLI.CarrierInterface  = ''ADSI''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.CarrierInterface is null) and
                                  (SLI.ShipVia like ''BEST%'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Default Rule to use CIMSSI to generate SPL */
select @vRuleCondition   = null,
       @vRuleDescription = 'Carrier Interface-Default: By default use CIMSSI to generate ship labels',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus    = iif (InsertRequired = ''Yes'', ''N'', SLI.ProcessStatus),
                                SLI.IntegrationMethod = ''CIMSSI'',
                                SLI.GenerationMethod  = ''LabelGenerator'',
                                SLI.CarrierInterface  = ''DIRECT''
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.CarrierInterface is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Change Shipment type change to Y for single shipment as CIMSSI expects Y */
select @vRuleCondition   = null,
       @vRuleDescription = 'CIMSSI: Change from S to Y for single shipment',
       @vRuleQuery       = 'update SLI
                            set SLI.ShipmentType = iif (SLI.ShipmentType = ''S'', ''Y'', SLI.ShipmentType)
                            from #ShipLabelsToInsert SLI
                            where (SLI.InsertRequired in (''Yes'', ''Evaluate'')) and
                                  (SLI.CarrierInterface = ''CIMSSI'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* CIMSFEDEX: Fedex master package through CLR to process immediately for API Integration */
select @vRuleCondition   = null,
       @vRuleDescription = 'CIMSFEDEX: Fedex master package through CLR to process immediately for API Integration',
       @vRuleQuery       = 'update SLI
                            set SLI.GenerationMethod = ''CLR''
                            from #ShipLabelsToInsert SLI
                              join LPNs L on (L.LPNId = SLI.EntityId) and (SLI.EntityType = ''L'' /* LPN */)
                            where (SLI.CarrierInterface  = ''CIMSFEDEX2'') and
                                  (SLI.IntegrationMethod = ''API'') and
                                  (L.PackageSeqNo        = ''1'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* CIMSUPS2: Change the carrier interface from CIMSUPS to CIMSUPS2 to generate the label with OAUTH2 */
select @vRuleCondition   = null,
       @vRuleDescription = 'CIMSUPS2: Use OAUTH2 for CIMSUPS API Integration',
       @vRuleQuery       = 'update SLI
                            set SLI.CarrierInterface = ''CIMSUPS2''
                            from #ShipLabelsToInsert SLI
                            where (SLI.CarrierInterface  = ''CIMSUPS'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Small Package Orders: Defer label generation if Order has more cartons than threshold */
select @vRuleCondition   = '~Module~ in (''Packing'')',
       @vRuleDescription = 'Small Package Orders: Defer label generation if Order has more cartons than threshold',
       @vRuleQuery       = 'declare @vNumCartons     TInteger,
                                    @vMaxLabelsToGen TInteger;

                            select @vMaxLabelsToGen = dbo.fn_Controls_GetAsInteger(''Packing'', ''MaxCarrierLabels'', 20, ~BusinessUnit~, ~UserId~);

                            select @vNumCartons = count(*)
                            from #ShipLabelsToInsert
                            where (InsertRequired = ''Yes'')

                            if (@vNumCartons > @vMaxLabelsToGen)
                              begin
                                update SLI
                                set SLI.GenerationMethod = ''APIJob''
                                from #ShipLabelsToInsert SLI
                                where (SLI.IntegrationMethod = ''API'') and
                                      (SLI.InsertRequired = ''Yes'');

                                insert into #ResultMessages (MessageType, MessageName) select ''I'' /* Info */, ''PackingSPLOrdDeferLabelGen'';
                              end',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Remove invalid data to do not generate labels */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabels_RemoveInvalid',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update invalid data to do not generate labels',
       @vSortSeq            =  400,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to do not generate SPLs for invalid Orders */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update invalid records process status',
       @vRuleQuery       = 'update SLI
                            set SLI.ProcessStatus = ''LGE'',
                                SLI.ShipmentType  = ''X'',
                                SLI.Notifications =  dbo.fn_messages_Build(V.MessageName, V.Value1, V.Value2, V.Value3, V.Value4, V.Value5)
                            from #ShipLabelsToInsert SLI
                              join ShipLabelValidations SLV on (SLI.OrderId = SLV.EntityId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */

/******************************************************************************/
/******************************************************************************/
/* Rule Set : On Ship label of an LPN, do we auto ship the LPN? */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ShipLabels_AutoShipLPN';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set: Evaluate AutoShipLPN Requirement */
/******************************************************************************/
select @vRuleSetName        = @vRuleSetType,
       @vRuleSetFilter      = '~Action~ = ''LPNAutoShip''',
       @vRuleSetDescription = 'AutoShipLPN: Evaluate if required or not',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 900; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule : Auto ship LPNs for Close Package action  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   =  '~WaveType~ = ''PTC''',
       @vRuleDescription = 'Auto ship LPNs for Close Package action',
       @vRuleQuery       = 'select ''Y''
                            from LPNs
                            where (LPNId = ~LPNId~) and (DestWarehouse = ''B2'') and
                                  (Status = ''D'' /* Packed */)',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA'/* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Auto Ship LPN - No by default */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   =  null,
       @vRuleDescription = 'Auto ship LPNs: No by default',
       @vRuleQuery       = 'select ''N''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* In Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
