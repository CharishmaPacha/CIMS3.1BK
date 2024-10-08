/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/07/12  VM      TLabelFormats: Moved to Base (CIMSV3-2949)
  2023/07/11  VM      Moved several domains from WMS to Base (CIMSV3-2928)
  2023/06/29  RKC     THostReference: Added (OBV3-1836)
  2023/06/06  AY      TInventoryKey: Changed from varchar(max) to varchar(200) as prior cannot be indexed (JLFL-331)
  2023/05/22  RKC     TAuditTrailInfo: Comment datatype Changed from varchar(500) to varchar(5000) (JLCA-820)
  2023/04/12  AY      TRuleSetsTable: Added RuleSetFilterSQL (CIMSV3-2537)
  2023/01/24  RV      Added TFilePath (CIMSV3-2530)
  2023/01/19  VS      Added TCurrency (OBV3-1652)
  2023/01/03  MS      Added TXMLRulesData (CIMSV3-2537)
  2022/11/02  VM      TControlsTable: Visible datatype changed to TInteger (CIMSV3-2384)
  2022/10/05  AY      Added TLookUpsTable.CreatedBy (OBV3-1255)
  2022/09/22  SK      Added TChar (CIMSV3-2161)
  2022/06/15  GAG     Added TJson (OBV3-527)
  2022/02/04  TK      Added TInventoryKey (FBV3-810)
  2021/11/05  AY      TFlags: Expand to 100 to use descriptive words instead of codes (CIMSV3-1490)
  2021/09/29  RV      TSortSeq -> Changed data type from smallint to integer (HA-3195)
  2020/07/30  AY      Added TLabelFormats.DBObjectName (BK-446)
  2020/11/09  AJM     Removed TPrintStatus which will now be using TStatus (CIMSV3-1201)
  2020/10/19  VM      TFieldsTable: Add TooTip (CIMSV3-1132)
  2020/10/12  AY      Added TKeyValue (HA-1576)
  2020/08/13  RKC     Added TPasswordPolicy, TEncryptedPassword (S2G-1409)
  2020/07/30  RV      Added TPrintStatus (S2GCA-1199)
  2020/07/21  AY      TCycleCountTable: Moved to domains_temptables due to dependencies
  2020/07/11  SK      TCycleCountTable Added PalletId (HA-1077)
  2020/07/10  AY      TNameValuePairs: Changed to use UDTs
  2020/07/08  YJ      TLabelFormats: Added column LabelTemplateType (HA-1035)
  2020/06/05  AY      TXMLNodes: Added TagName & ProcessFlag for processing of data (HA-579)
  2020/06/03  AY      TString: Expanded size to 200 for general purpose use
  2020/04/28  SK      Added TCycleCountTable (CIMSV3-788)
  2020/04/23  AY      Added TSQLOrderBy (CIMSV3-478)
  2020/04/10  VS      Added TRoleName (HA-96)
  2020/04/06  MS      Added TLabelFormats (CIMSV3-804)
  2019/10/31  NB      TFieldsTable: Added FieldGroups, DefaultFilterCondition (CIMSV3-642)
  2019/10/03  AY      TValidations: Renamed Parent to Master (CID-1086)
  2019/08/30  AY      TTransactionScope added, TRules: Added TransactionScope (CID-883)
  2019/08/02  AY      TXMLNodes: Added RecordId (CID-884)
  2019/07/20  AY      Added TValidations to capture failures and report back (CID-GoLive)
  2019/06/20  AY      Add TXMLNodes.RecordId (S2G-1276)
  2019/05/07  VM      Moved V3 specific to V3 branch files (CIMSV3-406)
  2019/04/23  VM      TFieldUIAttributes: Added DecimalPrecision (CIMSV3-457)
  2019/04/01  TK      TAuditTrailInfo: Included ActivityType in unique key (S2GCA-480)
  2019/03/26  VM      Added TSQLCondition (CIMSV3-409)
  2019/03/15  RV      Added Image type (CID-184)
  2019/01/11  OK      TAuditTrailInfo: Included UDF1 in unique constraint to allow any other field while using in procedure (HPI-2318)
  2018/11/17  AY      Added UDFs to TRecountKeysTable
  2018/10/17  AY      Changed TCategory to be 150 chars as it is used for grouping (S2GCA-)
  2018/09/07  AY      Added TSQL (S2G-1059)
  2018/07/25  AY      Added TClass (S2G-1056)
  2018/07/16  NB      Modified TUIMenuDetails: Added UITarget, HandlerTagName and StartNewMenuGroup(CIMSV3-299)
  2018/06/06  AY      Added TSortOrder
  2018/05/28  NB      Modified TEntityValuesTable to have UDFs and removed identity definition for RecordId(CIMSV3-152)
  2018/05/24  NB      Added TEntityValuesTable(CIMSV3-152)
  2018/05/06  AY      TRuleSetType: Expanded size to 50 (S2G-690)
  2018/04/24  NB      TFieldUIAttributes: Added new columns introduced into table FieldUIAttributes(CIMSV3-152)
  2018/01/08  NB      TFieldUIAttributes: Changed UIControl column type to TName(CIMSV3-203)
  2017/12/14  RA      Added TFileName (CIMS-1659)
  2018/01/02  AY      Added TUIMenuDetails (CIMSV3-157)
  2017/12/28  NB      TLayoutFieldsExpandedTable: Renamed IsKeyField -> KeyFieldType (CIMSV3-166)
  2017/11/18  YJ      Added TFieldUIAttributes (CIMSV3-133)
  2017/09/29  YJ      Added TLayoutTable (CIMSV3-73)
  2017/09/24  AY      Expanded TFieldsTable to include IsSelectable
  2017/08/10  AY      Added TLayoutFieldsExpandedTable to include new fields (CIMSV3-13)
  2017/08/08  YJ      Added TDebugControlsTable (HPI-1609)
  2017/08/03  AY      Added TJobCode (CIMS-1426)
  2017/07/25  YJ      Added field Visible for TLookUpsTable (CIMS-1521)
  2017/07/24  AY      Added TFilterValue (CIMSV3-13)
  2016/11/11  AY      Added TRecountKeysTable (HPI-993)
  2016/08/01  AY      Expanded TResult to varchar(max) (HPI-239), TDeviceId to 120.
  2016/06/07  PSK     Added multiple fields in TControlsTable (CIMS-963)
  2016/05/24  NY      TEntityKey: Changes to varchar(100) (TDAX-350)
  2016/03/18  OK      Added multiple fields in TRulesTable and TRuleSetsTable (HPI-29)
  2015/03/01  AY      Expanded TOwnership
  2015/08/26  AY      Added TEntityKey
  2015/08/14  AY      Added TPrintFlags
  2015/07/02  TK      Added TRules
  2015/05/18  AY      Added RuleSetName to TRuleSets and TRules
  2015/02/20  DK      Added TInputParams.
  2015/02/13  SV      Added TOwnership, TWarehouse from domains_Inventory as we are using in TRuleSetsTable
  2104/12/19  AK      Added TRuleSetsTable and TRulesTable.
  2014/10/13  AY      Added TNameValuePairs
  2014/09/17  PKS     Moved TEntityStatusCounts to domains_TempTables.Sql
  2014/09/11  TD      Added TEntityStatusCounts
  2014/05/28  NB      Added TAuditTrailInfo
  2014/05/13  SV      Added TRuleSetType, TQuery and TResult
  2014/04/15  AY      Added TControlsTable
  2014/03/31  TD      TLayoutFieldsTable,TFieldsTable:Added ToolTip.
  2014/01/28  AY      Added TLookUpsTable
  2013/10/10  AY      Added TStatusesTable, TEntityTypesTable
  2013/08/05  AY      Added TWidth, THeight
  2013/07/30  AY      Added TAttribute, TNote.
  2013/04/17  PKS     TEntity size increased from 20 to 50.
  2013/03/30  AY      Added TFieldsTable
  2013/02/10  AY      Added TLayoutFieldsTable
  2013/01/31  AY      Expanded TCategory to 50 chars
  2012/11/07  PKS     Added TAction.
  2012/09/01  AY      Added TDate, TTime, TOperation
  2012/07/26  AY      Added TMessage
  2012/07/11  PK      Added TPassword
  2012/07/11  AY      Added TUserName as we have been using TUserId instead!
  2012/05/19  AY      Added TEntityKeysTable
  2012/04/25  PK      Added TActivityType.
  2012/04/25  YA      Modified TDeviceId(10) -> TDeviceId(20) as init file for device does not accept for previous domain.
  2012/04/19  AY      Added TBinary
  2012/01/13  YA      Added TXML
  2011/12/27  AY      Added TFlags
  2011/12/20  PK      Added TPercent
  2011/11/12  AY      Added TUnitPrice, TMoney
  2011/09/05  NB      Added TLength
  2011/02/08  VK      Added TBoolean domain to LookUps.
  2011/01/25  VM      Added Device data types.
  2011/01/13  VM      Added TCharSet (Can be used for 'A' - Alphabets, 'N' - Numeric, 'AN' - Alpha Numeric).
  2010/12/14  VM      Added TVarChar, TNVarChar
  2010/10/25  AR      TUserId: varchar(30) -> varchar(128), because may not
                      necessarily be a RFCL user, but could be a Windows Identity
                      or other, depending on who is making the change. system_user
                      is nvarchar(128) so we should match that.
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/* Common */

/* Dependent */
Create Type TOwnership                 from varchar(30);        grant references on Type:: TOwnership                 to public;
Create Type TWarehouse                 from varchar(10);        grant references on Type:: TWarehouse                 to public;

Go
