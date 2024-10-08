/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  TK      Print list rules for Packing (BK-348)
  2021/06/06  TK      Print List post process updates should be a different Rule Set (BK-348)
  2021/01/12  MS      Added rules for Combo LPNWithODs (BK-52)
  2020/12/05  MS      Added rules for Combo packingslip (CIMSV3-1234)
  2020/11/16  RV      Added rules to decide the PrintDataFlag based upon the threshold (HA-1660)
              RV      Added rules to load print list from print job info from print jobs
  2020/10/08  RT      Include OrderId in the SortOrder  to differentiate the CustPO and ShipToStore is same (HA-1495)
  2020/09/30  RV      Added rule to update the printer unified name (HA-1481)
  2020/08/08  RT      Rules To update the SortOrder and PrinterName with respect to the WaveType (HA-1193)
  2020/07/28  RT      Included LPNs in the join to get the LPNDetails with respect to the LPNType 'S' (HA-1240)
  2020/07/16  AY      Save ZPL files by CustPO & Wave and always save ZPL for debugging
  2020/07/14  RV      Added Rules to save the ZPL label data for Orders, which are ship from contractor Warehouses (HA-1075)
  2020/07/09  RV      Added rules to print packing label when error in small package label generation (HA-1123)
  2020/07/02  PHK     Rule condition has been changed to null to print PL from Shipping Docs (HA-1055)
  2020/06/26  VM      Get Contents Label Format from OH.ContentsLabelFormat (HA-1037)
  2020/06/25  KBB     Added new rule for printing Rural King PL (HA-923)
  2020/06/24  PHK     Added new rule for printing combo PL for each LPN (HA-597)
  2020/06/17  MS      Corrections to PrinterName (HA-853)
  2020/06/12  AY      Added option LDwithLDs to print carton level details on the combo packing list (HA-857)
                      Renamed PTS combo packing lists and changed rules accordingly
  2020/06/11  MS      Rules to print append files for PTS packingslips (HA-857)
  2020/04/16  AY      Initial version
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
/* Rule Set : Determine which labels to print for Outbound */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PrintList_ShippingDocs';

delete from @RuleSets;
delete from @Rules;

/* Rule Conditions and Queries are validated on Insert.
   These Temp Tables are created such that the validations are done correctly */
declare @ttSelectedEntities  TEntityValuesTable;
if (object_id('tempdb..#ttSelectedEntities') is null)
  select * into #ttSelectedEntities from @ttSelectedEntities;

/******************************************************************************/
/* Rule Set - Identify the list of labels/reports for the given entities */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_ShippingDocs_GeneratePrintList',
       @vRuleSetFilter      = '~Action~ in (''GeneratePrintList'', ''PrintDocuments'')',
       @vRuleSetDescription = 'Orders: Determine which labels to print for Orders',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Add record for the Wave  */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Wave: Add record for display',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, Description, DocumentClass, DocumentSubClass,
                                                    DocumentType, DocumentFormat,
                                                    InputRecordId, SortSeqNo)
                              select ''Wave'', W.RecordId, W.WaveNo, ''Wave '' + W.WaveNo, ''Label'', ''ZPL'',
                                     ''WL'', ''Wave_4x6_Detail_'' + W.WaveType,
                                     ETP.RecordId, 1
                              from Waves W
                                 join #EntitiesToPrint ETP on ETP.EntityId = W.RecordId
                              where (ETP.EntityType = ''Wave'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Entity = ORDER

  The rules to generate documents for any given order in EntitiesToPrint are

  a. Always insert a record for the order to display the Order info if this is an interactive request. If the
     request is not interactive, this record would be of no use.
  b. For a non-PTS order, print the packing list for the Order. Format will be PackingList_ <OH.PackingListFormat>
  c. For PTS Orders, we have two variations: Regular Packing List or Combo Packing List. The rules would be setup
     to insert records based upon the requirement. One example is some SoldTos require combo PL and others don't.
     c1. PTS order requiring normal packing slips: Format will be PackingList_ <OH.PackingListFormat>
     c2. PTS order requiring combo packing slip: No PL will be printed against the Order
*/
/******************************************************************************/
/*-------------------------------------------------------------------------------------------------------------*/
/* Add record for the Order for grouping to show in treeview */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Order: Add record for display if there is no PL to be printed for the Order',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, Description, Action,
                                                    InputRecordId, SortSeqNo)
                              select ''Order'', OH.OrderId, ''Order-'' + OH.PickTicket, ''PickTicket '' + OH.PickTicket, '''',
                                     ETP.RecordId, 1
                              from OrderHeaders OH
                                 join #EntitiesToPrint ETP on ETP.EntityId = OH.OrderId
                              where (ETP.EntityType = ''Order'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Order Packing List: For Non-PTS Orders. We assume that all packing lists are ORD at this point, if for some
     customers we have to print ORDWithLDs, we will determine that later */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Order (non-PTS): Print Packing list if required',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass,
                                                    DocumentType, DocumentSubType, DocumentFormat, DocumentSchema, ParentEntityKey,
                                                    InputRecordId, SortSeqNo)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''Report'', ''RDLC'',
                                     ''PL'', ''ORD'', ''PackingList_'' + OH.PackingListFormat, ''PackingList'', ''Order-'' + OH.PickTicket,
                                     ETP.RecordId, 2
                              from OrderHeaders OH
                                 join #EntitiesToPrint ETP on ETP.EntityId = OH.OrderId
                              where (ETP.EntityType = ''Order'') and (coalesce(OH.PackingListFormat, '''') > '''') and
                                    (ETP.WaveType <> ''PTS'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Packing List - for PTS Orders - only if not printing combo packing list */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Order (PTS): Print Packing list only if not combo',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass,
                                                    DocumentType, DocumentSubType, DocumentFormat, DocumentSchema, ParentEntityKey,
                                                    InputRecordId, SortSeqNo)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''Report'', ''RDLC'',
                                     ''PL'', ''ORD'', ''PackingList_'' + OH.PackingListFormat, ''PackingList'', ''Order-'' + OH.PickTicket,
                                     ETP.RecordId, 2
                              from OrderHeaders OH
                                 join #EntitiesToPrint ETP on ETP.EntityId = OH.OrderId
                              where (ETP.EntityType = ''Order'') and (coalesce(OH.PackingListFormat, '''') > '''') and
                                    (ETP.WaveType = ''PTS'') and
                                    (dbo.fn_GetMappedValue(''CIMS'', ETP.SoldToId, ''CIMS'', ''PTS_PackingListType'', null, OH.BusinessUnit) <> ''Combo'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Entity = TASK

  When Task is an entity to print, then we would
*/
/******************************************************************************/

/*-------------------------------------------------------------------------------------------------------------*/
/* Task Header Label: For PTS/PTC/SLB/RU Waves */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Task: Print wave specific Task Header label for PTS/PTC Waves',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass,
                                                    DocumentType, DocumentFormat, ParentEntityKey,
                                                    InputRecordId, SortSeqNo)
                              select ''Task'', ETP.EntityId, ETP.EntityKey, ''Label'', ''ZPL'',
                                     ''TL'', ''Task_4x6_HeaderLabel_'' + ETP.WaveType, ''Wave-'' + ETP.WaveNo,
                                     ETP.RecordId, 1
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''Task'') and (ETP.WaveType in (''PTS'', ''PTC'', ''SLB'', ''RU''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Task Header Label: For other than PTS/PTC/SLB/RU Waves */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Task: Print generic Task Header label for non PTS/PTC Waves',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass,
                                                    DocumentType, DocumentFormat, ParentEntityKey,
                                                    InputRecordId, SortSeqNo)
                              select ''Task'', ETP.EntityId, ETP.EntityKey, ''Label'', ''ZPL'',
                                     ''TL'', ''Task_4x6_HeaderLabel'', ''Wave-'' + ETP.WaveNo,
                                     ETP.RecordId, 1
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''Task'') and (ETP.WaveType not in (''PTS'', ''PTC'', ''SLB'', ''RU''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Entity = LPN

   There could be various scenarios, so alter the rule to suit as per client requirements.

   a. We could print 4x8 label and regular packing list for Customers who are setup as 4x8 in mapping.

   b. We could print combo packing list for customers who are setup as Combo.

   c. We could print a combo packing list for all customers for certain wave types

*/
/******************************************************************************/

/*-------------------------------------------------------------------------------------------------------------*/
/* Print UCC128 label */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = 'coalesce(~EntityType~, '''') <> ''Task''',
       @vRuleDescription = 'UCC128 Label: Print UCC128 labels for each LPN as specified on the Order',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''SL'', ''Ship_4x6_Format_'' + OH.UCC128LabelFormat,
                                     ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 2
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (coalesce(OH.UCC128LabelFormat, '''') > '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print CaseContent label */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = 'coalesce(~EntityType~, '''') <> ''Task''',
       @vRuleDescription = 'Content label: Print Generic content labels for each LPN',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''CL'', OH.ContentsLabelFormat,
                                     ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 3
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (coalesce(OH.ContentsLabelFormat, '''') > '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print 4x8 Small package label for PTS */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Small Package label: Print 4x8 format label for PTS',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''SPL'', ''Ship_4x8_PTS'',
                                     ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (ETP.WaveType = ''PTS'') and (ETP.IsSmallPackageCarrier = ''Y'') and (ETP.IsValidTrackingNo = ''Y'') and
                                    (dbo.fn_GetMappedValue(''CIMS'', ETP.SoldToId, ''CIMS'', ''PTS_PackingListType'', null, L.BusinessUnit) = ''4x8'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* In-Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print 4x8 generic label for PTS if not small package order or error in small package label generation - as of now, both are same format */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PTS Non-Small Package or  Small package labels, which have errors label: Print 4x8 generic format label',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''SL'', ''Ship_4x8_PTS'',
                                     ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (ETP.WaveType = ''PTS'') and ((ETP.IsSmallPackageCarrier = ''N'') or (ETP.IsValidTrackingNo = ''N'')) and
                                    (dbo.fn_GetMappedValue(''CIMS'', ETP.SoldToId, ''CIMS'', ''PTS_PackingListType'', null, L.BusinessUnit) = ''4x8'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print combo PL for some PTS Waves (If Mapping has combo) - There could be a master page and an additional page.
   Master page has the shipping label and the additional page does not. */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PTS/Combo PL(LPNWithLDs): Print consolidated Packing List for each LPN if mapping has Combo',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType,
                                                    DocumentFormat, DocumentSchema, ParentEntityKey, NumDetails,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Report'', ''RDLC'', ''PL'', ''LPNWithLDs'',
                                     ''PackingList_'' + OH.PackingListFormat, ''PackingList'', ''Order-'' + L.PickTicketNo, L.NumLines,
                                     ETP.RecordId, 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (ETP.WaveType = ''PTS'') and
                                    (dbo.fn_GetMappedValue(''CIMS'', ETP.SoldToId, ''CIMS'', ''PTS_PackingListType'', null, L.BusinessUnit) = ''Combo'');

                            /* Insert Append report */
                            exec pr_Printing_GetAppendReport',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print combo PL for required Waves(LPNWithLDs) - There could be a master page and an additional page. Master page has
   the shipping label and the additional page does not. This rule will insert both Master & Append pages */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PTS/Combo PL(LPNWithLDs): Print combo Packing List always for each LPN',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType,
                                                    DocumentFormat, DocumentSchema, ParentEntityKey, NumDetails,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Report'', ''RDLC'', ''PL'', ''LPNWithLDs'',
                                     ''PackingList_'' + OH.PackingListFormat, ''PackingList'', ''Order-'' + L.PickTicketNo, L.NumLines,
                                     ETP.RecordId, 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (ETP.WaveType = ''PTS'');

                            /* Insert Append report */
                            exec pr_Printing_GetAppendReport',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print combo PL for BPP Waves (If Mapping has combo-LPNWithODs) - There could be a master page and an additional page.
   Master page has the shipping label and the additional page does not. */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Pick & Pack/Combo PL(LPNWithODs): Print combo Packing List for each LPN if mapping has Combo',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType,
                                                    DocumentFormat, DocumentSchema, ParentEntityKey, NumDetails,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Report'', ''RDLC'', ''PL'', ''LPNWithODs'',
                                     ''PackingList_'' + OH.PackingListFormat, ''PackingList'', ''Order-'' + L.PickTicketNo, OH.NumLines,
                                     ETP.RecordId, 4
                              from LPNs L
                                join #EntitiesToPrint ETP on (L.LPNId    = ETP.EntityId)
                                join OrderHeaders     OH  on (OH.OrderId = L.OrderId)
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (ETP.WaveType = ''BPP'') and
                                    (dbo.fn_GetMappedValue(''CIMS'', ETP.SoldToId, ''CIMS'', ''BPP_PackingListType'', null, L.BusinessUnit) = ''Combo'');

                            /* Insert Append report */
                            exec pr_Printing_GetAppendReport',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print combo PL for required Waves (LPNWithODs)- There could be a master page and an additional page. Master page has
   the shipping label and the additional page does not. This rule will insert both Master & Append pages */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Pick & Pack/Combo PL(LPNWithODs): Print combo Packing List always for each LPN',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType,
                                                    DocumentFormat, DocumentSchema, ParentEntityKey, NumDetails,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Report'', ''RDLC'', ''PL'', ''LPNWithODs'',
                                     ''PackingList_'' + OH.PackingListFormat, ''PackingList'', ''Order-'' + L.PickTicketNo, OH.NumLines,
                                     ETP.RecordId, 4
                              from LPNs L
                                join #EntitiesToPrint ETP on (L.LPNId    = ETP.EntityId)
                                join OrderHeaders     OH  on (OH.OrderId = L.OrderId)
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (ETP.WaveType = ''BPP'');

                            /* Insert Append report */
                            exec pr_Printing_GetAppendReport',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print 4x6 Small package label for non PTS */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Small Package label: Print 4x6 format label for non PTS',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''SPL'', ''Ship_4x6_SPL'',
                                     ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'') and
                                    (ETP.WaveType <> ''PTS'') and (ETP.IsSmallPackageCarrier = ''Y'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Entity = Load */
/******************************************************************************/

/*-------------------------------------------------------------------------------------------------------------*/
/* Print BoLs for the load */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Load : Print BoLs',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType,
                                                    DocumentFormat, DocumentSchema, ParentEntityKey,
                                                    InputRecordId, SortSeqNo)
                              select ''Load'', L.LoadId, L.LoadNumber, ''Report'', ''RDLC'', ''BL'', '''',
                                     ''VICSBoLMaster'', ''VICSBoL'', ''Load-'' + L.LoadNumber,
                                     ETP.RecordId, 1
                              from Loads L
                                join #EntitiesToPrint ETP on L.LoadId = ETP.EntityId
                              where (ETP.EntityType = ''Load'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print Shipping Manifest for the load */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Load: Print Shipping Manifest',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentSubType,
                                                    DocumentFormat, DocumentSchema, ParentEntityKey,
                                                    InputRecordId, SortSeqNo)
                              select ''Load'', L.LoadId, L.LoadNumber, ''Report'', ''RDLC'', ''SM'', '''',
                                     ''ShippingManifestMaster'', ''ShippingManifest'', ''Load-'' + L.LoadNumber,
                                     ETP.RecordId, 2
                              from Loads L
                                join #EntitiesToPrint ETP on L.LoadId = ETP.EntityId
                              where (ETP.EntityType = ''Load'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Order Packing List: For all Orders on the loads */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Order: Print Packing list if required for Orders on the load',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass,
                                                    DocumentType, DocumentSubType, DocumentFormat, DocumentSchema, ParentEntityKey,
                                                    InputRecordId, SortSeqNo)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''Report'', ''RDLC'',
                                     ''PL'', ''ORD'', ''PackingList_'' + OH.PackingListFormat, ''PackingList'', ''Order-'' + OH.PickTicket,
                                     ETP.RecordId, 3
                              from vwLoadOrders OH
                              join #EntitiesToPrint ETP on ETP.EntityId = OH.LoadId
                              where (ETP.EntityType = ''Load'') and (coalesce(OH.PackingListFormat, '''') > '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Determine Packing List Details to print for the PLs */
/******************************************************************************/

/*-------------------------------------------------------------------------------------------------------------*/
/* For some formats, we need to print Order Packing list with the details of each carton in the Order, so
   change the DocumentSubType */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PL Details: For some PL formats, we have to print ORDWithLDs',
       @vRuleQuery       = 'Update PL
                            set DocumentSubType = ''ORDWithLDs''
                            from #PrintList PL join OrderHeaders OH on PL.EntityId = OH.OrderId
                            where (PL.DocumentType = ''PL'') and (PL.DocumentSubType = ''ORD'') and
                                  (PL.EntityType = ''Order'') and
                                  ((OH.PackingListFormat like ''%401'') or
                                   (OH.PackingListFormat like ''%402'') or
                                   (OH.PackingListFormat like ''%521''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA'/* Active, InActive, NotApplicable */,
       @vSortSeq         = 90;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* LOAD Print List
*/
/******************************************************************************/

/******************************************************************************/
/* Rule Set to Load the Print list of selected entities */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_ShippingDocs_LoadList',
       @vRuleSetFilter      = '~Action~ = ''LoadPrintList''',
       @vRuleSetDescription = 'Print List Load: Load the list of selected entities into Print list',
       @vSortSeq            =  90,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Rule: Load the print list from Print job info from print jobs */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Load the print list from print list info from the print jobs',
       @vRuleQuery       = 'declare @vPrintListXML XML;

                            select @vPrintListXML = cast(PrintJobInfo as xml) from PrintJobs where PrintJobId = ~PrintJobId~;

                            insert into #PrintList(EntityType, EntityKey, EntityId, PrintRequestId, PrintJobId, DocumentClass,
                                                   DocumentSubClass, DocumentType, DocumentSubType, PrintDataFlag, DocumentFormat, DocumentSchema,
                                                   PrintData, AdditionalContent, PrinterName, PrinterConfigName, PrinterConfigIP, PrinterPort,
                                                   PrintProtocol, PrintBatch, NumCopies, SortOrder, InputRecordId, Status,
                                                   Description, Action, CreateShipment, FilePath, FileName, SortSeqNo,
                                                   ParentEntityKey, UDF1, UDF2, UDF3, UDF4, UDF5, ParentRecordId)
                              select Record.Col.value(''EntityType[1]'',  ''TEntity''), Record.Col.value(''EntityKey[1]'', ''TEntityKey''), Record.Col.value(''EntityId[1]'', ''TRecordId''),
                                     Record.Col.value(''PrintRequestId[1]'', ''TRecordId''), Record.Col.value(''PrintJobId[1]'', ''TRecordId''), Record.Col.value(''DocumentClass[1]'', ''TTypeCode''),
                                     Record.Col.value(''DocumentSubClass[1]'', ''TTypeCode''), Record.Col.value(''DocumentType[1]'', ''TTypeCode''), Record.Col.value(''DocumentSubType[1]'', ''TTypeCode''),
                                     ''Required'', Record.Col.value(''DocumentFormat[1]'', ''TName''), Record.Col.value(''DocumentSchema[1]'', ''TName''),
                                     Record.Col.value(''PrintData[1]'', ''TBinary''), Record.Col.value(''AdditionalContent[1]'', ''TName''), Record.Col.value(''PrinterName[1]'', ''TName''),
                                     Record.Col.value(''PrinterConfigName[1]'', ''TName''), Record.Col.value(''PrinterConfigIP[1]'', ''TName''), Record.Col.value(''PrinterPort[1]'', ''TName''),
                                     Record.Col.value(''PrintProtocol[1]'', ''TName''), Record.Col.value(''PrintBatch[1]'', ''TInteger''), Record.Col.value(''NumCopies[1]'', ''TInteger''),
                                     Record.Col.value(''SortOrder[1]'', ''TSortOrder''), Record.Col.value(''InputRecordId[1]'', ''TRecordId''), Record.Col.value(''Status[1]'', ''TStatus''),
                                     Record.Col.value(''Description[1]'', ''TDescription''), Record.Col.value(''Action[1]'', ''TFlags''), Record.Col.value(''CreateShipment[1]'', ''TFlags''),
                                     Record.Col.value(''FilePath[1]'', ''TName''), Record.Col.value(''FileName[1]'', ''TName''), Record.Col.value(''SortSeqNo[1]'', ''TSortSeq''),
                                     Record.Col.value(''ParentEntityKey[1]'', ''TEntityKey''), Record.Col.value(''UDF1[1]'', ''TUDF''), Record.Col.value(''UDF2[1]'', ''TUDF''),
                                     Record.Col.value(''UDF3[1]'', ''TUDF''), Record.Col.value(''UDF2[1]'', ''TUDF''), Record.Col.value(''UDF5[1]'', ''TUDF''), Record.Col.value(''ParentRecordId[1]'', ''TRecordId'')
                              from @vPrintListXML.nodes(''/PrintList/PrintListRecord'') as Record(Col);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rule Set : Determine which labels to print for Outbound from Packing */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PrintList_Packing';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Identify the list of labels/reports for the given entities */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_Packing_GeneratePrintList',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Packing: Determine which labels to print for Orders',
       @vSortSeq            =  0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/******************************************************************************/
/* Entity = ORDER

  The rules to generate documents for any given order in EntitiesToPrint are

  If the Order is completely packed then
  a. Print Content Labels for all LPNs if ther is one
  b. Print UCC128 Label/Small package label
  c. Print order packing list
*/
/******************************************************************************/
/*-------------------------------------------------------------------------------------------------------------*/
/* Packing: Print Content Labels for all the LPNs when order is completely packed */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing: Print Content Labels for all the LPNs when order is completely packed',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    AdditionalContent, InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''CL'', OH.ContentsLabelFormat,
                                     ''ContentsLabel'', ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.OrderId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''Order'') and (L.LPNType = ''S'' /* ShipCarton */) and
                                    (coalesce(OH.ContentsLabelFormat, '''') > '''') and
                                    (dbo.fn_IsInList(ETP.OrderStatus, ''KGLS'' /* Packed, Staged, Loaded, Shipped */) > 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* In-Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Packing: Print UCC128 Labels for all the LPNs when order is completely packed */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing: Print UCC128 Labels for all the LPNs when order is completely packed',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    AdditionalContent, InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''SL'', OH.UCC128LabelFormat,
                                     '''', ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.OrderId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''Order'') and (L.LPNType = ''S'' /* ShipCarton */) and
                                    (coalesce(OH.UCC128LabelFormat, '''') > '''') and
                                    (dbo.fn_IsInList(ETP.OrderStatus, ''KGLS'' /* Packed, Staged, Loaded, Shipped */) > 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Packing: Print 4x6 Small package label if the order is packed */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing: Print 4x6 Small package label if the order is packed',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    AdditionalContent, InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''SPL'', ''Ship_4x6_SPL'',
                                     ''PickingLabel_4x8'', ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.OrderId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''Order'') and (L.LPNType = ''S'' /* ShipCarton */) and
                                    (dbo.fn_IsInList(ETP.OrderStatus, ''KGLS'' /* Packed, Staged, Loaded, Shipped */) > 0) and
                                    (ETP.IsSmallPackageCarrier = ''Y'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Packing: Print packing list if the order is completely packed */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing: Print packing list if the order is completely packed',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass,
                                                    DocumentType, DocumentSubType, DocumentFormat, DocumentSchema, ParentEntityKey,
                                                    InputRecordId, SortSeqNo)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''Report'', ''RDLC'',
                                     ''PL'', ''ORD'', OH.PackingListFormat, ''PackingList'', ''Order-'' + OH.PickTicket,
                                     ETP.RecordId, 2
                              from OrderHeaders OH
                                 join #EntitiesToPrint ETP on ETP.EntityId = OH.OrderId
                              where (ETP.EntityType = ''Order'') and (coalesce(OH.PackingListFormat, '''') > '''') and
                                    (dbo.fn_IsInList(ETP.OrderStatus, ''KGLS'' /* Packed, Staged, Loaded, Shipped */) > 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Entity = LPN

   There could be various scenarios, so alter the rule to suit as per client requirements.

   a. Print Contents Label of there is one
   b. Print Packing Label if there is no other label for the LPN
*/
/******************************************************************************/
/*-------------------------------------------------------------------------------------------------------------*/
/* Packing: Print contents label if there is one */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing: Print contents label if there is one',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    AdditionalContent, InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''CL'', OH.ContentsLabelFormat,
                                     '''', ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'' /* ShipCarton */) and
                                    (coalesce(OH.ContentsLabelFormat, '''') > '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Print Packing Label if there is no other label for the LPN */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Print Packing Label if there is no other label for the LPN',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType, DocumentFormat,
                                                    AdditionalContent, InputRecordId, SortSeqNo)
                              select ''LPN'', L.LPNId, L.LPN, ''Label'', ''ZPL'', ''PCKL'', ''Packing_4x6_LPNLabel'',
                                     ''PackingLabel'', ETP.RecordId, coalesce(L.PackageSeqNo, 0) * 10 + 4
                              from LPNs L
                                join #EntitiesToPrint ETP on L.LPNId = ETP.EntityId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                                left outer join #PrintList PL on L.LPNId = PL.EntityId and
                                                                 PL.EntityType = ''LPN''
                              where (ETP.EntityType = ''LPN'') and (L.LPNType = ''S'' /* ShipCarton */) and
                                    (PL.RecordId is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rule Set: Post process update the print list with necessary actions as required */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PrintList_PostProcess';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* POST PROCESS

  There are several actions to be taken after the print list is determined above as follows:

  a. Ignore any records that do not have a document format
  b. Set up the sort order
  c. Setup the appropriate printer
  d. Setup description for each entity when the request mode is interactive
*/
/******************************************************************************/

/******************************************************************************/
/* Rule Set to finalize the PrintList File names, path and sort order */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_PostProcess_FilePath&Sort',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Print List process: once Print list is determined, then do a post process i.e. setup some defaults etc.',
       @vSortSeq            =  100,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Default file path */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'File Path - Default: Setup default path to be BU/Date',
       @vRuleQuery       = 'update PL
                            set FilePath = ~BusinessUnit~ + ''\'' + convert(varchar, getdate(), 23)
                            from #PrintList PL
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Save the ZPL label data for Orders, which are ship from contractor Warehouses */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'File Path/Name - ZPL: Save the ZPL label data to WH folder for Orders',
       @vRuleQuery       = 'Update PL
                            set FileName = concat_ws(''-'', coalesce(OH.CustPO, OH.PickTicket), OH.PickBatchNo, ''DC'' + coalesce(OH.ShipToStore, ''0000''),
                                                            ~PrintJobId~,  ''zpl.txt''),
                                FilePath = ''ShippingDocs\WH'' + OH.ShipFrom
                            from #PrintList PL
                              join LPNs L on (L.LPNId = PL.EntityId)
                              left outer join OrderHeaders OH on (OH.OrderId = L.OrderId)
                            where (PL.DocumentSubClass = ''ZPL'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* For all Waves, save the files in WH<ShipFrom>. Note that action is always P even when
   user chooses SaveReportToFile because PrintManager sees it as Printing to PDF */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'FilePath - Packing List: Save in WH-ShipFrom folder',
       @vRuleQuery       = 'Update PL
                            set FilePath = ''ShippingDocs\WH'' + ETP.ShipFrom
                            from #PrintList PL
                              join #EntitiesToPrint ETP on (PL.InputRecordId = ETP.RecordId)
                            where (PL.DocumentType = ''PL'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* For all Waves, save each job as a single file with WaveNo, have to include PrintJobId one wave be split into
   multiple print jobs for Order packing lists */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'FileName - Packing List: Save the Order PLs with WaveNo and PrintJobId',
       @vRuleQuery       = 'Update PL
                            set FileName = coalesce(OH.CustPO, OH.PickTicket) + ''-'' + coalesce(OH.UDF16,'''') + ''-DC'' + coalesce(OH.ShipToStore, ''0000'') + ''-'' + cast(coalesce(~PrintJobId~, 0) as varchar)
                            from #PrintList PL
                              join OrderHeaders OH on (PL.EntityId = OH.OrderId)
                            where (PL.DocumentClass = ''Report'') and
                                  (PL.DocumentType = ''PL'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Some Customers do not require Contents labels when processed as Case Pick */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Contents Label: Not needed when WaveType is CasePick except for some customers',
       @vRuleQuery       = 'delete PL
                            from #PrintList PL join #EntitiesToPrint ETP on PL.InputRecordId = ETP.RecordId
                            where (ETP.WaveType = ''BCP'') and (PL.DocumentType = ''CL'') and
                                  (PL.DocumentFormat like ''%217'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/*
  update SortOrder for labels and reports. The Sortorder is typically established in EntitiesToPrint. For the
  same entity, if there are multiple items to print, then the SortSeqNo determines the sequence of them. So,
  the final SortOrder is a combination of ETP.SortOrder and PL.SortSeq
*/
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Sort Order for the labels and reports from ETP',
       @vRuleQuery       = 'Update PL
                            set SortOrder   = case when DocumentClass = ''Label''
                                                     then case when ETP.WaveType = ''BPP'' then coalesce(ETP.CustPO, '''') + ''-'' + coalesce(ETP.ShipToStore, '''') + ''-'' + coalesce(cast(L.OrderId as varchar), '''') + ''-'' + dbo.fn_LeftPadNumber(SortSeqNo, 5)
                                                               when ETP.WaveType = ''BCP'' then coalesce(ETP.CustPO, '''') + ''-'' + coalesce(ETP.ShipToStore, '''') + ''-'' + coalesce(L.SKU, '''') + ''-'' + coalesce(cast(L.OrderId as varchar), '''') + ''-'' + dbo.fn_LeftPadNumber(SortSeqNo, 5)
                                                          end
                                                   else coalesce(ETP.SortOrder, '''') + ''-'' + dbo.fn_LeftPadNumber(SortSeqNo, 5)
                                              end
                            from #PrintList PL
                              join #EntitiesToPrint ETP on PL.InputRecordId = ETP.RecordId
                              left outer join LPNs L on L.LPNId = ETP.EntityId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/*
  update SortOrder with respect to the document types
*/
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Sort Order with respect to the document type',
       @vRuleQuery       = 'Update PL
                            set SortOrder   = concat_ws(''-'', PL.SortOrder,
                                                        case
                                                          when PL.DocumentType = ''WL''   then ''01''
                                                          when PL.DocumentType = ''STL''  then ''02''
                                                          when PL.DocumentType = ''SL''   then ''03''
                                                          when PL.DocumentType = ''CL''   then ''04''
                                                          when PL.DocumentType = ''SPL''  then ''05''
                                                          when PL.DocumentType = ''PCKL'' then ''06''
                                                          else ''09''
                                                        end)
                            from #PrintList PL',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Update description for document nodes  */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Description',
       @vRuleQuery       = 'Update PL
                            set Description = case when DocumentFormat like ''%_AP''
                                                   then ''Additional Pages of '' + L.LookUpDescription + '' for '' + PL.EntityKey
                                                   when DocumentFormat like ''Ship%PTS''
                                                   then ''Packing Label for'' + PL.EntityKey
                                              else L.LookUpDescription + '' for '' + PL.EntityKey
                                              end
                            from #PrintList PL
                              join Lookups L on (L.LookupCategory = ''DocumentType'') and (L.LookupCode = PL.DocumentType)
                            where (Description is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set to finalize the PrintList Updates.
   The sort seq no is particularly updated for this to be a higher range to indicate that the following rules are generic and don't change from client to client */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_PostProcess_Final',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Print List process: once Print list is determined, then do a post process i.e. setup some defaults etc.',
       @vSortSeq            =  900,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* For Shipping Docs operation, PrintList may be printed by UI or JobProcessor, so when printing from UI,
   if there are too many to print, we have to defer it the Job Processor - we do this by setting PrintDataFlag
   to Defer so that it would be processed later. When the Job processor invokes the same rules though we wouldn't
   have this restriction and hence this rule applies only when not invoked by PrintJobProcessor */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = 'coalesce(~Processor~ , '''') <> ''PrintJobProcessor'' ',
       @vRuleDescription = 'Ignore the Print data process if print list count crosses the threshold',
       @vRuleQuery       = 'update PL
                            set PrintDataFlag = ''Defer''
                            from #PrintList PL
                            where ((select count(*) from #PrintList) > 100)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Update the remaining records print data flag */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Print List: Set default for PrintDataFlag based upon document library',
       @vRuleQuery       = 'update PL
                            set PrintDataFlag = case when (DL.Status = ''Active'') then ''PreGenerated'' else ''Required'' end
                            from #PrintList PL
                              left join DocumentLibrary DL on (DL.EntityId = PL.EntityId) and (DL.EntityType = PL.EntityType) and (DL.DocumentType = PL.DocumentType)
                            where PrintDataFlag is null',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Update PrinterName for the Labels and Reports */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the PrinterName for the labels and reports from ETP',
       @vRuleQuery       = 'Update PL
                            set PrinterName = coalesce(ETP.LabelPrinterName,
                                                       case when DocumentClass = ''Label'' then ~LabelPrinterName~
                                                            when Documentclass = ''Report'' then ~ReportPrinterName~
                                                       end)
                            from #PrintList PL join #EntitiesToPrint ETP on PL.InputRecordId = ETP.RecordId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Update Printer unified name for the Print list */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update the Printer unified name',
       @vRuleQuery       = 'Update PL
                            set PrinterName = VP.PrinterNameUnified
                            from #PrintList PL join vwPrinters VP on PL.PrinterName = VP.PrinterName',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Save the ZPL label data only if user selected PrintToFile option */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = '~LabelPrinterName~ like ''SaveLabelToFile%''',
       @vRuleDescription = 'Action - ZPL: If user save to file, then just save it',
       @vRuleQuery       = 'update PL
                            set Action = ''S''
                            from #PrintList PL
                            where (PL.DocumentSubClass = ''ZPL'');
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Save the Report PDF only if user selected SaveReportToFile option */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = '~ReportPrinterName~ like ''SaveReportToFile%''',
       @vRuleDescription = 'Action - Report: If user save to file, then just save it',
       @vRuleQuery       = 'update PL
                            set Action = ''S''
                            from #PrintList PL
                            where (PL.DocumentSubClass = ''RDLC'');
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Update the remaining records print data flag */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Print List/Action: Set default to Print',
       @vRuleQuery       = 'update PL
                            set Action = ''P''
                            from #PrintList PL
                            where (Action is null) or (Action = '''')
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Ignore the record if the document format is unknown */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Disable printing of documents which do not have a format',
       @vRuleQuery       = 'Update #PrintList
                            set Action        = ''I'',
                                PrintDataFlag = ''Ignore''
                            where coalesce(DocumentFormat, '''') = ''''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* In Dev & Staging, save ZPL for debugging purposes as sometimes we are missing info on labels. If this is
   need in production, then comment out the rule condition */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = '(DB_Name() like ''%Staging'') or (DB_Name() like ''%Dev'')',
       @vRuleDescription = 'Save the ZPL label data for all Orders for debugging',
       @vRuleQuery       = 'Update PL
                            set Action  += ''S''
                            from #PrintList PL
                              join #EntitiesToPrint ETP on (PL.InputRecordId = ETP.RecordId)
                            where (PL.DocumentSubClass = ''ZPL'') and
                                  (PL.Action = ''P'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I'/* InActive */, -- Not needed anymore as we have provision to Save the files
       @vSortSeq         = 997;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* Remove the special characters from the file name to avoid the exceptions */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Remove the special characters from the file name',
       @vRuleQuery       = 'Update PL
                            set FileName = dbo.fn_RemoveSpecialCharsExceptSelected(FileName, ''.,_,-'')
                            from #PrintList PL
                            where FileName is not null
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 998;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* In Staging/Dev, only print first 10 reports if printing reports to printer */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = '((DB_Name() like ''%Staging'') or (DB_Name() like ''%Dev'')) and
                            (~ReportPrinterName~ not like ''SaveReportToFile%'')',
       @vRuleDescription = 'Print only few reports when testing',
       @vRuleQuery       = 'update #PrintList
                            set Action = ''I''
                            where (DocumentClass = ''Report'') and
                                  (RecordId not in (select top 10 RecordId from #PrintList
                                                    where DocumentClass = ''Report''
                                                    order by SortOrder))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 999;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*-------------------------------------------------------------------------------------------------------------*/
/* In Staging/Dev, only print first 10 labels if printing labels to printer */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = '((DB_Name() like ''%Staging'') or (DB_Name() like ''%Dev'')) and
                            (~LabelPrinterName~ not like ''SaveLabelToFile%'')',
       @vRuleDescription = 'Print only few labels when testing',
       @vRuleQuery       = 'update #PrintList
                            set Action = ''I''
                            where (DocumentClass = ''Label'') and
                                  (RecordId not in (select top 10 RecordId from #PrintList
                                                    where DocumentClass = ''Label''
                                                    order by SortOrder))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 999;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
