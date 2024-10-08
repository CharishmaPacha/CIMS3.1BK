/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/05/27  RV      Packing Slip Details: Port back from onsite Prod (BK-849)
  2022/04/15  TK      If OD.UnitSalePrice is not given use SKU.UnitPrice (BK-797)
  2021/11/23  AY      Bug fix: LPNWithLDs should print only LPN details (BK-701)
  2021/08/27  TK      Consider UnitsBackordered from view (BK-530)
  2021/07/30  SJ      PackingListDetails: Excluded Component SKUs (OB2-1960)
  2021/06/30  RV      update UOM and SKU display description (OB2-1822)
  2021/06/23  KBB     ORDWithLDs:Inclued Pallet (HA-2906)
  2021/06/22  PHK     ORDWithLDs: Included Weight, TrackingNo (BK-372)
  2021/05/11  TK      PackingListDetails_Finalize: Update CoO (HA-2759)
  2021/02/24  AY      Generate PL details in order they appear in Order (HA Mock GoLive)
  2020/09/30  AY      Populate NumCartons for the ORD PL (HA-1466)
  2020/08/05  PHK/MS  Corrections to print Price on Commersial Invoice (CID-1458)
  2020/07/24  RT      Included LPNId and LPNDetailId, in case Printing all the details in the first carton, then we are getting same SortOrder
                      for few lines because of LPNs having same SKU (HA-597)
  2020/07/02  MS      Changes to get UnitsAssigned from views (HA-1046)
  2020/07/01  PHK     Changes to get the Quantity (HA-924 & HA-925)
  2020/06/30  AY      Added option LDwithLDs to print carton level details on the combo packing list (HA-857)
              RV      PackingListDetails_SummarizeBySKU, PackingListDetails_HOST: Corrected rules syntaxes (HA-1053)
  2020/06/03  PHK     Changes to get UnitSalePrice, RetailUnitPrice, TrackingNo, UPC, UCCBarcode (HA-597)
  2020/05/20  RV      PackingListDetails_Finalize: Rule changed to padding 4 digits as some times crossing packages 3 digits (CID-1435)
  2019/08/28  RT      Added SKUId along with HostOrderLine to group by (HPI-2713)
  2019/08/21  MS      Changes to update sortorder field (HPI-2700)
  2019/08/09  MS      Changes to update Unitsordered & BackOrdqty on PackingSlips (HPI-2691)
  2019/08/07  MS      Changes to update datasets for PackingSlips (HPI-2656)
  2019/08/01  MS      Initial version (HPI-2656)
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
/* Rules for : PackingList Details */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PackingListDetails';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - PackingList - Summarize by SKU */
/******************************************************************************/
select @vRuleSetName        = 'PackingListDetails_SummarizeBySKU',
       @vRuleSetFilter      = '~SourceSystem~ = ''SAP''',
       @vRuleSetDescription = 'Summarize details by SKUId',
       @vSortSeq            = 0, -- Initialize for this set
       @vStatus             = 'A' /* A-Active , I-InActive , NA-Not applicable */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - ORD PackingList */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ = ''ORD'' and charindex(~Report~, ''Matrix'') > 0',
       @vRuleDescription = 'Rule for Packing Slip where we pivot by Size',
       @vRuleQuery       = 'insert into #ttPackingListDetails
                               (SKU1, SKU2, SKU3, SKUDescription, CustSKU, HostLineNo, RetailUnitPrice,
                                UnitSalePrice, LineTotalAmount, Value1, Value2, TotalValue, RecordId)
                              select SKU1, SKU2, SKU3, SKUDescription, CustSKU, HostLineNo, RetailUnitPrice,
                                     UnitSalePrice, LineTotalAmount, Value1, Value2, TotalValue, RecordId
                              from fn_Shipping_GetPackingListMatrix(~OrderId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/*  Rule - ORD PackingList - Summarize by SKU */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ in (''ORD'', ''LPNWithODs'')',
       @vRuleDescription = 'Packing Slip Details: Summarized for ORD/LPNWithODs',
       @vRuleQuery       = 'insert into #ttPackingListDetails
                                (SKUId, OrderId, OrderDetailId,
                                 SKU, SKUDescription, OD_UDF4,
                                 PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                 UnitsOrdered, UnitsShipped, UnitsAuthorizedToShip,
                                 UnitsAssigned, BackOrdered, UnitSalePrice, RetailUnitPrice, UPC, UCCBarcode,CustSKU, RecordId)
                              select min(SKUId), min(OrderId), min(OrderDetailId),
                                     min(SKU), min(SKUDescription), min(OD_UDF4),
                                     min(PL_UDF1), min(PL_UDF2), min(PL_UDF3), min(PL_UDF4), min(PL_UDF5),
                                     sum(UnitsOrdered), sum(UnitsShipped), sum(UnitsAuthorizedToShip),
                                     sum(UnitsAssigned), sum(BackOrdered), sum(UnitSalePrice), sum(RetailUnitPrice),
                                     min(UPC), min(UCCBarcode), min(CustSKU), row_number() over (order by HostOrderLine)
                              from vwPackingListDetails
                              where (OrderId = ~OrderId~)
                              group by SKUId, HostOrderLine',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/*  Rule - LPN/ReturnLPN PackingList - Summarize by SKU */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ in (''LPN'',''ReturnLPN'' /* for return Packing list */)',
       @vRuleDescription = 'Packing Slip Details: Summarize by SKU for LPN/ReturnLPN',
       @vRuleQuery       = 'insert into #ttPackingListDetails
                                (SKUId, LPNId, LPNDetailId, PackageSeqNo, Quantity, OrderId, OrderDetailId,
                                 SKU, SKUDescription, OD_UDF4, CoO,
                                 PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                 UnitsOrdered, UnitsShipped, UnitsAuthorizedToShip,
                                 UnitsAssigned, BackOrdered, UnitSalePrice, RetailUnitPrice, TrackingNo, UPC, UCCBarcode, CustSKU, RecordId)
                              select min(SKUId), min(LPNId), min(LPNDetailId), min(PackageSeqNo), sum(Quantity), min(OrderId), min(OrderDetailId),
                                     min(SKU), min(SKUDescription),min(OD_UDF4), min(CoO),
                                     min(PL_UDF1), min(PL_UDF2), min(PL_UDF3), min(PL_UDF4), min(PL_UDF5),
                                     sum(UnitsOrdered), sum(UnitsShipped), sum(UnitsAuthorizedToShip),
                                     sum(UnitsAssigned), sum(BackOrdered), sum(UnitSalePrice), sum(RetailUnitPrice), min(TrackingNo)
                                     min(UPC), min(UCCBarcode), min(CustSKU), row_number() over (order by HostOrderLine)
                              from vwLPNPackingListDetails
                              where (LPNId = ~LPNId~)
                              group by SKUId, HostOrderLine',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set #2 - PackingList - HOST */
/******************************************************************************/
select @vRuleSetName        = 'PackingListDetails_HOST',
       @vRuleSetFilter      = '~SourceSystem~ = ''HOST''',
       @vRuleSetDescription = 'Rule Set to generate PackingListDetails as is (not summarized)',
       @vStatus             = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq           += 1;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/*  Rule - ORD/LPNWithODs PackingList */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ in (''ORD'', ''LPNWithODs'')',
       @vRuleDescription = 'Rule ORD/LPNWithODs PackingSlip',
       @vRuleQuery       = 'insert into #ttPackingListDetails
                                (SKUId, OrderId, OrderDetailId,
                                 PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                  UnitsAssigned, BackOrdered, RecordId)
                               select SKUId, OrderId, OrderDetailId,
                                      PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                       UnitsAssigned, BackOrdered, row_number() over (order by HostOrderLine)
                               from vwPackingListDetails
                               where (OrderId = ~OrderId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/*  Rule - ORDWithLDs PackingList */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ in (''ORDWithLDs'')',
       @vRuleDescription = 'Rule ORDWithLDs PackingSlip',
       @vRuleQuery       = 'insert into #ttPackingListDetails
                                (SKUId, OrderId, OrderDetailId, LPNId, Quantity, CoO, Weight, TrackingNo, Pallet,
                                 PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                 UnitsAssigned, BackOrdered, RecordId)
                               select SKUId, OrderId, OrderDetailId, LPNId, Quantity, CoO, Weight, TrackingNo, Pallet,
                                      PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                      UnitsAssigned, BackOrdered, row_number() over (order by HostOrderLine)
                               from vwLPNPackingListDetails
                               where (OrderId = ~OrderId~) and (UnitsAssigned > 0) and (LPNType like ''S'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;


/*----------------------------------------------------------------------------*/
/*  Rule - LPNWithLDs PackingList */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ in (''LPNWithLDs'')',
       @vRuleDescription = 'Rule LPNWithLDs PackingSlip',
       @vRuleQuery       = 'insert into #ttPackingListDetails
                              (SKUId, LPNId, Quantity, OrderId, OrderDetailId, CoO,
                               PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                               UnitsAssigned, BackOrdered, RecordId)
                             select SKUId, LPNId, Quantity, OrderId, OrderDetailId, CoO,
                                    PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                    UnitsAssigned, BackOrdered,
                                    row_number() over (order by HostOrderLine)
                             from vwLPNPackingListDetails
                             where (LPNId = ~LPNId~) and (LPNType = ''S'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/*  Rule - ORDWithLDs PackingList with short lines at the end */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ in (''ORDWithLDs'')',
       @vRuleDescription = 'Rule ORDWithLDs PackingSlip with missing Lines',
       @vRuleQuery       = 'insert into #ttPackingListDetails
                                (SKUId, OrderId, OrderDetailId,
                                 PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                 UnitsAssigned, BackOrdered, RecordId)
                               select SKUId, OrderId, OrderDetailId,
                                      PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                      UnitsAssigned, BackOrdered, row_number() over (order by HostOrderLine)
                               from vwPackingListDetails
                               where (OrderId = ~OrderId~) and (UnitsAuthorizedToShip > 0) and (UnitsAssigned = 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/*  Rule - LPN/ReturnLPN PackingList - HOST */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ in (''LPN'', ''ReturnLPN'' /* for return Packing list */)',
       @vRuleDescription = 'Rule LPN/ReturnLPN  PackingSlip',
       @vRuleQuery       = 'insert into #ttPackingListDetails
                               (SKUId, LPNId, LPNDetailId, Quantity, OrderId, OrderDetailId, CoO,
                                PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                UnitsAssigned, BackOrdered, RecordId)
                              select SKUId, LPNId, LPNDetailId, Quantity, OrderId, OrderDetailId, CoO,
                                     PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5,
                                     UnitsAssigned, BackOrdered, row_number() over (order by HostOrderLine)
                              from vwLPNPackingListDetails
                              where (LPNId = ~LPNId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/* Finalize rules are several sets of rules for the Packing List details that
   would update all the relevant info:
   a. OrderDetail info
   b. SKU info
   c. Determine to show/hide BackOrderQty
   d. Determine to show/hide pricing info
   e. Sort Order
   f. Determine rows that would be needed for each detail (as some lines may need
      a group header or footer or a multi-line display with barcodes etc.). So,
      one PL detail may physically span more than one row on the physical report.
 */
/******************************************************************************/
select @vRuleSetType = 'PackingListDetails_Finalize';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* PackingListDetails Finalize - Update Order Detail/SKU info */
/******************************************************************************/
select @vRuleSetName        = 'PackingListDetails_UpdateODSKU',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rule Set to update Order Detail/SKU info on PackingListDetails ',
       @vStatus             = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq           += 1;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* update Order Detail info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing Slip Details: Update OrderDetail Info',
       @vRuleQuery       = 'update PLD
                            set CustSKU               = OD.CustSKU,
                                OrderLine             = OD.OrderLine,
                                HostOrderLine         = OD.HostOrderLine,
                                LineType              = OD.LineType,
                                UnitSalePrice         = OD.UnitSalePrice,
                                RetailUnitPrice       = OD.RetailUnitPrice,
                                LineTotalAmount       = PLD.Quantity * OD.UnitSalePrice,
                                UnitsOrdered          = OD.UnitsOrdered,
                                UnitsShipped          = OD.UnitsShipped,
                                UnitsAuthorizedToShip = OD.UnitsAuthorizedToShip,
                                OD_UDF1               = OD.UDF1,
                                OD_UDF2               = OD.UDF2,
                                OD_UDF3               = OD.UDF3,
                                OD_UDF4               = OD.UDF4,
                                OD_UDF5               = OD.UDF5,
                                OD_UDF6               = OD.UDF6,
                                OD_UDF7               = OD.UDF7,
                                OD_UDF8               = OD.UDF8,
                                OD_UDF9               = OD.UDF9,
                                OD_UDF10              = OD.UDF10
                            from #ttPackingListDetails PLD
                              join OrderDetails OD on (PLD.OrderDetailId = OD.OrderDetailId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* update SKU info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing Slip Details: Update SKU info',
       @vRuleQuery       = 'update PLD
                            set SKU  = S.SKU,
                                SKU1 = S.SKU1,
                                SKU2 = S.SKU2,
                                SKU3 = S.SKU3,
                                SKU4 = S.SKU4,
                                SKU5 = S.SKU5,
                                SKUDescription  = S.Description,
                                SKU1Description = S.SKU1Description,
                                SKU2Description = S.SKU2Description,
                                SKU3Description = S.SKU3Description,
                                SKU4Description = S.SKU4Description,
                                SKU5Description = S.SKU5Description,
                                DisplaySKU      = S.DisplaySKU,
                                DisplaySKUDesc  = S.DisplaySKUDesc,
                                UPC             = S.UPC,
                                CoO             = coalesce(CoO, S.DefaultCoO),
                                UOM             = S.UOM,
                                HarmonizedCode  = S.HarmonizedCode
                            from #ttPackingListDetails PLD join SKUs S on PLD.SKUId = S.SKUId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* update LPN info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing Slip Details: Update LPN info',
       @vRuleQuery       = 'update PLD
                            set LPN          = L.LPN,
                                UCCBarcode   = L.UCCBarcode,
                                TrackingNo   = L.TrackingNo,
                                PackageSeqNo = L.PackageSeqNo
                            from #ttPackingListDetails PLD join LPNs L on PLD.LPNId = L.LPNId
                            where (PLD.LPNId is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* update NumCartons info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingListType~ in (''ORD'')',
       @vRuleDescription = 'Packing Slip Details: Update NumCartons info',
       @vRuleQuery       = 'with ODNumCartons as
                            (
                              select LD.OrderId, LD.OrderDetailId, count(distinct LD.LPNId) NumCartons
                              from #ttPackingListDetails PLD
                                join LPNDetails LD on (PLD.OrderId = LD.OrderId) and (PLD.OrderDetailId = LD.OrderDetailId)
                              group by LD.OrderId, LD.OrderDetailId
                            )
                            update PLD
                            set NumCartons = OD.NumCartons
                            from #ttPackingListDetails PLD join ODNumCartons OD on PLD.OrderDetailId = OD.OrderDetailId
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* PackingListDetails Finalize - Determine what info may be shown/hidden */
/******************************************************************************/
select @vRuleSetName        = 'PackingListDetails_FinalizeShowHide',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'PackingListDetails Finalize: Show/hide relevant',
       @vStatus             = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq           += 1;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Delete component SKU lines if not required to show on PL */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~ShowComponentSKUsLines~ = ''N''',
       @vRuleDescription = 'PLDetails Finalize: Delete component lines to do not show',
       @vRuleQuery       = 'delete PLD
                            from #ttPackingListDetails PLD
                            where PLD.LineType = ''C'' /* Component SKU */',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* update BackOrderQty for LPNwithOD PL Types */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~Operation~ = ''PickTasks'' and ~WaveType~ = ''PTS''', --MS: SW Wavetype not yet approved in Staging, hence it is not migrated to Prod.
       @vRuleDescription = 'PLDetails Finalize: Update BackOrdered Qty as null , other than 1st Carton ',
       @vRuleQuery       = 'update PLD
                            set UnitsOrdered = null,
                                BackOrdered  = null
                            from #ttPackingListDetails PLD
                            where PLD.PackageSeqNo <> 1',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* PackingListDetails Finalize - Determine how the records would be sorted */
/******************************************************************************/
select @vRuleSetName        = 'PackingListDetails_FinalizeSort',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'PackingListDetails Finalize: Sort Order',
       @vStatus             = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq           += 1;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* update SortOrder: Sort by HostOrderLine and SKU  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PLDetails Finalize: Sort by HostOrder Line & SKU',
       @vRuleQuery       = 'Update #ttPackingListDetails
                            set SortOrder = dbo.fn_Pad(HostOrderLine, 9) + SKU + dbo.fn_LeftPadNumber(OrderDetailId, 8)
                                            + dbo.fn_LeftPadNumber(coalesce(LPNId, 0), 8) + dbo.fn_LeftPadNumber(coalesce(LPNDetailId, 0), 8)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* update SortOrder: Sort by Host OrderLine and then OrderDetailId  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PLDetails Finalize: Sort by HostOrder Line & OrderDetailId',
       @vRuleQuery       = 'Update #ttPackingListDetails
                            set SortOrder = dbo.fn_Pad(HostOrderLine, 9) + dbo.fn_LeftPadNumber(OrderDetailId, 8)
                                            + dbo.fn_LeftPadNumber(coalesce(LPNId, 0), 8) + dbo.fn_LeftPadNumber(coalesce(LPNDetailId, 0), 8)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* update SortOrder: Sort by OrderDetailId  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PLDetails Finalize: Sort by OrderDetailId',
       @vRuleQuery       = 'Update #ttPackingListDetails
                            set SortOrder = dbo.fn_LeftPadNumber(OrderDetailId, 8)
                                            + dbo.fn_LeftPadNumber(coalesce(LPNId, 0), 8) + dbo.fn_LeftPadNumber(coalesce(LPNDetailId, 0), 8)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Delete the lines, since for PTS we will print all LD's in first page of the report
   or for the report which we are printing for first LPN  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~WaveType~ = ''PTS'' and ~PackingListType~ in (''LPNWithODs'') and (~PackageSeqNo~ <> ''1'')',
       @vRuleDescription = 'PL Details: No details to be printed for subsequent cartons on Combo Packing List',
       @vRuleQuery       = 'delete from #ttPackingListDetails where OrderId = ~OrderId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* PackingListDetails Finalize - Update NumRows/Row Counters */
/******************************************************************************/
select @vRuleSetName        = 'PackingListDetails_UpdateNumRows',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rule Set to update Num Rows/Row Counter for each PL Detail',
       @vStatus             = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq           += 1;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Initialize Num rows */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PLDetails Finalize: Initialize NumRows',
       @vRuleQuery       = 'update #ttPackingListDetails
                            set NumRows = 1',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* In some cases, we are printing OD_UDF1, OD_UDF2 and OD_UDF4 as a second row,
   so we need to calculate the NumRows per record to print exact lines on
   first page with label */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PLDetails Finalize: Increment NumRows when detail is to printed on multiple rows',
       @vRuleQuery       = 'update #ttPackingListDetails
                            set NumRows += 1
                            where (OD_UDF1 is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Update Counter: Generate the cumulative Row count in the sequence of Sort order */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'PLDetails Finalize: Compute Counter',
       @vRuleQuery       = ';with CalCummRows (SortOrder, Counter) as
                            (
                             select t1.SortOrder, sum(t2.NumRows)
                             from #ttPackingListDetails t1
                               inner join #ttPackingListDetails t2 on t1.RecordId >= t2.RecordId
                             group by t1.SortOrder, t1.NumRows
                            )
                            update PLD
                            set PLD.Counter = CCR.Counter
                            from #ttPackingListDetails PLD join CalCummRows CCR on PLD.SortOrder = CCR.SortOrder;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
