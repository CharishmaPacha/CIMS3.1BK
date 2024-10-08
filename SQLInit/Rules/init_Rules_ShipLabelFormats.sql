/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/16  MS      Added rules to print UCC 128 labels (CID-348)
  2019/04/25  RT      Added rules to print Ship_4x6_AAMAZON1 and Ship_4x6_ACOSTCO1 labels (S2GCA-603 & 604)
  2018/09/20  NB      syntax corrections (CIMSV3-221)
  2018/08/29  CK      Added rule for Packing label format : Migrated from HPI
                      Changed RuleSetname PackingLabels to Packing_LabelsToPrint(OB2-603)
  2018/08/05  VM      Added ShipLabel_USPS_Address in UCCLabels and Inactivated ShipLabel_USPS Small Package label (OB2-480)
  2018/05/10  RV      Added rules for Pallet label format and added descriptions (S2G-753)
              MJ      Added rule for Ship_4x8_Generic (S2G-803)
  2017/09/05  DK      Added ShipLabel_BEST (cIMS-1259)
  2016/09/10  VM      ShipLabel_4x6_Generic => ShipLabel_4x6_GenericCarrier
  2016/07/26  TK      Configured rules for Generic Carrier (HPI-187)
  2016/07/11  KN      Fixed rule condition for DHL (NBD-637)
  2016/06/30  AY      Setup standard rules for ship labels and content labels
  2016/06/14  TK      Added LPNLabelToPrint RuelSet (NBD-578)
  2016/06/13  KN      Added: DHL related code (NBD-554).
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2016/02/18  AY      Added Packing_LPNLabel
  2015/10/28  AY      Added sample Content Label rules
  2015/08/07  SV      Added Ship_4x6_LaneBryant (FB-273)
  2015/07/22  SV      Added ShipLabel for Cabela (OB-376)
  2015/07/18  VM      Use singular for RuleSetType - ShipLabelFormat (FB-255)
  2015/02/26  AK      Splitted Rules,RuleSets(Init_Rules) based on RuleSetType.
  2014/12/19  AK      Changes made to control data using procedure
  2014/05/13  SV      Initial version
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
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
/* Rules to deterime the various types of shipping label formats to use */
/******************************************************************************/
/******************************************************************************/
declare @vRuleSetType TRuleSetType = 'ShipLabelFormat';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set #1 - UCC Ship Label Formats */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabelFormat_UCCLabels',
       @vRuleSetDescription = 'Get ship label format for UCC labels' ,
       @vRuleSetFilter      = '~LabelType~ = ''SL''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 Rules - Ship Label Formats

   Shipping labels can be defined for customers, or customer accounts or there
   may be a generic format used for all customers. We are defining the default
   RuleSet so that it can be used by most clients without much modification.

   The below rules are setup with the assumption that the various label formats
   setup in the system use a consistent naming structure. All Shiplabel formats
   are defined with prefix of 'Ship' and we could have formats defined by SoldTo,
   Account or AccountName and in end may have a generic format which appplies to
   all orders in the event there are no specific ones setup for that cusotmer.

   The various combinations setup are:

   Ownership-Account-ShipToStore
   Ownership-Account-ShipTo
   Ownership-Account-SoldTo
   Ownership-Account

   Ownership-ShipTo
   Ownership-SoldTo
   Ownership

   BusinessUnit-ShipTo
   BusinessUnit-SoldTo
   BusinessUnit-Account
   BusinessUnit-AccountName
   BusinessUnit-Generic

   CIMS Generic
*/

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Owner/Account/ShipToStore, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get Shiplabels based on Ownership, Account-ShipToStore',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~Ownership~_AcctShipToStore_~Account~_~ShipToStore~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Inactive */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Account/ShipTo, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get Shiplabels based on Ownership, Account-ShipTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~Ownership~_AcctShipTo_~Account~_~ShipTo~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Inactive */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Account/SoldTo, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get Shiplabels based on Ownership, Account-SoldTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~Ownership~_AcctSoldTo_~Account~_~SoldTo~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Inactive */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a default label for the Account, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the default label formats based on the account',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~!Ownership~_Acct_~!Account~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Inactive */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Ownership-ShipTo, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the label formats based on Ownership-ShipTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~Ownership~_ShipTo_~ShipTo~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Ownership-SoldTo, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the label formats based on Ownership-SoldTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~Ownership~_SoldTo_~SoldTo~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Ownership, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the label formats based on Ownership',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~Ownership~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is no consistent naming format this type of rule could be used */
select @vRuleCondition   = '~SoldToId~ like ''Walmart''',
       @vRuleDescription = 'Get the standard label format',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship_4x6_Walmart_t5000''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* InActive - just setup to show as example */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is no consistent naming format this type of rule could be used */
select @vRuleCondition   = '~SoldToId~ like ''CABE01''' /* Cabela code use at OB */,
       @vRuleDescription = 'Get the label format specific to Cabela',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship_4x6_Cabelas_~BusinessUnit~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* InActive */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the BusinessUnit/ShipTo, then use that to print */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the label formats based on BusinessUnit and ShipTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~BusinessUnit~_ShipTo_~ShipTo~_''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the BusinessUnit/SoldTo, then use that to print */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the label formats based on BusinessUnit and SoldTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~BusinessUnit~_SoldTo_~SoldTo~_''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the BusinessUnit/Account, then use that to print */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the label formats based on BusinessUnit and Account',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~!BusinessUnit~_Acct_~!Account~_''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the AccountName, then use that to print */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the label formats based on BusinessUnit and AccountName',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~!BusinessUnit~_AcctName_~!AccountName~_''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Inctive */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Print UCC - 128 Labels */
select @vRuleCondition   = null,
       @vRuleDescription = 'Print UCC-128 Label for the specific SoldTo if one is available',
       @vRuleQuery       = 'select LabelFormatName
                            from LabelFormats
                            where LabelFormatName like ''Ship_4x6_'' + ~BusinessUnit~ + ''_'' + ~SoldToId~ ',
       @vSortSeq        +=  1,
       @vStatus          = 'A'; /* Active */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Print generic label for the client is there is no customer specific label defined */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the generic label format for the BusinessUnit',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''Ship%_~!BusinessUnit~_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 998; /* Generic label should be last in the list becuase if no other rule satisfies,
                                 then we would use the generic label */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* USPS */
select @vRuleCondition   = '~ShipVia~ like ''USPS''',
       @vRuleDescription = 'Get USPS ShipTo Address label format',
       @vRuleQuery       = 'select ''ShipLabel_USPS_Address''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Print generic label for Generic Carrier */
select @vRuleCondition   = '~Carrier~ = ''Generic'' or ~AddressRegion~ = ''I''',
       @vRuleDescription = 'Get the generic label format for any carrier',
       @vRuleQuery       = 'select ''ShipLabel_4x6_GenericCarrier''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 900;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Print generic label of CIMS */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the default label format for any carrier',
       @vRuleQuery       = 'select ''ShipLabel_4x6_GenericCarrier''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Active */
       @vSortSeq         = 999; /* Generic label should be last in the list becuase if no other rule satisfies,
                                 then we would use the generic label */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Print generic 4x6 label of CIMS */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get the generic label format',
       @vRuleQuery       = 'select ''Ship_4x6_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 999; /* Generic label should be last in the list becuase if no other rule satisfies,
                                 then we would use the generic label */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Print generic 4x8 label of CIMS */
select @vRuleCondition   = null,
       @vRuleDescription = 'Generic Ship Label',
       @vRuleQuery       = 'select ''Ship_4x8_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* InActive */
       @vSortSeq         = 999; /* Generic label should be last in the list becuase if no other rule satisfies,
                                   then we would use the generic label */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/******************************************************************************/
/* Rule Set - Small Package Label Formats */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabelFormat_SmallPackageLabels',
       @vRuleSetDescription = 'Rule Sets for Small Package Labels',
       @vRuleSetFilter      = '~LabelType~ = ''SPL''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* FEDEX */
select @vRuleCondition   = '~ShipVia~ like ''FEDX%'' and ~Carrier~ = ''FEDEX''',
       @vRuleDescription = 'Get FEDEX ship label formats',
       @vRuleQuery       = 'select ''ShipLabel_FEDEX''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* UPS */
select @vRuleCondition   = '~ShipVia~ like ''UPS%'' and ~Carrier~ = ''UPS''',
       @vRuleDescription = 'Get UPS ship label formats',
       @vRuleQuery       = 'select ''ShipLabel_UPS''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* USPS */
select @vRuleCondition   = '~ShipVia~ like ''USPS%'' and ~Carrier~ = ''USPS''',
       @vRuleDescription = 'Get USPS ship label formats',
       @vRuleQuery       = 'select ''ShipLabel_USPS''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* BEST */
select @vRuleCondition   = '~ShipVia~ like ''BEST%''',
       @vRuleDescription = 'Get BEST ship label formats',
       @vRuleQuery       = 'select ''ShipLabel_BEST''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* DHL */
select @vRuleCondition   = '~ShipVia~ like ''DHL%''',
       @vRuleDescription = 'Get DHL ship label formats',
       @vRuleQuery       = 'select ''ShipLabel_DHL''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Generic Carrier - Either we print this label when user selects Shipping label or small package label as per
   client needs, but not both, so this is deactivated */
select @vRuleCondition   = '~Carrier~ = ''Generic'' or ~AddressRegion~ = ''I''',
       @vRuleDescription = 'Get generic ship label format',
       @vRuleQuery       = 'select ''ShipLabel_4x6_GenericCarrier''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* InActive */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/******************************************************************************/
/* Rule Set - Pallet Ship Label Formats */
/******************************************************************************/
select @vRuleSetName        = 'ShipLabelFormat_Pallet',
       @vRuleSetDescription = 'Rule Set For Pallet Ship Label',
       @vRuleSetFilter      = '~LabelType~ = ''PSL''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule: Pallet Ship Label Formats */
select @vRuleCondition   = null,
       @vRuleDescription = 'Generic Pallet Label',
       @vRuleQuery       = 'select ''ShipPallet_4x6_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/******************************************************************************/
/* Rule Set - Packing Label Formats */
/******************************************************************************/
select @vRuleSetName        = 'PackingLabelFormat',
       @vRuleSetDescription = 'Rule Set for Packing label',
       @vRuleSetFilter      = '~LabelType~ = ''PCKL''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* 4x6 Packing Label */
select @vRuleCondition   = null,
       @vRuleDescription = 'Rule to get Packing Label Formats',
       @vRuleQuery       = 'select ''Packing_4x6_Default''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Default Packing label */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get Packing label format',
       @vRuleQuery       = 'select ''Packing_LPNLabel''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* InActive */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*****************************************************************************/
/* Rule Set- Content labels */
/*****************************************************************************/
select @vRuleSetName        = 'ContentLabelFormat',
       @vRuleSetDescription = 'Get Content labels',
       @vRuleSetFilter      = '~LabelType~ = ''CL''',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Owner/Account/ShipToStore, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label based on Owner, Account or ShipToStore',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!Ownership~_AcctShipToStore_~!Account~_~!ShipToStore~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Account/ShipTo, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label based on Account or ShipToStore',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!Ownership~_AcctShipTo_~!Account~_~!ShipTo~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Account/SoldTo, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label based on Account or SoldTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!Ownership~_AcctSoldTo_~!Account~_~!SoldTo~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a default label for the Account, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label format based on Account',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!Ownership~_Acct_~!Account~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Ownership-ShipTo, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label format based on Ownership-ShipTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!Ownership~_ShipTo_~!ShipTo~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Ownership-SoldTo, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label format based on Ownership-SoldTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!Ownership~_SoldTo_~!SoldTo~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the Ownership, then we need to print that */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label formats based on Ownership',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!Ownership~''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the BusinessUnit/ShipTo, then use that to print */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label formats based on BusinessUnit or ShipTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!BusinessUnit~_ShipTo_~!ShipTo~_''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the BusinessUnit/SoldTo, then use that to print */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label formats based on BusinessUnit or SoldTo',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!BusinessUnit~_SoldTo_~!SoldTo~_''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the BusinessUnit/Account, then use that to print */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label formats based on BusinessUnit or Account',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!BusinessUnit~_Acct_~!Account~_''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* If there is a specific label for the AccountName, then use that to print */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label formats based on the AccountName',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!BusinessUnit~_AcctName_~!AccountName~_''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Print generic label for the client is there is no customer specific label defined */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get content label formats based on the customer',
       @vRuleQuery       = 'select LabelFormatName from LabelFormats
                            where LabelFormatName like ''ContentLabel%_~!BusinessUnit~_Generic''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 998; /* Generic label should be last in the list becuase if no other rule satisfies,
                                 then we would use the generic label */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*----------------------------------------------------------------------------*/
/* Print standard content label of CIMS for all orders */
select @vRuleCondition   = null,
       @vRuleDescription = 'Get standard content label of CIMS for all orders',
       @vRuleQuery       = 'select ''ContentLabel_4x6_Standard''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'I', /* Active */
       @vSortSeq         = 999; /* Generic label should be last in the list becuase if no other rule satisfies,
                                 then we would use the generic label */

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/*******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

/*******************************************************************************
 * LPN Label Format
 ******************************************************************************/
select  @vRuleSetType = 'LPNLabelToPrint';

delete from @RuleSets;
delete from @Rules;

/*----------------------------------------------------------------------------*/
/* Rule Set #1 - LPN labels to be printed from Tasks Page */
/*----------------------------------------------------------------------------*/
select @vRuleSetName        = 'LPNLabelToPrint',
       @vRuleSetDescription = 'Get LPN labels to print from tasks page',
       @vRuleSetFilter      = '~LabelType~ = ''LPN''',
       @vSortSeq            = 0,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Generic */
select @vRuleCondition   = null,
       @vRuleDescription = 'Generic rule to get labels',
       @vRuleQuery       = 'select ''LPN_4x3''',
       @vRuleQueryType   = 'Select',
       @vStatus          = 'A', /* Active */
       @vSortSeq         = 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, Status, SortSeq)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription,  @vRuleQuery, @vRuleQueryType, @vStatus, coalesce(@vSortSeq, 0);

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules;

Go
