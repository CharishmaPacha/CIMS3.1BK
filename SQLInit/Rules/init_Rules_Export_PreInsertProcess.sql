/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/06  SV      Changes to manage the Exports.Status value for OB (OB2-1791)
  2021/04/21  TK      Changes to populate required fields (HA-2641)
  2021/04/16  TK      update ShipTo & ShipVia info irrespective of TransType (HA-GoLive)
  2021/02/02  TK      Rules to populate missing values (HA-1842)
  2020/04/29  MS      Initial version (HA-323)
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
/* Rules for: Updating values before inserting into Exports table  */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'Export_PreInsertProcess';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set: Updating values before inserting into Exports table  */
/******************************************************************************/
select @vRuleSetName        = 'Export_PreInsertProcess',
       @vRuleSetDescription = 'Rules to do neccasary updates on Exports',
       @vRuleSetFilter      = null,
       @vStatus             = 'A' /* Active */,
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to populate missing values related to LPNs */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to populate missing values related to LPNs',
       @vRuleQuery       = 'Update ER
                            set SKUId              = coalesce(ER.SKUId,              L.SKUId, LD.SKUId),
                                LocationId         = coalesce(ER.LocationId,         L.LocationId),
                                PalletId           = coalesce(ER.PalletId,           L.PalletId),
                                ReceiverId         = coalesce(ER.ReceiverId,         L.ReceiverId),
                                ReceiverNumber     = coalesce(ER.ReceiverNumber,     L.ReceiverNumber),
                                ReceiptId          = coalesce(ER.ReceiptId,          L.ReceiptId),
                                Warehouse          = coalesce(ER.Warehouse,          L.DestWarehouse),
                                Ownership          = coalesce(ER.Ownership,          L.Ownership),
                                TrackingNo         = coalesce(ER.TrackingNo,         L.TrackingNo),
                                Reference          = coalesce(ER.Reference,          L.Reference),
                                Lot                = coalesce(ER.Lot,                L.Lot, LD.Lot),
                                InventoryClass1    = coalesce(ER.InventoryClass1,    L.InventoryClass1),
                                InventoryClass2    = coalesce(ER.InventoryClass2,    L.InventoryClass2),
                                InventoryClass3    = coalesce(ER.InventoryClass3,    L.InventoryClass3),
                                OrderId            = coalesce(ER.OrderId,            L.OrderId),
                                OrderDetailId      = coalesce(ER.OrderDetailId,      LD.OrderDetailId),
                                ShipmentId         = coalesce(ER.ShipmentId,         L.ShipmentId),
                                LoadId             = coalesce(ER.LoadId,             L.LoadId)
                            from #ExportRecords ER
                              join LPNs       L  on L.LPNId          = ER.LPNId
                              left join LPNDetails LD on LD.LPNDetailId   = ER.LPNDetailId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to populate missing values related to Order info */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to populate missing values related to Order info',
       @vRuleQuery       = 'Update ER
                            set SKUId              = coalesce(ER.SKUId,              OD.SKUId),
                                Warehouse          = coalesce(ER.Warehouse,          OH.Warehouse),
                                Ownership          = coalesce(ER.Ownership,          OH.Ownership),
                                Lot                = coalesce(ER.Lot,                OD.Lot),
                                InventoryClass1    = coalesce(ER.InventoryClass1,    OD.InventoryClass1),
                                InventoryClass2    = coalesce(ER.InventoryClass2,    OD.InventoryClass2),
                                InventoryClass3    = coalesce(ER.InventoryClass3,    OD.InventoryClass3),
                                SourceSystem       = coalesce(ER.SourceSystem,       OH.SourceSystem,   ''HOST''),
     --                           FreightCharges     = coalesce(ER.FreightCharges,     OH.FreightCharges),
                                FreightTerms       = coalesce(ER.FreightTerms,       OH.FreightTerms),
                                SoldToId           = coalesce(ER.SoldToId,           OH.SoldToId),
                                SoldToName         = coalesce(ER.SoldToName,         OH.SoldToName),
                                ShipToId           = coalesce(ER.ShipToId,           OH.ShipToId)
                            from #ExportRecords ER
                              join OrderHeaders OH on OH.OrderId       = ER.OrderId
                              left join OrderDetails OD on OD.OrderDetailId = ER.OrderDetailId',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to populate missing values related to shipping info */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to populate missing values related to shipping info',
       @vRuleQuery       = 'Update ER
                            set ShipToName         = coalesce(ER.ShipToName,         SHIPTO.Name),
                                ShipToAddressLine1 = coalesce(ER.ShipToAddressLine1, SHIPTO.AddressLine1),
                                ShipToAddressLine2 = coalesce(ER.ShipToAddressLine2, SHIPTO.AddressLine2),
                                ShipToCity         = coalesce(ER.ShipToCity,         SHIPTO.City),
                                ShipToState        = coalesce(ER.ShipToState,        SHIPTO.State),
                                ShipToCountry      = coalesce(ER.ShipToCountry,      SHIPTO.Country),
                                ShipToZip          = coalesce(ER.ShipToZip,          SHIPTO.Zip),
                                ShipToPhoneNo      = coalesce(ER.ShipToPhoneNo,      SHIPTO.PhoneNo),
                                ShipToEmail        = coalesce(ER.ShipToEmail,        SHIPTO.Email),
                                ShipToReference1   = coalesce(ER.ShipToReference1,   SHIPTO.Reference1),
                                ShipToReference2   = coalesce(ER.ShipToReference2,   SHIPTO.Reference2)
                            from #ExportRecords ER
                              join Contacts SHIPTO on SHIPTO.ContactRefId = ER.ShipToId and SHIPTO.ContactType = ''S''
                           ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ignore Recv transactions for XYZ Warehouse as Receipts are to be exported for ABC Warehouse */
select @vRuleCondition   = '~TransType~ = ''Recv'' and ~Warehouse~ = ''XYZ''',
       @vRuleDescription = 'Ignore Recv transactions for XYZ Warehouse',
       @vRuleQuery       = 'Update ER
                            set ExchangeStatus = ''I''
                            from #ExportRecords ER',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Ignore Recv transactions if receiver is not yet closed */
select @vRuleCondition   = '~TransType~ = ''Recv''',
       @vRuleDescription = 'Ignore Recv transactions if receiver is not yet closed',
       @vRuleQuery       = 'Update ER
                            set ExchangeStatus = ''I''
                            from #ExportRecords ER
                              join Receivers R on (ER.ReceiverId = R.Receiver) and
                                                  (R.BusinessUnit = ~BusinessUnit~) and
                                                  (R.Status not in (''C''))', /* Ignore if receiver not closed */
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update the ShipVia */
select @vRuleCondition   = '~TransType~ = ''Ship''',
       @vRuleDescription = 'Export ShipVia: Use Load Ship Via if MasterTrackingNo exists',
       @vRuleQuery       = 'Update ER
                            set ShipVia = coalesce(L.ShipVia, ER.ShipVia)
                            from #ExportRecords ER
                              join Loads L on (ER.LoadId = L.LoadId)
                            where (L.LoadId > 0) and
                                  (coalesce(L.MasterTrackingNo, '''') <> '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Export ShipVia: If on Load, Export Load ShipVia or Order ShipVia */
select @vRuleCondition   = null,
       @vRuleDescription = 'Export ShipVia: If on Load, Export Load ShipVia or Order ShipVia',
       @vRuleQuery       = 'Update ER
                            set ShipVia = coalesce(ER.ShipVia, Load.ShipVia, OH.ShipVia)
                            from #ExportRecords ER
                              left outer join OrderHeaders OH on (ER.OrderId = OH.OrderId)
                              left outer join Loads Load on (ER.LoadId = Load.LoadId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to Get the ShipVia when not on a Load */
select @vRuleCondition   = null,
       @vRuleDescription = 'Export ShipVia: If not on Load, Export Order ShipVia',
       @vRuleQuery       = 'Update ER
                            set ShipVia = coalesce(ER.ShipVia, OH.ShipVia)
                            from #ExportRecords ER
                              join OrderHeaders OH on (ER.OrderId = OH.OrderId)
                            where (OH.LoadId = 0)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update ShipVia attributes */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to update ShipVia attributes',
       @vRuleQuery       = 'Update ER
                            set ShipViaDesc = coalesce(ER.ShipViaDesc, SV.Description),
                                Carrier     = coalesce(ER.Carrier,     SV.Carrier),
                                SCAC        = coalesce(ER.SCAC,        SV.SCAC)
                            from #ExportRecords ER
                              join ShipVias SV on (SV.ShipVia = ER.ShipVia)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Update Exports Status as Ignored for RMA transactions 
   FYI, this rule will be active for CIMS and OB for now.
   If required we need to manage it at client branch level*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Exports Status: Ignore the RMA transactions',
       @vRuleQuery       = 'Update ER
                            set Status = ''I'' /* Ignored */
                            from #ExportRecords ER
                            where (Transtype = ''RMA'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Default values to update on Exports, if no-value sent */
select @vRuleCondition   = null,
       @vRuleDescription = 'Default - Values to update',
       @vRuleQuery       = 'Update ER
                            set Status        = coalesce(ER.Status, ''N''),
                                TransQty      = coalesce(ER.TransQty, 0),
                                SourceSystem  = coalesce(ER.SourceSystem, ''HOST''),
                                Weight        = coalesce(ER.Weight, 0.0),
                                Volume        = coalesce(ER.Volume, 0.0)
                            from #ExportRecords ER
                            where Status is null',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
