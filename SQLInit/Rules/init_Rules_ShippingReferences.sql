/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/04  SV      Send USPS Shipping Reference 1 (BK-252)
  2018/09/19  VS      Setup rules for TFORCE (S2GCA-287)
  2018/09/07  RV      Setup rules for ADSI (S2GCA-250)
  2018/08/27  DK      Initial version (HPI-2010).
------------------------------------------------------------------------------*/

declare @vRecordId            TRecordId,
        @vRuleSetId           TRecordId,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,

        @vBusinessUnit        TBusinessUnit,

        @vRuleCondition       TQuery,
        @vRuleDescription     TDescription,
        @vRuleQuery           TQuery,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

declare @vRuleSetType  TRuleSetType = 'ShippingReference1';

/******************************************************************************/
/* Rule Set #1: Get the ShippingReference1 value */
/******************************************************************************/
select @vRuleSetName        = 'Shipping-Reference1-Mapping',
       @vRuleSetDescription = 'Determine Reference1',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier Fedex */
select @vRuleCondition   = '(~CarrierInterface~ = ''ADSI'') and ~Carrier~ = ''FEDEX''',
       @vRuleDescription = 'FEDEX/ADSI: Get Shipping Reference 1',
       @vRuleQuery       = 'select ''ShipperReference:'' + ~LPN~ + ''-'' + ~UCCBarcode~',
       @vSortSeq         = 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier DHL */
select @vRuleCondition   = '(~CarrierInterface~ = ''ADSI'') and ~Carrier~ = ''DHL''',
       @vRuleDescription = 'DHL/ADSI: Get Shipping Reference 1',
       @vRuleQuery       = 'select ''ShipperReference:'' + ~LPN~ + ''-'' + ~UCCBarcode~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

  /*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier UPS */
select @vRuleCondition   = '(~CarrierInterface~ = ''ADSI'') and ~Carrier~ = ''UPS''',
       @vRuleDescription = 'UPS/ADSI: Get Shipping Reference 1',
       @vRuleQuery       = 'select ''ShipperReference:'' + ~LPN~ + ''-'' + ~UCCBarcode~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier Fedex */
select @vRuleCondition   = '~Carrier~ = ''FEDEX''',
       @vRuleDescription = 'FedEx: Get Shipping Reference 1',
       @vRuleQuery       = 'select ''P_O_NUMBER:'' + ~CustPO~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier UPS */
select @vRuleCondition   = '~Carrier~ = ''UPS''',
       @vRuleDescription = 'UPS: Get Shipping Reference 1',
       @vRuleQuery       = 'select ''SE:'' + ~LPN~ + ''-'' + ~UCCBarcode~ + '';'' + '' PO:'' + ~CustPO~ + ''-'' + ~SalesOrder~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get PickTicket to be printed over USPS label for USPS carrier */
select @vRuleCondition   = '~Carrier~ = ''USPS''',
       @vRuleDescription = 'USPS: Get Shipping Reference 1',
       @vRuleQuery       = 'select ~PickTicket~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier TFORCE */
select @vRuleCondition   = '(~CarrierInterface~ = ''ADSI'') and ~Carrier~ = ''TFORCE''',
       @vRuleDescription = 'TFORCE/ADSI: Get Shipping Reference 1',
       @vRuleQuery       = 'select ''ShipperReference:'' + ~SalesOrder~',
       @vSortSeq         += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for ShippingReference2 */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'ShippingReference2';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1: Get the Reference2 value */
/******************************************************************************/
select @vRuleSetName        = 'Shipping-Reference2-Mapping',
       @vRuleSetDescription = 'Determine Reference2',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

         /*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier Fedex */
select @vRuleCondition   = '(~CarrierInterface~ = ''ADSI'') and ~Carrier~ = ''FEDEX''',
       @vRuleDescription = 'FEDEX/ADSI: Get Shipping Reference 2',
       @vRuleQuery       = 'select ''ConsigneeReference:'' + ~CustPO~',
       @vSortSeq         = 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier DHL */
select @vRuleCondition   = '(~CarrierInterface~ = ''ADSI'') and ~Carrier~ = ''DHL''',
       @vRuleDescription = 'DHL/ADSI: Get Shipping Reference 2',
       @vRuleQuery       = 'select ''ConsigneeReference:'' + ~CustPO~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

  /*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier UPS */
select @vRuleCondition   = '(~CarrierInterface~ = ''ADSI'') and ~Carrier~ = ''UPS''',
       @vRuleDescription = 'UPS/ADSI: Get Shipping Reference 2',
       @vRuleQuery       = 'select ''ConsigneeReference:'' + ~CustPO~ + ''-'' + ~SalesOrder~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier Fedex*/
select @vRuleCondition   = '~Carrier~ = ''FEDEX''',
       @vRuleDescription = 'FedEx: Get Shipping Reference 2',
       @vRuleQuery       = 'select ''CUSTOMER_REFERENCE:'' + ~LPN~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* InActive */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier TFORCE */
select @vRuleCondition   = '(~CarrierInterface~ = ''ADSI'') and ~Carrier~ = ''TFORCE''',
       @vRuleDescription = 'TFORCE/ADSI: Get Shipping Reference 2',
       @vRuleQuery       = 'select ''ConsigneeReference:'' + ~CustPO~',
       @vSortSeq        += 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for ShippingReference3 */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'ShippingReference3';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1: Get the Reference3 value */
/******************************************************************************/
select @vRuleSetName        = 'Shipping-Reference3-Mapping',
       @vRuleSetDescription = 'Determine Reference3',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Get default one for carrier Fedex*/
select @vRuleCondition   = '~Carrier~ = ''FEDEX''',
       @vRuleDescription = 'FedEx: Get Shipping Reference 3',
       @vRuleQuery       = 'select ''INVOICE_NUMBER:'' + ~PickTicket~',
       @vSortSeq         = 1,
       @vStatus          = 'A'/* Active */;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* Replace */;

Go
