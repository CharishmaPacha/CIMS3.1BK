/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/08/27  RV      Made changes to update the references for all the packages for FEDEX (CIMSV3-3792)
  2024/06/06  RV      CarrierPackages_InsuranceRequired: Default to No (CIMSV3-3659)
  2023/02/16  AY      Revise FedEx References (CIMSV3-3395)
  2023/12/23  VS      Added PROSHIP Rules and mapped with Order (JLFL-320, FBV3-1660)
  2023/08/16  RV      Initial version (JLFL-320)
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
/* RuleSetType
     CarrierPackages: Update the required information for the carrier
                      packages based upon the rules

   RuleSets:
     CarrierPackages_InsuranceRequired: Evaluate the rules whether insurance required or not
     CarrierPackages_UpdateReferences : Update the label references
*/
/******************************************************************************/
/******************************************************************************/

select @vRuleSetType = 'CarrierPackages';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* RuleSet to determine and update insurance required or not */
/******************************************************************************/
select @vRuleSetName        = 'CarrierPackages_InsuranceRequired',
       @vRuleSetFilter      =  null,
       @vRuleSetDescription = 'Evaluate whether insurance required or not',
       @vSortSeq            =  100,   /* Set at this so that we can later add rules before this or after */
       @vStatus             =  'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Insurance Required: Evaluate based upon the carrier options */
select @vRuleCondition   = null,
       @vRuleDescription = 'Insurance Required: Evaluate based upon the carrier options',
       @vRuleQuery       = 'update CPI
                            set CPI.InsuranceRequired = case when (dbo.fn_IsInList(''INS-AP'' /* All Packages */, CSD.CarrierOptions) > 0)
                                                              then ''Yes''
                                                            when (dbo.fn_IsInList(''INS-NR'' /* Not Required */, CSD.CarrierOptions) > 0)
                                                              then ''No''
                                                            else ''No''
                                                       end
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.OrderId = CPI.OrderId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set: Get the Shipping Label References for ADSI/PROSHIP */
/******************************************************************************/
select @vRuleSetName        = 'CarrierPackages_UpdateReferences_ADSI/PROSHIP',
       @vRuleSetFilter      = '(~CarrierInterface~ in (''ADSI'', ''PROSHIP''))',
       @vRuleSetDescription = 'Determine Shipping References for ADSI API',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 200;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: ADSI+Pallet - Get the Shipper Reference1 and Reference2 for Pallet Entity */
select @vRuleCondition   = null,
       @vRuleDescription = 'ADSI-Pallet: Get the Shipper Reference1 and Reference2 for Pallet',
       @vRuleQuery       = 'update CPI
                            set CPI.LabelReference1 = iif(CPI.LabelReference1 is null, ''ShipperReference:'' + EntityKey, CPI.LabelReference1),
                                CPI.LabelReference2 = iif(CPI.LabelReference2 is null, ''ConsigneeReference:'' + CPI.LoadNumber, CPI.LabelReference2)
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.OrderId = CPI.OrderId)
                            where (CSD.CarrierInterface = ''ADSI'') and
                                  (CPI.EntityKey = ''Pallet'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: ADSI/PROSHIP + Canadian Carriers: Get the Shipper Reference1 and Reference2 for specified carriers */
select @vRuleCondition   = null,
       @vRuleDescription = 'ADSI/PROSHIP-Canadian: Get the Shipper Reference1 and Reference2 for specified carriers',
       @vRuleQuery       = 'update CPI
                            set CPI.LabelReference1 = iif(CPI.LabelReference1 is null, ''ShipperReference:'' + OH.SalesOrder, CPI.LabelReference1),
                                CPI.LabelReference2 = iif(CPI.LabelReference2 is null, ''ConsigneeReference:'' + OH.CustPO, CPI.LabelReference2)
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.OrderId = CPI.OrderId)
                              join #OrderHeaders OH on (OH.OrderId = CPI.OrderId)
                            where (CSD.CarrierInterface   in (''ADSI'', ''PROSHIP'')) and
                                  (CSD.Carrier in (''TFORCE'', ''CANADAPOST'', ''CANPAR'', ''LOOMIS'', ''PURO''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: ADSI/PROSHIP + UPS: Get the Shipper Reference1 and Reference2 */
select @vRuleCondition   = null,
       @vRuleDescription = 'ADSI/PROSHIP-UPS: Get the Shipper Reference1 and Reference2 for UPS carrier',
       @vRuleQuery       = 'update CPI
                            set CPI.LabelReference1 = iif(CPI.LabelReference1 is null, ''ShipperReference:'' + + CPI.LPN + ''-'' + coalesce(CPI.UCCBarcode, ''''), CPI.LabelReference1),
                                CPI.LabelReference2 = iif(CPI.LabelReference2 is null, ''ConsigneeReference:'' + OH.CustPO + ''-'' + OH.SalesOrder, CPI.LabelReference2)
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.OrderId = CPI.OrderId)
                              join #OrderHeaders OH on (OH.OrderId = CPI.OrderId)
                            where (CSD.CarrierInterface in (''ADSI'', ''PROSHIP'')) and
                                  (CSD.Carrier = ''UPS'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: ADSI/PROSHIP: Default rule for Shipping Reference1 and Reference2 */
select @vRuleCondition   = null,
       @vRuleDescription = 'ADSI/PROSHIP-Default: Default rule for Shipping Reference1 and Reference2',
       @vRuleQuery       = 'update CPI
                            set CPI.LabelReference1 = iif(CPI.LabelReference1 is null, ''ShipperReference:'' + CPI.LPN + ''-'' + coalesce(CPI.UCCBarcode, ''''), CPI.LabelReference1),
                                CPI.LabelReference2 = iif(CPI.LabelReference2 is null, ''ConsigneeReference:'' + OH.CustPO, CPI.LabelReference2)
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.OrderId = CPI.OrderId)
                              join #OrderHeaders OH on (OH.OrderId = CPI.OrderId)
                            where (CSD.CarrierInterface in (''ADSI'', ''PROSHIP''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set: Get the Shipping Label References for UPS */
/******************************************************************************/
select @vRuleSetName        = 'CarrierPackages_UpdateReferences_UPS',
       @vRuleSetFilter      = '(~CarrierInterface~ = ''DIRECT'') and (~Carrier~ = ''UPS'')',
       @vRuleSetDescription = 'Determine Shipping References for UPS Direct Integration',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 210;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Get the Shipper Reference1 and Reference2 for Direct UPS for 3RDPARTY */
select @vRuleCondition   = null,
       @vRuleDescription = 'UPS Direct-3rd Party: Get the Shipper Reference1 and Reference2 for Direct UPS for 3RDPARTY',
       @vRuleQuery       = 'update CPI
                            set CPI.LabelReference1 = iif(CPI.LabelReference1 is null, ''SE:'' + CPI.LPN + ''-'' + CPI.UCCBarcode , CPI.LabelReference1),
                                CPI.LabelReference2 = iif(CPI.LabelReference2 is null, ''PO:'' + OH.CustPO + '' ARN-'' + OH.ShipmentRefNumber, CPI.LabelReference2)
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.OrderId = CPI.OrderId)
                              join #OrderHeaders OH on (OH.OrderId = CPI.OrderId)
                            where (coalesce(CSD.CarrierInterface, '''') not in (''ADSI'', ''PROSHIP'')) and
                                  (CSD.Carrier = ''UPS'') and
                                  (OH.FreightTerms = ''3RDPARTY'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get the Shipper Reference1 and Reference2 for Direct UPS */
select @vRuleCondition   = null,
       @vRuleDescription = 'Direct: Get the Shipper Reference1 and Reference2 for Direct UPS',
       @vRuleQuery       = 'update CPI
                            set CPI.LabelReference1 = iif(CPI.LabelReference1 is null, ''SE:'' + coalesce(nullif(CPI.UCCBarcode, ''''), CPI.LPN), CPI.LabelReference1),
                                CPI.LabelReference2 = iif(CPI.LabelReference2 is null, ''PO:'' + OH.CustPO + ''-'' + OH.PickTicket, CPI.LabelReference2)
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.OrderId = CPI.OrderId)
                              join #OrderHeaders OH on (OH.OrderId = CPI.OrderId)
                            where (coalesce(CSD.CarrierInterface, '''') not in (''ADSI'', ''PROSHIP'')) and
                                  (CSD.Carrier = ''UPS'') and
                                  (OH.FreightTerms <> ''3RDPARTY'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set: Get the Shipping Label References for FEDEX */
/******************************************************************************/
select @vRuleSetName        = 'CarrierPackages_UpdateReferences_FEDEX',
       @vRuleSetFilter      = '(~CarrierInterface~ = ''DIRECT'') and (~Carrier~ = ''FEDEX'')',
       @vRuleSetDescription = 'Determine Shipping References for FEDEX Direct Integration',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 220;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Get the Shipper Reference1 and Reference2 for Direct FEDEX */
select @vRuleCondition   = null,
       @vRuleDescription = 'Direct: Get the Shipper Reference1, Reference2 and Reference3 for Direct FEDEX',
       @vRuleQuery       = 'update CPI
                            set CPI.LabelReference1Type  = iif(CPI.LabelReference1Value is null, ''P_O_NUMBER'',         CPI.LabelReference1Type),
                                CPI.LabelReference1Value = iif(CPI.LabelReference1Value is null, OH.CustPO,              CPI.LabelReference1Value),
                                CPI.LabelReference2Type  = iif(CPI.LabelReference2Value is null, ''CUSTOMER_REFERENCE'', CPI.LabelReference2Type),
                                CPI.LabelReference2Value = iif(CPI.LabelReference2Value is null,  CPI.LPN,               CPI.LabelReference2Value),
                                CPI.LabelReference3Type  = iif(CPI.LabelReference3Value is null, ''INVOICE_NUMBER'',     CPI.LabelReference3Type),
                                CPI.LabelReference3Value = iif(CPI.LabelReference3Value is null, OH.PickTicket,          CPI.LabelReference3Value)
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.OrderId= CPI.OrderId)
                              join #OrderHeaders OH on (OH.OrderId = CPI.OrderId)
                            where (CSD.Carrier = ''FEDEX'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set: Get the Shipping Label References for USPS */
/******************************************************************************/
select @vRuleSetName        = 'CarrierPackages_UpdateReferences_USPS',
       @vRuleSetFilter      = '(~CarrierInterface~ = ''DIRECT'') and (~Carrier~ = ''USPS'')',
       @vRuleSetDescription = 'Determine Shipping References for USPS Direct Integration',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 230;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Get the Shipper Reference1 and Reference2 for Direct USPS */
select @vRuleCondition   = null,
       @vRuleDescription = 'Direct: Get the Shipper Reference1 and Reference2 for Direct USPS',
       @vRuleQuery       = 'update CPI
                            set CPI.LabelReference1 = iif(CPI.LabelReference1 is null, CSD.PickTicket, CPI.LabelReference1)
                            from #CarrierPackageInfo CPI
                              join #CarrierShipmentData CSD on (CSD.LPNId = CPI.LPNId)
                            where (CSD.Carrier = ''USPS'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set: Populate the CN22 info */
/******************************************************************************/
select @vRuleSetName        = 'CarrierPackages_UpdateCN22Info',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Populate the required info for CN22',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 300;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Get the required info CN22 document */
select @vRuleCondition   = null,
       @vRuleDescription = 'CN22: Get the required info CN22 document',
       @vRuleQuery       = 'update CPI
                            set CNNDescription = ''Apparel'',
                                WeightUoM      = ''LBS''
                            from #CarrierPackageInfo CPI',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Commercial Invoice Details */
/******************************************************************************/
select @vRuleSetName        = 'CarrierPackages_UpdateCommercialInvoiceInfo',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Update Commercial Invoice Details for API',
       @vStatus             = 'A' /* A-Active , I-InActive , NA-Not applicable */,
       @vSortSeq            = 100; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Update info based upon OH Info */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Update required info for Commercial Invoice for API',
       @vRuleQuery       = 'update CPI
                            set CPI.CIPurpose        = ''SOLD'',
                                CPI.CITerms          = iif(OH.FreightTerms = ''3RDPARTY'', ''DDU'', ''DDP''),
                                CPI.CIFreightCharge  = coalesce(OH.TotalShippingCost, 0),
                                CPI.CIInsuranceValue = 0.0,
                                CPI.CIOtherCharges   = 0.0,
                                CPI.CIComments       = null,
                                CPI.CISaveInDB       = ''Y''
                            from #CarrierPackageInfo CPI
                              join #OrderHeaders OH on (CPI.OrderId = OH.OrderId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active , I-InActive, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
