/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/07  VS      Archive APIOutboundTransaction for Canceled ProcessStatus (BK-853)
  2021/11/01  RV      Setup APIInboundTransactions and APIOutboundTransactions (BK-510)
  2021/05/19  TK      Changes to Archive CaptureTrackingInfo (BK-291)
  2021/02/11  MS      Changes to update Archived on PrintJobDetails (BK-126)
  2020/11/12  SV      Added Rule to Archive InterfaceLog which are processed successfully (HA-1309)
  2020/09/20  AY      Setup RouterInstruction and RouterConfirmation tables (JL-65)
  2020/09/18  PHK     Added new rule for CC Task Archive (HA-1377)
  2020/08/05  VS      Initial version (S2GCA-1220)
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
/* Rules for : Archive the Old Data */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ArchiveData';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Archive the Old Data */
/******************************************************************************/
select @vRuleSetName        = 'ArchiveData',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Archive Old Data',
       @vStatus             = 'A', /* Active */
       @vSortSeq            = 0; -- Initialize for this set

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/******************************************************************************/
/* Cycle count tables */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Archive CC Task that are completed and Canceled  */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''CycleCount'', ''CCTasks''))',
       @vRuleDescription = 'Archive CC Tasks Data',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''Tasks'', ''1'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            update Tasks
                            set Archived = ''Y'' /* Yes */
                            where (Archived   = ''N'' /* No */ ) and (TaskType = ''CC'') and
                                  (Status in (''X'' /* Canceled */, ''C'' /* Completed */)) and
                                  (ModifiedOn <= @vArchiveDate)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Print tables */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Archive Print Jobs that are completed and Canceled  */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''Printing'', ''PrintJobs''))',
       @vRuleDescription = 'Archive Print Jobs Data',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''PrintJobs'', ''1'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            update PrintJobs
                            set Archived = ''Y'' /* Yes */
                            where (Archived   = ''N'' /* No */ ) and
                                  (PrintJobStatus in (''X'' /* Canceled */, ''C'' /* Completed */)) and
                                  (JobDate <= @vArchiveDate);

                            update PJD
                            set Archived = ''Y'' /* Yes */
                            from PrintJobDetails PJD join PrintJobs PJ on (PJD.PrintJobId = PJ.PrintJobId)
                            where (PJD.Archived   = ''N'' /* No */ ) and
                                  (PJD.PrintJobDetailStatus in (''X'' /* Canceled */, ''C'' /* Completed */)) and
                                  (PJ.Archived = ''Y'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Router tables */
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Archive Router Confirmations that are processed  */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''Router'', ''RouterConfirmation''))',
       @vRuleDescription = 'Archive Router Confirmations',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''RouterConfirmation'', ''1'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            update RouterConfirmation
                            set Archived = ''Y''
                            where (Archived        = ''N'') and
                                  (ProcessedStatus = ''Y'' /* Processed */) and
                                  (ProcessedOn     <= @vArchiveDate)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Archive Router Instructions that are processed  */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''Router'', ''RouterInstruction''))',
       @vRuleDescription = 'Archive Router Instruction',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''RouterInstruction'', ''1'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            /* Update RouterInstruction as Archived which are already exported */
                            update RouterInstruction
                            set Archived = ''Y''
                            where (Archived     = ''N'') and
                                  (ExportStatus = ''Y'' /* Processed */) and
                                  (ExportedOn  <= @vArchiveDate);
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Archive InterfaceLog records that are processed successfully */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''InterfaceLog''))',
       @vRuleDescription = 'Archive InterfaceLog which are successfully processed',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''InterfaceLog-Days'', ''1'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            /* Update InterfaceLog as Archived which are already processed successfully */
                            update InterfaceLog
                            set Archived = ''Y''
                            where (Archived   = ''N'') and
                                  (Status     = ''S'' /* Success */) and
                                  (CreatedOn <= @vArchiveDate);
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Archive InterfaceLog records that are not processed successfully */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''InterfaceLog''))',
       @vRuleDescription = 'Archive InterfaceLog which are not processed successfully',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''InterfaceLogErrors-Days'', ''60'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            /* Update InterfaceLog as Archived which are not processed successfully */
                            update InterfaceLog
                            set Archived = ''Y''
                            where (Archived  =  ''N'') and
                                  (Status    <> ''S'' /* Success */) and
                                  (CreatedOn <= @vArchiveDate);
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Archive CarrierTrackingInfo records which are delivered */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''CarrierTrackingInfo''))',
       @vRuleDescription = 'Archive CarrierTrackingInfo records which are delivered',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''CarrierTrackingInfo-Days'', ''1'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            /* Update CarrierTrackingInfo records as Archived that are delivered */
                            update CarrierTrackingInfo
                            set Archived = ''Y''
                            where (Archived = ''N'') and
                                  (DeliveredOn <= @vArchiveDate);
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Archive APIInboundTransactions records which are delivered */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''APIInboundTransactions''))',
       @vRuleDescription = 'Archive APIInboundTransactions records which are processed',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''APIInboundTransactions-Days'', ''1'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            /* Update APIInboundTransactions records as Archived that are processed */
                            update APIInboundTransactions
                            set Archived = ''Y''
                            where (Archived = ''N'') and
                                  (ProcessStatus in (''Processed'', ''Fail'')) and
                                  (ModifiedDate <= @vArchiveDate);
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Archive APIOutboundTransactions records which are delivered */
select @vRuleCondition   = '(~DataSet~ in (''All'', ''APIOutboundTransactions''))',
       @vRuleDescription = 'Archive APIOutboundTransactions records which are processed',
       @vRuleQuery       = 'declare  @vArchiveDate  TDate,
                                     @vArchiveDays  TInteger

                            /* Fetch the no of days from controls */
                            select @vArchiveDays = dbo.fn_Controls_GetAsInteger(''Archive'', ''APIOutboundTransactions-Days'', ''1'', ~BusinessUnit~, ~UserId~)
                            select @vArchiveDate = convert(date, getdate() - @vArchiveDays)

                            /* Update APIOutboundTransactions records as Archived that are processed */
                            update APIOutboundTransactions
                            set Archived = ''Y''
                            where (Archived = ''N'') and
                                  (ProcessStatus in (''Processed'', ''Fail'', ''Canceled'', ''NotRequired'')) and
                                  (ModifiedOn <= @vArchiveDate);
                            ',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
