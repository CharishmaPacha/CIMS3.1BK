/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/12  PK      Ported changes done by Pavan (HA-1897)
  2020/10/08  AY      Print label for Transfer Wave even for LPN Reservation (HA-1542)
  2020/08/07  MS      Initial version (HA-1273)
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
/* Rule Set : Determine which LPNs labels to print at Picking */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'PrintList_Picking';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Print labels for LPN */
/******************************************************************************/
select @vRuleSetName        = 'PrintList_Picking_BatchPicking',
       @vRuleSetFilter      = '(~Operation~ in (''BatchPicking'', ''LPNReservation''))',
       @vRuleSetDescription = 'BatchPicking: Determine which labels to print for LPN while Picking',
       @vSortSeq            = 0,   /* Set at this so that we can later add rules before this or after */
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*-------------------------------------------------------------------------------------------------------------*/
/* Transfer Waves: When LPN is Picked, we have to determine what label format to print for the Picked LPN */
/*-------------------------------------------------------------------------------------------------------------*/
select @vRuleCondition   = '(~WaveType~ = ''XFER'')',
       @vRuleDescription = 'BatchPicking: Determine the label format to print, for Transfer Waves',
       @vRuleQuery       = 'insert into #PrintList (EntityType, EntityId, EntityKey, DocumentClass, DocumentSubClass, DocumentType,
                                                    DocumentFormat, PrinterName, SortSeqNo, PrintDataFlag)
                              select EntityType, EntityId, EntityKey, ''Label'', ''ZPL'', ''LPN'',
                                     ''LPN_4x6_ContractorLabel'', LabelPrinterName, 1, ''Required''
                              from #EntitiesToPrint ETP
                              where (ETP.EntityType = ''LPN'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
