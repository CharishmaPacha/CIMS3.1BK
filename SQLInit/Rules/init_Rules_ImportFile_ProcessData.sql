/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/11/12  PHK     Temp Changes to able to do Imports for SKUs (BK-1160)
  2022/03/10  PHK     Added new rules for SKUs file Imports (HA-109)
  2021/03/13  RKC     Added new rules to add the 0 in prefix for 04, 08 WH (HA-2252)
  2021/02/05  RKC     Added new rules for import inventory (CIMSV3-1323)
  2021/01/30  AY      Initialize BusinessUnit (HA-1946)
  2020/11/11  SV      Set up rules for Location File Imports (CIMSV3-1120)
  2020/03/23  MS      Changes to delete Existing records (CID-1276)
  2020/01/20  MS      Initial version (CID-1117)
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
/* Rules to update existing Records while importing */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ImportFile_ProcessData';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set to establish the KeyData for each of the File Types to be imported  */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_EstablishKeyData',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to setup Key data for various types of imports',
       @vSortSeq            = 10, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update KeyData for SPL */
select @vRuleCondition   = '~FileType~ = ''SPL''',
       @vRuleDescription = 'SKU Price List: Update Keydata',
       @vRuleQuery       = 'Update TMP
                            set TMP.KeyData = coalesce(SKU, '''') + ''-'' + coalesce(SoldToId, '''') + ''-'' + coalesce(CustSKU,'''')' +
                           'from ~!TempTableName~ TMP ;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update KeyData for LOC */
select @vRuleCondition   = '~FileType~ = ''LOC''',
       @vRuleDescription = 'Location: Update Keydata',
       @vRuleQuery       = 'Update TMP
                            set TMP.KeyData = Location
                            from ~!TempTableName~ TMP ;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update KeyData for Inventory imports */
select @vRuleCondition   = '~FileType~ = ''INV''',
       @vRuleDescription = 'Inventory: Update Keydata',
       @vRuleQuery       = 'Update TMP
                            set TMP.KeyData = coalesce(SKU, '''') + ''-'' + coalesce(Warehouse,'''') + ''-'' + cast(RecordId as varchar)
                            from ~!TempTableName~ TMP ;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update SKU Archived info on the temp table */
select @vRuleCondition   = '~FileType~ in (''SKU'')',
       @vRuleDescription = 'Process File: Update SKU Archived info on the temp table',
       @vRuleQuery       = 'update ~!TempTableName~
                            set Archived = ''N''',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'I', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set to establish the KeyData for each of the File Types to be imported  */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_AddRequiredColumn',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Rules to add required columns for various types of imports',
       @vSortSeq            = 20, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update KeyData for INV */
select @vRuleCondition   = '~FileType~ = ''INV''',
       @vRuleDescription = 'Import Inventory: Add required column',
       @vRuleQuery       = 'alter table ~!TempTableName~ add SKUId TRecordId ;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set for initializing the fields for import */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_Initialize',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Set of rules to be used for validating SKU Price List import',
       @vSortSeq            = 30, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to Initialize the fields and generic validations */
select @vRuleCondition   = null,
       @vRuleDescription = 'Process File: Initialize ValidationMsg & CreatedBy user',
       @vRuleQuery       = 'Update TMP
                            set TMP.CreatedBy     = ~UserId~,
                                TMP.ValidationMsg = '''' ,
                                TMP.BusinessUnit  = ~BusinessUnit~' +
                           'from ~!TempTableName~ TMP ;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate duplicate records */
select @vRuleCondition   = null,
       @vRuleDescription = 'Process File: Do not allow duplicate records',
       @vRuleQuery       = 'Update TMP set TMP.ValidationMsg += ''|| Duplicate Records''
                            from ~!TempTableName~ TMP
                            where (KeyData in (select KeyData
                                               from ~!TempTableName~
                                               group by KeyData
                                               having count(*) > 1));',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update record action as I if it has U and not exists in MainTable */
select @vRuleCondition   = '~FileType~ in (''SPL'')',
       @vRuleDescription = 'Process File: Update record action as I if it has U and not exists in MainTable',
       @vRuleQuery       = 'Update TT
                            set RecordAction = ''I''
                            from ~!TempTableName~ TT
                              left outer join ~!MainTableName~ MT on (TT.KeyData      = MT.~!KeyFieldName~) and
                                                                     (TT.BusinessUnit = MT.BusinessUnit)
                            where (TT.RecordAction = ''U'') and
                                  (MT.RecordId is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update record action as U if it exists in MainTable and it has action as Insert */
select @vRuleCondition   = '~FileType~ in (''SPL'')',
       @vRuleDescription = 'Process File: Update record action as U if it exists in Location Table',
       @vRuleQuery       = 'Update TT
                            set RecordAction = ''U''
                            from ~!TempTableName~ TT
                              left outer join ~!MainTableName~ MT on (TT.KeyData      = MT.~!KeyFieldName~) and
                                                                     (TT.BusinessUnit = MT.BusinessUnit)
                            where (TT.RecordAction = ''I'') and
                                  (MT.RecordId is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

  /*----------------------------------------------------------------------------*/
/* Rule to update record action as U if it exists in MainTable and it has action as Insert */
select @vRuleCondition   = '~FileType~ in (''INV'')',
       @vRuleDescription = 'Process File: Update SKU info on the temp table',
       @vRuleQuery       = 'Update TMP
                            set TMP.SKUId = S.SKUId
                            from ~!TempTableName~ TMP
                              cross apply dbo.fn_SKUs_GetScannedSKUs (TMP.SKU, ~BusinessUnit~) S',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update Warehouse value */
select @vRuleCondition   = '~FileType~ in (''INV'')',
       @vRuleDescription = 'Process File: Update correct WH info on the temp table',
       @vRuleQuery       = 'Update TMP
                            set TMP.Warehouse = case when Warehouse in (''8'',''4'') then ''0''+ Warehouse else Warehouse end
                            from ~!TempTableName~ TMP',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set for validations related to SKU Price List */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_INVValidations',
       @vRuleSetFilter      = '~FileType~ = ''INV''',
       @vRuleSetDescription = 'Set of rules to be used for validating Inv file import',
       @vSortSeq            = 50, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to validate SKU */
select @vRuleCondition   = '~FileType~ = ''INV''',
       @vRuleDescription = 'Process File: Update validation msg if SKU is invalid',
       @vRuleQuery       = 'Update TMP set TMP.ValidationMsg += ''|| Invalid SKU ''
                            from ~!TempTableName~ TMP
                              left outer join SKUs S on (TMP.SKU = S.SKU)
                            where (S.SKUId is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set for validations related to SKU Price List */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_SKUPriceListValidations',
       @vRuleSetFilter      = '~FileType~ = ''SPL''',
       @vRuleSetDescription = 'Set of rules to be used for validating SKU Price List import',
       @vSortSeq            = 50, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to validate SKU */
select @vRuleCondition   = '~FileType~ = ''SPL''',
       @vRuleDescription = 'Process File: Update validation msg if SKU is invalid',
       @vRuleQuery       = 'Update TMP set TMP.ValidationMsg += ''|| Invalid SKU ''
                            from ~!TempTableName~ TMP
                              left outer join SKUs S on (TMP.SKU = S.SKU)
                            where (S.SKUId is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate SoldToId */
select @vRuleCondition   = '~FileType~ = ''SPL''',
       @vRuleDescription = 'Process File: Update validation msg if SoldToId is invalid',
       @vRuleQuery       = 'Update TMP set TMP.ValidationMsg += ''|| Invalid SoldTo ''
                            from ~!TempTableName~ TMP
                              left outer join Contacts C on (TMP.SoldToId = C.ContactRefId)
                            where (C.ContactRefId is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate Price */
select @vRuleCondition   = '~FileType~ = ''SPL''',
       @vRuleDescription = 'Process File: Update validation msg if Price has Negative value',
       @vRuleQuery       = 'Update TMP set TMP.ValidationMsg += ''|| Invalid Price ''
                            from ~!TempTableName~ TMP
                            where (TMP.UnitSalePrice like ''-%'' OR TMP.RetailUnitPrice like ''-%'');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set for importing Locations */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_Location',
       @vRuleSetFilter      = '~FileType~ = ''LOC''',
       @vRuleSetDescription = 'Set of rules to be used for validating Location import',
       @vSortSeq            = 60, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update record action as I if it has U and not exists in Location Table
   default rule above cannot be used as that assumes that the key field is RecordId
   where as it is LocationId */
select @vRuleCondition   = '~FileType~ = ''LOC''',
       @vRuleDescription = 'Process File: Update record action as I if it has U and does not exist in Location Table',
       @vRuleQuery       = 'Update TT
                            set RecordAction = ''I''
                            from ~!TempTableName~ TT
                              left outer join ~!MainTableName~ MT on (TT.KeyData      = MT.~!KeyFieldName~) and
                                                                     (TT.BusinessUnit = MT.BusinessUnit)
                            where (TT.RecordAction = ''U'') and
                                  (MT.LocationId is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update record action as U if it exists in MainTable and it has action as Insert */
select @vRuleCondition   = '~FileType~ = ''LOC''',
       @vRuleDescription = 'Process File: Update record action as U if it exists in MainTable',
       @vRuleQuery       = 'Update TT
                            set RecordAction = ''U''
                            from ~!TempTableName~ TT
                              left outer join ~!MainTableName~ MT on (TT.KeyData      = MT.~!KeyFieldName~) and
                                                                     (TT.BusinessUnit = MT.BusinessUnit)
                            where (TT.RecordAction = ''I'') and
                                  (MT.LocationId is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate Location */
select @vRuleCondition   = '~FileType~ = ''LOC''',
       @vRuleDescription = 'Process File: Update validation msg if Location already exists',
       @vRuleQuery       = 'Update TT set TT.ValidationMsg += ''|| Location does not exist''
                            from ~!TempTableName~ TT
                              left outer join Locations L on (TT.Location = L.Location)
                            where (TT.RecordAction not in ( ''I'')) and
                                  (L.LocationId is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set for importing SKUs */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_SKU',
       @vRuleSetFilter      = '~FileType~ = ''SKU''',
       @vRuleSetDescription = 'Set of rules to be used for validating SKU import',
       @vSortSeq            = 220, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update record action as I if it has U and not exists in SKUs Table
   default rule above cannot be used as that assumes that the key field is RecordId
   where as it is SKUId */
select @vRuleCondition   = '~FileType~ = ''SKU''',
       @vRuleDescription = 'Process File: Update record action as I if it has U and does not exist in SKUs Table',
       @vRuleQuery       = 'update TT
                            set RecordAction = ''I''
                            from ~!TempTableName~ TT
                              left outer join ~!MainTableName~ MT on (TT.KeyData      = MT.~!KeyFieldName~) and
                                                                     (TT.BusinessUnit = MT.BusinessUnit)
                            where (TT.RecordAction = ''U'') and
                                  (MT.SKU is null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to update record action as U if it exists in MainTable and it has action as Insert */
select @vRuleCondition   = '~FileType~ = ''SKU''',
       @vRuleDescription = 'Process File: Update record action as U if it exists in MainTable',
       @vRuleQuery       = 'update TT
                            set RecordAction = ''U''
                            from ~!TempTableName~ TT
                              left outer join ~!MainTableName~ MT on (TT.KeyData      = MT.~!KeyFieldName~) and
                                                                     (TT.BusinessUnit = MT.BusinessUnit)
                            where (TT.RecordAction = ''I'') and
                                  (MT.SKU is not null)',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'NA', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate SKUs */
select @vRuleCondition   = '~FileType~ = ''SKU''',
       @vRuleDescription = 'Process File: Update validation msg if SKU already exists',
       @vRuleQuery       = 'update TT set TT.ValidationMsg += ''|| SKU does not exist''
                            from ~!TempTableName~ TT
                              left outer join SKUs S on (TT.SKU = S.SKU)
                            where (TT.RecordAction not in ( ''I'')) and
                                  (S.SKU is null);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate SKUs if UOM is invalid */
select @vRuleCondition   = '~FileType~ = ''SKU''',
       @vRuleDescription = 'Process File: Update validation msg if UOM is invalid',
       @vRuleQuery       = 'update TT set TT.ValidationMsg += ''|| Invalid UoM''
                            from ~!TempTableName~ TT
                              left outer join vwLookUps L on (TT.UoM = L.LookUpCode) and
                                      (L.LookUpCategory = ''UoM'')
                            where (TT.UoM is not null) and (coalesce(L.LookUpDescription, '''') = '''');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate SKUs if SourceSystem is invalid */
select @vRuleCondition   = '~FileType~ = ''SKU''',
       @vRuleDescription = 'Process File: Update validation msg if SourceSystem is invalid',
       @vRuleQuery       = 'update TT set TT.ValidationMsg += ''|| Source System is not valid''
                            from ~!TempTableName~ TT
                              left outer join vwLookUps L on (TT.SourceSystem = L.LookUpCode) and
                                      (L.LookUpCategory = ''SourceSystem'')
                            where (TT.SourceSystem is not null) and (coalesce(L.LookUpDescription, '''') = '''');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate SKUs: We do not want to allow any deletes by diff source system */
select @vRuleCondition   = '~FileType~ = ''SKU''',
       @vRuleDescription = 'Process File: Update validation msg if tried to delete diff source system ',
       @vRuleQuery       = 'update TT set TT.ValidationMsg += ''|| Cannot delete data sent from a different Source System''
                            from ~!TempTableName~ TT
                              join SKUs S on (TT.SKU = S.SKU) and (S.SourceSystem <> TT.SourceSystem)
                            where (TT.RecordAction = ''D'' /* Delete */);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate SKUs: We do not allow update SKUs sent from diff source system */
select @vRuleCondition   = '~FileType~ = ''SKU''',
       @vRuleDescription = 'Process File: Update validation msg if tried to update diff source system ',
       @vRuleQuery       = 'update TT set TT.ValidationMsg += ''|| Cannot update data sent from a different Source System''
                            from ~!TempTableName~ TT
                              join SKUs S on (TT.SKU = S.SKU) and (S.SourceSystem <> TT.SourceSystem)
                            where (TT.RecordAction = ''U'' /* Update */) and
                                  (S.Status        = ''A'' /* Active */);',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/*----------------------------------------------------------------------------*/
/* Rule to validate SKUs if UPC is invalid */
select @vRuleCondition   = '~FileType~ = ''SKU''',
       @vRuleDescription = 'Process File: Update validation msg if UPC is invalid',
       @vRuleQuery       = 'update TT set TT.ValidationMsg += ''|| UPC is invalid as it is not numeric''
                            from ~!TempTableName~ TT
                            where (IsNumeric(TT.UPC) = ''0'') and (coalesce(TT.UPC, '''') <> '''');',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;
/******************************************************************************/
/* Rule Set for Load Routing Info */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_LoadRoutingInfo',
       @vRuleSetFilter      = '~FileType~ like ''LRI%''',
       @vRuleSetDescription = 'Set of updates to be used for doing final updates',
       @vSortSeq            = 100, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update records as Validation Failed */
select @vRuleCondition   = null,
       @vRuleDescription = 'Load Routing info: Delete blank lines',
       @vRuleQuery       = 'delete from ~!TempTableName~
                            where (coalesce(CustPO, '''') = '''')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
/* Rule Set for final updates */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_Finalize',
       @vRuleSetFilter      = null,
       @vRuleSetDescription = 'Set of updates to be used for doing final updates',
       @vSortSeq            = 90, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;
/*----------------------------------------------------------------------------*/
/* Rule to update records as Validation Failed */
select @vRuleCondition   = null,
       @vRuleDescription = 'Process File: Update records as Validation Failed if it has any ValidationMsg',
       @vRuleQuery       = 'update TMP set TMP.Validated      = case when coalesce(TMP.ValidationMsg, '''') <> ''''
                                                                  then ''N'' /* No */
                                                                else ''Y'' /* Yes */
                                                                end,
                                           TMP.ValidationMsg += case when coalesce(TMP.ValidationMsg, '''') <> ''''
                                                                  then ''||''
                                                                else ''''
                                                                end
                            from ~!TempTableName~ TMP;',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq         = 99;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

/******************************************************************************/
/******************************************************************************/
/* Rules to update existing Records while importing */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'ImportFile_UpdateRecords';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Description of this Rule set */
/******************************************************************************/
select @vRuleSetName        = 'ImportFile_UpdateRecords',
       @vRuleSetDescription = 'Update existing records while importing',
       @vRuleSetFilter      = null,
       @vSortSeq            = 900, -- Initialize for this set
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rule to update Existing Records */
select @vRuleCondition   = '~FileType~ = ''SPL''',
       @vRuleDescription = 'Process Data: Update existing records in SKUPriceList, if RecordAction is U ',
       @vRuleQuery       = 'update MT
                              set MT.RetailUnitPrice = coalesce(TT.RetailUnitPrice, MT.RetailUnitPrice),
                                  MT.UnitSalePrice   = coalesce(TT.UnitSalePrice, MT.UnitSalePrice)
                              from ~!MainTableName~ MT
                                join ~!TempTableName~ TT on (MT.~!KeyFieldName~ = TT.KeyData)
                              where (MT.Status       = ''A'' /* Active */) and
                                    (TT.RecordAction = ''U'' /* Update */) and
                                    (TT.Validated    = ''Y'')',
       @vRuleQueryType   = 'Update',
       @vStatus          = 'A', /* A-Active, I-In-Active, NA-Not Applicable */
       @vSortSeq        += 1;

insert into @Rules (RuleSetName, RuleCondition, RuleDescription, RuleQuery, RuleQueryType, SortSeq, Status)
  select @vRuleSetName, @vRuleCondition, @vRuleDescription, @vRuleQuery, @vRuleQueryType, coalesce(@vSortSeq, 0), @vStatus;

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R' /* I-Insert, R-Replace */;

Go
