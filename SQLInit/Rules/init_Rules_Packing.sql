/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/22  OK      Corrected rule to return order information from Packing status LPN as well (BK-703)
  2021/10/26  AY      Added Packing_IdentifyOrder rules (BK-657)
  2021/10/13  RV      Added new rule to send the order details group by key (BK-636)
  2021/07/28  RV      Added rules to delete component lines from packing details
  2021/07/15  OK      Bug fix to allow to pack units from Totes (BK-432)
  2021/04/30  NB      Initial version (CIMSV3-156)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/* Several Rule types implemented in this file
   - Packing_IdentifyOrder
   - Packing_IdentifyType
   - Packing_IdentifyDetails
   - Packing_IdentifyInputForm
   - Packing_AutoShipLPN

*/
/******************************************************************************/

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

/* Rule Conditions and Queries are validated on Insert. This Temp Table is created such that the validations are done correctly */
declare @ttSelectedEntities  TEntityValuesTable;
if (object_id('tempdb..#ttSelectedEntities') is null)
  select * into #ttSelectedEntities from @ttSelectedEntities;

/******************************************************************************/
/******************************************************************************/
/* Rule Set : Identifies the order for selected entity */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Packing_IdentifyOrder';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1     */
/******************************************************************************/
select @vRuleSetName        = 'Packing_IdentifyOrder',
       @vRuleSetFilter      = '(object_id(''tempdb..#ttSelectedEntities'') is not null)',
       @vRuleSetDescription = 'Identify Order based on scanned entity',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 100; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule : Verify if user scanned LPN or cart position  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Identify Order - if user scanned cart position/LPN',
       @vRuleQuery       = 'insert into #ttSelectedEntities (Entityid, EntityKey, EntityType, RecordId)
                              select L.OrderId, L.PickTicketNo, ''Order'', L.LPNId
                              from #ttSelectedEntities SE
                                join LPNs L on L.LPNId = SE.EntityId
                              where SE.EntityType = ''LPN''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Verify if user scanned cart  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Identify order - select an order to pack when user scanned Cart/Pallet',
       @vRuleQuery       = 'insert into #ttSelectedEntities (Entityid, EntityKey, EntityType, RecordId)
                              select top 1 L.OrderId, L.PickTicketNo, ''Order'', OH.OrderId
                              from #ttSelectedEntities SE
                                join Pallets P on P.PalletId = SE.EntityId
                                join LPNs L on L.PalletId = P.PalletId
                                join OrderHeaders OH on OH.OrderId = L.OrderId
                              where (SE.EntityType = ''Pallet'') and
                                    (L.Status in (''K'', ''G'' /* Picked, Packing */))
                              order by L.Status, OH.Priority, OH.CancelDate, OH.DesiredShipDate, OH.OrderId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Delete other entities which are not order
          We are supporting only order entity for now  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Delete other entities which are not an order',
       @vRuleQuery       = 'delete from #ttSelectedEntities
                            where EntityType <> ''Order''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;


/******************************************************************************/
/******************************************************************************/
/* Rule Set : Determine the type of packing needed to be performed for the input */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Packing_IdentifyType';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1     */
/******************************************************************************/
select @vRuleSetName        = @vRuleSetType + '_Order',
       @vRuleSetFilter      = '(object_id(''tempdb..#ttSelectedEntities'') is not null)',
       @vRuleSetDescription = 'Identify Order Packing Type',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 200; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule #1 : Packing Type for Bulk Order  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Packing Type for Bulk Order Wave',
       @vRuleQuery       = 'select top 1 ''BulkOrderPacking''
                            from #ttSelectedEntities SE
                              join OrderHeaders OH1 on (OH1.PickTicket = SE.EntityKey) and (OH1.BusinessUnit = ~BusinessUnit~)
                              join OrderHeaders OH2 on (OH1.PickBatchId = OH2.PickBatchId)
                            where (OH2.OrderType = ''B'')',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule #999 : Default Packing Type  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Packing Type',
       @vRuleQuery       = 'select ''StandardOrderPacking''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 999;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;
/******************************************************************************/

/******************************************************************************/
/******************************************************************************/
/* Rule Set : Determine the Packing Details for the Packing Type and Entity or Entities */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Packing_IdentifyDetails';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set: Load Packing details for Bulk Order Packing   */
/******************************************************************************/
/* Rule Conditions and Queries are validated on Insert. This Temp Table is created such that the validations are done correctly */
select @vRuleSetName        = @vRuleSetType + '_BulkOrderPacking',
       @vRuleSetFilter      = '~PackingType~=''BulkOrderPacking''',
       @vRuleSetDescription = 'Identify Packing Details for Bulk Order Packing',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 300; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule #1 : Insert Packing Details */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Bulk Order Packing: Insert Packing Details',
       @vRuleQuery       = 'exec pr_Packing_GetBulkDetailsToPack',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule #3 : delete lines with no picked quantities   */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~ShowLinesNotPicked~=''N'' and ~Action~ <> ''PACKAGEREOPEN''',
       @vRuleDescription = 'Bulk Order Packing: Delete Lines with no Picked Quantity',
       @vRuleQuery       = 'delete from #PackingDetails where (PickedQuantity = 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : packed details for reopened package */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~Action~ = ''PACKAGEREOPEN''',
       @vRuleDescription = 'Reopen Package: Packed Details for reopened package',
       @vRuleQuery       = 'insert into #PackingDetails (OrderDetailId, OrderId, OrderLine, PickTicket, SalesOrder, OrderType,  Status, Priority, SoldToId, ShipToId,
                                                         PickBatchId, PickBatchNo, ShipVia, CustPO, Ownership, HostOrderLine, LineType,
                                                         SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, SKUDesc, SKU1Desc,
                                                         SKU2Desc , SKU3Desc, SKU4Desc, SKU5Desc, Serialized, UPC, AlternateSKU,
                                                         DisplaySKU, DisplaySKUDesc, SKUBarcode, UnitWeight, SKUImageURL, SKUSortOrder,
                                                         UnitsOrdered, UnitsAuthorizedToShip, UnitsAssigned, UnitsToPack, UnitsPacked, Lot, CustSKU,
                                                         PackingGroup, PalletId, Pallet, LPNId, LPN, LPNType, LPNStatus, LPNDetailId,
                                                         PickedQuantity, PickedFromLocation, PickedBy, BusinessUnit, PageTitle, PackGroupKey)
                              select LD.OrderDetailId, LD.OrderId, OD.OrderLine, OH.PickTicket, OH.SalesOrder, OH.OrderType, OH.Status, OH.Priority, OH.SoldToId, OH.ShipToId,
                              OH.PickBatchId, OH.PickBatchNo, OH.ShipVia, OH.CustPO, OH.Ownership, OD.HostOrderLine, OD.LineType,
                              S.SKUId, S.SKU, S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5, S.Description, S.SKU1Description,
                              S.SKU2Description , S.SKU3Description, S.SKU4Description, S.SKU5Description, OD.Serialized, S.UPC, S.AlternateSKU,
                              S.DisplaySKU, S.DisplaySKUDesc, S.Barcode, S.UnitWeight, S.SKUImageURL, S.SKUSortOrder,
                              OD.UnitsOrdered, OD.UnitsAuthorizedToShip, OD.UnitsAssigned, 0, LD.Quantity, OD.Lot, OD.CustSKU,
                              OD.PackingGroup, L.PalletId, L.Pallet, L.LPNId, L.LPN, L.LPNType, L.Status, LD.LPNDetailId,
                              0, LD.ReferenceLocation, LD.PickedBy, OH.BusinessUnit, ''test'', null
                              from LPNDetails LD
                                join LPNs L on (LD.LPNId = L.LPNId) and (L.LPNType = ''S'' /* Ship */)
                                join OrderHeaders OH on (OH.OrderId = LD.OrderId)
                                join OrderDetails OD on (OD.OrderDetailId = LD.OrderDetailId)
                                join SKUs S on (S.SKUId = LD.SKUId)
                              where (L.LPN = ~LPN~ and L.BusinessUnit = ~BusinessUnit~);
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule #4 : Delete Component Lines if not required to show   */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~ShowComponentSKUsLines~=''N''',
       @vRuleDescription = 'Bulk Order Packing: Delete Component Lines if not required to show',
       @vRuleQuery       = 'delete from #PackingDetails where (Line = ''C'' /* Component SKU */)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set: Load Packing details for Standard Order Packing     */
/******************************************************************************/
/* Rule Conditions and Queries are validated on Insert. This Temp Table is created such that the validations are done correctly */
select @vRuleSetName        = @vRuleSetType + '_StandardOrderPacking',
       @vRuleSetFilter      = '~PackingType~=''StandardOrderPacking''',
       @vRuleSetDescription = 'Identify Packing Details for Standard Order Packing',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 350; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule : Determine the packing details group by PackGroupKey for standard order packing   */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackDetailsMode~ = ''GroupBy-LPN-SKU''',
       @vRuleDescription = 'Standard Order Packing: Insert Packing Details group by pack group key',
       @vRuleQuery       = 'insert into #PackingDetails
                              (OrderDetailId, OrderId, PickTicket, SalesOrder, OrderType,  Status, Priority, SoldToId, ShipToId,
                               PickBatchId, PickBatchNo, ShipVia, CustPO, Ownership, HostOrderLine, LineType,
                               SKUId, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, SKUDesc, SKU1Desc,
                               SKU2Desc , SKU3Desc, SKU4Desc, SKU5Desc, Serialized, UPC, AlternateSKU,
                               DisplaySKU, DisplaySKUDesc, SKUBarcode, UnitWeight, SKUImageURL, SKUSortOrder,
                               UnitsOrdered, UnitsAuthorizedToShip, UnitsAssigned, UnitsToPack, UnitsPacked, Lot, CustSKU,
                               PackingGroup, PalletId, Pallet, LPNId, LPN, LPNType, LPNStatus, LPNDetailId,
                               PickedQuantity, PickedFromLocation, PickedBy, BusinessUnit, PageTitle, PackGroupKey, InventoryKey)
                              select 0, min(PD.OrderId), min(PD.PickTicket), min(PD.SalesOrder), min(PD.OrderType), min(PD.Status), min(PD.Priority), min(PD.SoldToId), min(PD.ShipToId),
                                     min(PD.PickBatchId), min(PD.PickBatchNo), min(PD.ShipVia), min(PD.CustPO), min(PD.Ownership), min(PD.HostOrderLine), min(PD.LineType),
                                     min(PD.SKUId), min(PD.SKU), min(PD.SKU1), min(PD.SKU2), min(PD.SKU3), min(PD.SKU4), min(PD.SKU5), min(PD.SKUDesc), min(SKU1Desc),
                                     min(PD.SKU2Desc), min(PD.SKU3Desc), min(PD.SKU4Desc), min(PD.SKU5Desc), min(Serialized) , min(UPC), min(PD.AlternateSKU),
                                     min(PD.DisplaySKU), min(PD.DisplaySKUDesc), min(SKUBarcode), sum(PD.UnitWeight), min(PD.SKUImageURL), min(PD.SKUSortOrder),
                                     sum(UnitsOrdered), sum(PD.UnitsAuthorizedToShip), sum(PD.UnitsAssigned), sum(PD.UnitsToPack), sum(UnitsPacked) , min(PD.Lot), min(PD.CustSKU),
                                     min(PD.PackingGroup), min(PD.PalletId), min(PD.Pallet), min(PD.LPNId), min(PD.LPN), min(PD.LPNType), min(PD.LPNStatus), 0,
                                     sum(PickedQuantity), min(PD.PickedFromLocation), min(PD.PickedBy), min(BusinessUnit), min(PageTitle), concat_ws(''-'', OrderId, LPNId, SKUId, PackingGroup), min(InventoryKey)
                             from vwOrderToPackDetails PD
                               join #ttSelectedEntities SE on (SE.EntityId = PD.OrderId)
                             where ((PD.LPNType in (''A'', ''TO'')) or (PD.LPNStatus = ''K''))
                             group by concat_ws(''-'', OrderId, LPNId, SKUId, PackingGroup)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule : Determine the default packing details for standard order packing   */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackDetailsMode~ = ''Default''',
       @vRuleDescription = 'Standard Order Packing: Insert Packing Details',
       @vRuleQuery       = 'insert into #PackingDetails
                              select PD.*
                              from vwOrderToPackDetails PD
                              join #ttSelectedEntities SE on (SE.EntityId = PD.OrderId)
                              where ((PD.LPNType in (''A'', ''TO'')) or (PD.LPNStatus = ''K''));

                            update #PackingDetails set PackGroupKey = ''''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule #4 : Delete Component Lines if not required to show   */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~ShowComponentSKUsLines~=''N''',
       @vRuleDescription = 'Order Packing: Delete Component Lines if not required to show',
       @vRuleQuery       = 'delete from #PackingDetails where (PickedQuantity = 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rule Set : Determine the Form Name for the Packing Type */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Packing_IdentifyInputForm';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1     */
/******************************************************************************/
/* Rule Conditions and Queries are validated on Insert. This Temp Table is created such that the validations are done correctly */
select @vRuleSetName        = @vRuleSetType,
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Identify Packing Input Form Name',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 400; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule #1 : Packing Form Name for Bulk Order Packing Type  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingType~=''BulkOrderPacking''',
       @vRuleDescription = 'Packing Form for Bulk Order Packing Type',
       @vRuleQuery       = 'select ''Packing_StandardOrder''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule #1 : Packing Form Name for Standard Order Packing Type  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~PackingType~=''StandardOrderPacking''',
       @vRuleDescription = 'Packing Form for Standard Order Packing Type',
       @vRuleQuery       = 'select ''Packing_StandardOrder''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule #999 : Default Packing Form Name  */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Default Packing Input Form Name',
       @vRuleQuery       = 'select ''Packing_Standard''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 999;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
if (object_id('tempdb..#ttSelectedEntities') is not null)
  drop table #ttSelectedEntities;

Go
