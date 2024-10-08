/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/13  TK      Messages separated for each wave type (CID-1720)
  2020/11/22  TK      Initial Revision (CID-1513)
------------------------------------------------------------------------------*/

/*

  If FieldName is null, then we will consider DefaultValue
  If FieldName is not null and ConvertedField is not null then we will consider ConvertedField and replace FieldName in it
  If FieldName is not null and ConvertedField is null then we will consider FieldName only

*/

declare @vProcessName      TName,
        @vDataSetName      TName,
        @vBusinessUnit     TBusinessUnit;

select top 1 @vBusinessUnit = BusinessUnit from vwBusinessUnits;

/******************************************************************************/
select @vProcessName = 'CIMS6River',
       @vDataSetName = 'PickCanceled_PTS';

delete from InterfaceFields where ProcessName = @vProcessName and DataSetName = @vDataSetName and BusinessUnit = @vBusinessUnit;

insert into InterfaceFields
              (FieldName,                ExternalFieldName,                SortSeq,  FieldType,   FieldDefaultValue,   ProcessName,    DataSetName,    BusinessUnit)
/* GroupUpdate Root */
        select 'Current_TimeStamp',      'timestamp',                      1,        'datetime',  null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'messageType',                    2,        null,        'groupCancel',       @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'groupType',                      3,        null,        'orderPick',         @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'TempLabel',              'groupID',                        4,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit

/******************************************************************************/
select @vProcessName = 'CIMS6River',
       @vDataSetName = 'PickCanceled_PTC';

delete from InterfaceFields where ProcessName = @vProcessName and DataSetName = @vDataSetName and BusinessUnit = @vBusinessUnit;

insert into InterfaceFields
              (FieldName,                ExternalFieldName,                SortSeq,  FieldType,   FieldDefaultValue,   ProcessName,    DataSetName,    BusinessUnit)
/* GroupUpdate Root */
        select 'Current_TimeStamp',      'timestamp',                      1,        'datetime',  null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'messageType',                    2,        null,        'groupCancel',       @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'groupType',                      3,        null,        'batchPick',         @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'PickTicket',             'groupID',                        4,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit


/******************************************************************************/
select @vProcessName = 'CIMS6River',
       @vDataSetName = 'PickCanceled_SLB';

delete from InterfaceFields where ProcessName = @vProcessName and DataSetName = @vDataSetName and BusinessUnit = @vBusinessUnit;

insert into InterfaceFields
              (FieldName,                ExternalFieldName,                SortSeq,  FieldType,   FieldDefaultValue,   ProcessName,    DataSetName,    BusinessUnit)
/* GroupUpdate Root */
        select 'Current_TimeStamp',      'timestamp',                      1,        'datetime',  null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'messageType',                    2,        null,        'groupCancel',       @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'groupType',                      3,        null,        'batchPick',         @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'PickTicket',             'groupID',                        4,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit

Go
