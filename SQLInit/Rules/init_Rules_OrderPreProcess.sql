/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/07/29  RV      Added rules to validate the ship to address (BK-882)
  2022/01/22  AY      Moved address management to rules (BK-742)
  2021/08/13  OK      Added validations if any order Warehouse/shipfrom doesn't has ShipFrom Contact (BK-487)
  2021/04/23  MS      Ignore Address Validations for Replenish Orders (BK-302)
  2021/03/23  TK      Estimate cartons by volume for OrderCategory1 (HA-GoLive)
  2021/03/05  TK      Rules to update SortOrder on OrderDetails (HA-2127)
  2021/02/19  VS      Added validation for City, State and Zip (BK-170)
  2021/02/04  TK      Rule to update EstimatedCartons on Orders (HA-1964)
  2021/02/01  AY      Rules to setup PackinglistFormat (BK-141)
  2020/05/29  YJ      HostNumLines Validation: Migrated from Production (HA-689)
  2020/05/25  TK      Changes to update PackingGroup on order details (HA-648)
  2020/05/15  RT/TK   ValidateOrdersOnPreprocess: Included Rules (HA-301)
  2020/04/24  TK      Changes to update default values on Orders (HA-281)
  2018/01/25  MJ      Added a rules for updating ShipFrom based on Ownership(S2G-102)
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
/* Rules evaluate ShipFrom on Preprocess */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ShipFrom';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set : ShipFrom on Orders */
/******************************************************************************/
select @vRuleSetName        = 'ShipFrom ',
       @vRuleSetFilter      =  null,
       @vRuleSetDescription = 'Determine ShipFrom for Orders',
       @vStatus             =  'I', /* Inactive */
       @vSortSeq            =  100;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Update ShipFrom order  */
select @vRuleCondition   = '~Ownership~ = ''''',
       @vRuleDescription = 'Change Ship From based upon Ownership',
       @vRuleQuery       = 'select ''''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules evaluate SoldToId on Preprocess */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'SoldToId';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set : SoldToId on Orders */
/******************************************************************************/
select @vRuleSetName        = 'SoldToId',
       @vRuleSetFilter      =  null,
       @vRuleSetDescription = 'Determine SoldToId for Orders',
       @vStatus             =  'I', /* InActive */
       @vSortSeq            =  120;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Condition for Update ShipFrom order  */
select @vRuleCondition   = '~Ownership~ = ''''',
       @vRuleDescription = 'Change SoldToId based upon Ownership',
       @vRuleQuery       = 'select ''''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules evaluate OrderPriority on Preprocess */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OrderPriority';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Order Priority by Customer */
/******************************************************************************/
select @vRuleSetName        = 'OrderPriority_CustomerSpecific',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Order Priority by Customer Specific',
       @vStatus             =  'I', /* InActive */
       @vSortSeq            =  0;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule - Order Priority 1 for Account 00 */
select @vRuleCondition   = '~Account~ in (''00'')',
       @vRuleDescription = 'Always priority 1 for Account 00',
       @vRuleQuery       = 'select ''1''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'NA'/* Not applicable */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules to managed SoldTo/ShipTo addresses */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OH_ManageAddresses';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to setup SoldToAddress */
/******************************************************************************/
select @vRuleSetName        = 'SoldToAddress',
       @vRuleSetFilter      =  null,
       @vRuleSetDescription = 'Order Preprocess: Setup SoldToAddress',
       @vStatus             =  'I', /* InActive */
       @vSortSeq            =  140;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to setup SoldToaddress if there is a new SoldTo for the Order */
select @vRuleCondition   = '(~PrevSoldToId~ <> ~SoldToId~) and
                            (not exists(select * from Contacts where (ContactRefId = ~SoldToId~) and (ContactType = ''C'' /* Customer */)))',
       @vRuleDescription = 'SoldToAddress: Copy ShipTo address to Sold To if SoldTo changed',
       @vRuleQuery       = 'exec pr_Contacts_Copy ~ShipToId~, ''S'' /* ShipTo */, ~SoldToId~, ''C'' /* Customer */, ~BusinessUnit~, ~UserId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to setup SoldToaddress if it does not exist */
select @vRuleCondition   = '(not exists (select * from Contacts where (ContactRefId = ~SoldToId~) and (ContactType = ''C'' /* Customer */))) and
                            (exists (select * from Contacts where (ContactRefId = ~ShipToId~) and (ContactType = ''S'' /* Ship To  */)))',
       @vRuleDescription = 'SoldToAddress: Copy ShipTo address to Sold To if SoldTo address does not exist',
       @vRuleQuery       = 'exec pr_Contacts_Copy ~ShipToId~, ''S'' /* ShipTo */, ~SoldToId~, ''C'' /* Customer */, ~BusinessUnit~, ~UserId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set to setup ShipToAddress */
/******************************************************************************/
select @vRuleSetName        = 'ShipToAddress',
       @vRuleSetFilter      =  null,
       @vRuleSetDescription = 'Order Preprocess: Setup ShipToAddress',
       @vStatus             =  'I', /* InActive */
       @vSortSeq            =  150;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to setup ShipToAddress if it does not exist */
select @vRuleCondition   = '(not exists (select * from Contacts where (ContactRefId = ~ShipToId~) and (ContactType = ''S'' /* ShipTo */))) and
                            (exists (select * from Contacts where (ContactRefId = ~SoldToId~) and (ContactType = ''C'' /* Customer  */)))',
       @vRuleDescription = 'ShipToAddress: Copy Customer address to Ship To if ShipTo address does not exist',
       @vRuleQuery       = 'exec pr_Contacts_Copy ~SoldToId~, ''C'' /* Customer */, ~ShipToId~, ''S'' /* ShipTo */, ~BusinessUnit~, ~UserId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I',  /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate the Ship To address for specific carriers */
select @vRuleCondition   = null,
       @vRuleDescription = 'ShipToAddress: Validate the address for specific carrier orders',
       @vRuleQuery       = 'update C
                              set C.AVStatus = ''ToBeVerified'',
                                  C.AVMethod = SV.Carrier
                            from Contacts C
                              join OrderHeaders OH on (OH.ShipToId = C.ContactRefId)  and (C.ContactType = ''S'')
                              join ShipVias SV on (SV.ShipVia = OH.ShipVia) and (SV.IsSmallPackageCarrier = ''Y'')
                            where (OH.OrderId = ~OrderId~) and (C.AVStatus in (''NotRequired'', ''InValid''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate the Ship To address for small package carriers */
select @vRuleCondition   = null,
       @vRuleDescription = 'ShipToAddress: Validate the address for all small package carrier orders',
       @vRuleQuery       = 'update C
                              set C.AVStatus = ''ToBeVerified'',
                                  C.AVMethod = ''UPS'' /* As of now using UPS validation for all other carriers */
                            from Contacts C
                              join OrderHeaders OH on (OH.ShipToId = C.ContactRefId)  and (C.ContactType = ''S'')
                              join ShipVias SV on (SV.ShipVia = OH.ShipVia) and (SV.IsSmallPackageCarrier = ''Y'')
                            where (OH.OrderId = ~OrderId~) and (C.AVStatus in (''NotRequired'', ''InValid''))',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules for Updates to be done on Preprocess */
/******************************************************************************/
/******************************************************************************/
select  @vRuleSetType = 'OH_PreprocessUpdates';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to update defaults on PreProcess */
/******************************************************************************/
select @vRuleSetName        = 'OrderPreprocessUpdates',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Updates for Order on Preprocess',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 20;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update default values on OD */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to update default values on OD',
       @vRuleQuery       = 'update OD
                            set PackingGroup = OrderId
                            from OrderDetails OD
                            where OrderId = ~OrderId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to SortOrder on order details */
select @vRuleCondition   = null,
       @vRuleDescription = 'OD.SortOrder - Sort in the order of HostOrderLine & OrderDetailId',
       @vRuleQuery       = 'update OD
                            set SortOrder = dbo.fn_Pad(OD.HostOrderLine, 9) + dbo.fn_LeftPadNumber(OD.OrderDetailId, 8)
                            from OrderDetails OD
                            where OrderId = ~OrderId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Case Pick: update Estimated Cartons required for each order based upon units per carton */
select @vRuleCondition   = '~OrderCategory1~ = ''Case Pick''',
       @vRuleDescription = 'Case Pick: updates Estimated Cartons required for each order based upon units per carton',
       @vRuleQuery       = 'declare @ttOrdersToPreProcess   TEntityKeysTable;

                            select * into #OrdersToPreProcess from @ttOrdersToPreProcess;

                            insert into #OrdersToPreProcess (EntityId) select ~OrderId~;

                            /* Invoke proc that updates num cartons on Orders */
                            exec pr_OrderHeaders_EstimateCartonsByUnitsPerCarton ~BusinessUnit~, ~UserId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Pick & Pick, PTS: update Estimated Cartons required for each order based upon order volume */
select @vRuleCondition   = '~OrderCategory1~ in (''Pick & Pack'', ''Pick To Ship'', ''Wave Manager'')',
       @vRuleDescription = 'Pick & Pick, PTS: update Estimated Cartons required for each order based upon order volume',
       @vRuleQuery       = 'declare @ttOrdersToPreProcess   TEntityKeysTable;

                            select * into #OrdersToPreProcess from @ttOrdersToPreProcess;

                            insert into #OrdersToPreProcess (EntityId) select ~OrderId~;

                            /* Invoke proc that updates num cartons on Orders */
                            exec pr_OrderHeaders_EstimateCartonsByVolume ~BusinessUnit~, ~UserId~;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A' /* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update default values on OH */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Orders with default values',
       @vRuleQuery       = 'update OrderHeaders
                            set ShipCompletePercent = coalesce(nullif(ShipCompletePercent, ''0''), 100)
                            where OrderId = ~OrderId~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update label & Report formats */
select @vRuleCondition   = null,
       @vRuleDescription = 'Update Orders with the Label & Report formats',
       @vRuleQuery       = 'update OrderHeaders
                            set PackingListFormat = ''PackingList_'' + BusinessUnit  + ''_Standard''
                            where (OrderId = ~OrderId~)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to default Packing list format to CIMS version */
select @vRuleCondition   = null,
       @vRuleDescription = 'PackingList: By default print the CIMS Standard format',
       @vRuleQuery       = 'update OrderHeaders
                            set PackingListFormat = ''PackingList_CIMS_Standard''
                            where (OrderId = ~OrderId~) and (coalesce(PackingListFormat, '''') = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Validations for OrderDetails ParentLines and composite Lines */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OH_PreprocessValidations';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Validate orders on preprocess */
/******************************************************************************/
select @vRuleSetName        = 'ValidateOrdersOnPreprocess',
       @vRuleSetFilter      = '~OrderType~ not in (''R'', ''RU'', ''RP'')',
       @vRuleSetDescription = 'Validations for Orders to PreProcess',
       @vSortSeq            = 300,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Number of Lines on the Order */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~OrderLineCount~ = ''0''',
       @vRuleDescription = 'Check number of lines on the Order',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType,  MessageName, Value1)
                              select ''Order'', ~OrderId~, ~PickTicket~, ''E'', ''Order_InvalidLinesOntheOrder'', ~PickTicket~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* HostNumLines Validation */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = '~ODUniqueKey~ = ''PTHostOrderLine'' and ~Status~ in (''O'', ''N'') and (~HostNumLines~ > 0) and (~HostNumLines~ <> ~OrderLineCount~)',
       @vRuleDescription = 'HostNumLines does not match order details imported',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1, Value2, Value3)
                              select ''Order'', ~OrderId~, ~PickTicket~, ''E'', ''Order_InvalidHostNumLines'', ~PickTicket~, ~HostNumLines~, ~OrderLineCount~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Orders with invalid address Order missing Ship To City */
select @vRuleCondition   = '(coalesce(~ShipToCity~, '''') = '''')',
       @vRuleDescription = 'Orders with missing ShipToCity',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1)
                              select ''Order'', ~OrderId~, ~PickTicket~, ''E'', ''OrderPreprocess_OrderMissingShipToCity'', ~PickTicket~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Orders with invalid address Order missing Ship To Zip */
select @vRuleCondition   = '(coalesce(~ShipToCountry~, '''') = '''') and (Len(~ShipToZip~) not in (5, 9, 10))',
       @vRuleDescription = 'Orders with missing or invalid ShipToZip',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1, Value2)
                              select ''Order'', ~OrderId~, ~PickTicket~, ''E'', ''OrderPreprocess_OrderHasInvalidShipToZip'', ~PickTicket~, ~ShipToZip~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Orders with invalid address Order missing Ship To State */
select @vRuleCondition   = '(coalesce(~ShipToState~, '''') = '''') and (~OrderType~ not in (''T''))',
       @vRuleDescription = 'Orders with missing ShipToState',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1)
                              select ''Order'', ~OrderId~, ~PickTicket~, ''E'', ''OrderPreprocess_OrderMissingShipToState'', ~PickTicket~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Orders with missing ShipFrom Contact */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing ShipFrom contact',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''E'', ''OrderPreprocess_MissingShipFromContact'', OH.PickTicket, OH.ShipFrom
                              from OrderHeaders OH
                                left outer join Contacts C on (C.ContactRefId = OH.ShipFrom) and (C.ContactType = ''F'' /* Ship From */)
                              where (OH.OrderId = ~OrderId~)and
                                    (C.ContactId is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Orders with missing Warehouse Contact */
select @vRuleCondition   = null,
       @vRuleDescription = 'Missing Warehouse contact',
       @vRuleQuery       = 'insert into #Validations (EntityType, EntityId, EntityKey, MessageType, MessageName, Value1, Value2)
                              select ''Order'', OH.OrderId, OH.PickTicket, ''E'', ''OrderPreprocess_MissingWarehouseContact'', OH.PickTicket, OH.Warehouse
                              from OrderHeaders OH
                                left outer join Contacts C on (C.ContactRefId = OH.Warehouse) and (C.ContactType = ''F'' /* Ship From */)
                              where (OH.OrderId = ~OrderId~)and
                                    (C.ContactId is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Update Parent info on all validations */
select @vRuleCondition   = null,
       @vRuleDescription = 'Order Preprocress: Update Parent info on all Validations',
       @vRuleQuery       = 'update #Validations
                            set MasterEntityType = ''Order'',
                                MasterEntityId   = ~OrderId~,
                                MasterEntityKey  = ~PickTicket~',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules to Estimate cartons on Orders */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'OH_EstimateCartons';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Estimate Cartons on Orders */
/******************************************************************************/
select @vRuleSetName        = 'OH_EstimateCartons',
       @vRuleSetFilter      = '~OrderType~ not in (''R'', ''RU'', ''RP'')',
       @vRuleSetDescription = 'Determine method to Estimate Cartons on Orders',
       @vSortSeq            = 30,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* If the Order is waved then go with Wave Type i,e.
     a. Estimate by PackCombination for Case Pick
     b. Estimate by Volume for Pick & Pack and PTS

   If the Order is not waved then go with OrderCategory1 i,e.
     a. Estimate by PackCombination for Case Pick
     b. Estimate by Volume for Pick & Pack, Pick To Ship, Wave Manager */
/*----------------------------------------------------------------------------*/
select @vRuleCondition   = null,
       @vRuleDescription = 'Estimate Cartons on Order: Identify Estimation method',
       @vRuleQuery       = 'update OTE
                            set EstimationMethod = case when W.WaveId is not null and W.WaveType in (''BCP'')
                                                          then ''ByPackConfig''
                                                        when W.WaveId is not null and W.WaveType in (''BPP'', ''PTS'')
                                                          then ''ByVolume''
                                                        when OH.Status = ''N'' and OH.OrderCategory1 in (''Case Pick'')
                                                          then ''ByPackConfig''
                                                        when OH.Status = ''N'' and OH.OrderCategory1 in (''Pick & Pack'', ''Pick To Ship'', ''Wave Manager'')
                                                          then ''ByVolume''
                                                   end
                            from #OrdersToEstimateCartons OTE
                              join OrderHeaders OH on (OTE.EntityId = OH.OrderId)
                              left outer join Waves W on (OH.PickBatchId = W.WaveId)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A'/* Active */,
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
