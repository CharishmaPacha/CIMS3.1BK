/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/12  TK      Changes to use function to build container info (CID-1778)
  2021/02/12  TK      Product dimensions should be of type Float (CID-1715)
  2021/02/11  TK      UnitLength & UnitWidth should be '1' by default and
                        added dimensionUnitOfMeasure & weightUnitOfMeasure (CID-1714)
  2021/01/28  AY      Mapped data.priority to WavePriority, expectedShippingDate to OH.DownloadedDate (CID-6River support)
  2020/01/27  AY      Mappped product.name to SKU (CID-Support)
  2021/01/15  TK      Separated Pick wave message for each wave type (CID-1624)
  2021/01/04  TK      Changes to export CoO & OrderType (CID-1599)
  2020/11/16  TK      Initial Revision (CID-1498)
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
       @vDataSetName = 'PickWave_PTS';

delete from InterfaceFields where ProcessName = @vProcessName and DataSetName = @vDataSetName and BusinessUnit = @vBusinessUnit;

insert into InterfaceFields
              (FieldName,                ExternalFieldName,                SortSeq,  FieldType,   FieldDefaultValue,   ProcessName,    DataSetName,    BusinessUnit)
/* pickWave */
        select 'TaskDetailId',           'pickID',                         1,        'string',    null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitsToPick',            'eachQuantity',                   2,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'Location',               'sourceLocation',                 3,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'groupType',                      4,        null,        'orderPick',         @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'TempLabel',              'groupID',                        5,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'DropLocation',           'destinationLocation',            6,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'consolidate',                    7,        null,        'false',             @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'skipBatchIfSingleTote',          8,        null,        'false',             @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'DownloadedDate',         'expectedShippingDate',           9,        'datetime',  null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.product */
  union select 'SKU',                    'product.productID',              20,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'ShipPack',               'product.unitOfMeasureQuantity',  21,       null,        '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UoM',                    'product.unitOfMeasure',          23,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'SKU',                    'product.name',                   24,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'SKUDescription',         'product.description',            25,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitVolume',             'product.length',                 26,       'float',     null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.width',                  27,       'float',     '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.height',                 28,       'float',     '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitWeight',             'product.weight',                 29,       'float',     null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.dimensionUnitOfMeasure', 30,       null,        'in',                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.weightUnitOfMeasure',    31,       null,        'lb',                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'dbo.fn_API_6River_PickWave_BuildArrayOfIdentifiers(TaskDetailId)',
                                         'product.identifiers',            32,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.container */
  union select 'dbo.fn_API_6River_PickWave_BuildArrayOfContainerInfo(TaskDetailId)',              
                                         'container',                      50,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.Data */
  union select 'WaveType',               'data.WaveType',                  70,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WaveId',                 'data.WaveId',                    71,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WaveNo',                 'data.WaveNo',                    72,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'OrderId',                'data.OrderId',                   73,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'PickTicket',             'data.PickTicket',                74,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'OrderType',              'data.orderType',                 76,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WavePriority',           'data.priority',                  77,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit

/******************************************************************************/
select @vProcessName = 'CIMS6River',
       @vDataSetName = 'PickWave_PTC';

delete from InterfaceFields where ProcessName = @vProcessName and DataSetName = @vDataSetName and BusinessUnit = @vBusinessUnit;

insert into InterfaceFields
              (FieldName,                ExternalFieldName,                SortSeq,  FieldType,   FieldDefaultValue,   ProcessName,    DataSetName,    BusinessUnit)
/* pickWave */
        select 'TaskDetailId',           'pickID',                         1,        'string',    null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitsToPick',            'eachQuantity',                   2,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'Location',               'sourceLocation',                 3,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'groupType',                      4,        null,        'batchPick',         @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'PickTicket',             'groupID',                        5,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'DropLocation',           'destinationLocation',            6,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'consolidate',                    7,        null,        'false',             @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'skipBatchIfSingleTote',          8,        null,        'false',             @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'DownloadedDate',         'expectedShippingDate',           9,        'datetime',  null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.product */
  union select 'SKU',                    'product.productID',              20,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'ShipPack',               'product.unitOfMeasureQuantity',  21,       null,        '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UoM',                    'product.unitOfMeasure',          23,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'SKU',                    'product.name',                   24,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'SKUDescription',         'product.description',            25,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitVolume',             'product.length',                 26,       'float',     null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.width',                  27,       'float',     '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.height',                 28,       'float',     '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitWeight',             'product.weight',                 29,       'float',     null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.dimensionUnitOfMeasure', 30,       null,        'in',                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.weightUnitOfMeasure',    31,       null,        'lb',                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'dbo.fn_API_6River_PickWave_BuildArrayOfIdentifiers(TaskDetailId)',
                                         'product.identifiers',            32,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.container */
  union select 'TempLabel',              'container.containerID',          50,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'CartonType',             'container.containerType',        51,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.Data */
  union select 'WaveType',               'data.WaveType',                  70,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WaveId',                 'data.WaveId',                    71,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WaveNo',                 'data.WaveNo',                    72,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'OrderId',                'data.OrderId',                   73,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'PickTicket',             'data.PickTicket',                74,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'OrderType',              'data.orderType',                 76,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WavePriority',           'data.priority',                  77,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit

/******************************************************************************/
select @vProcessName = 'CIMS6River',
       @vDataSetName = 'PickWave_SLB';

delete from InterfaceFields where ProcessName = @vProcessName and DataSetName = @vDataSetName and BusinessUnit = @vBusinessUnit;

insert into InterfaceFields
              (FieldName,                ExternalFieldName,                SortSeq,  FieldType,   FieldDefaultValue,   ProcessName,    DataSetName,    BusinessUnit)
/* pickWave */
        select 'TaskDetailId',           'pickID',                         1,        'string',    null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitsToPick',            'eachQuantity',                   2,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'Location',               'sourceLocation',                 3,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'groupType',                      4,        null,        'batchPick',         @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'PickTicket',             'groupID',                        5,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'DropLocation',           'destinationLocation',            6,        null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'consolidate',                    7,        null,        'false',             @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'skipBatchIfSingleTote',          8,        null,        'false',             @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'OrderCreatedDate',       'expectedShippingDate',           9,        'datetime',  null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.product */
  union select 'SKU',                    'product.productID',              20,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'ShipPack',               'product.unitOfMeasureQuantity',  21,       null,        '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UoM',                    'product.unitOfMeasure',          23,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'SKU',                    'product.name',                   24,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'SKUDescription',         'product.description',            25,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitVolume',             'product.length',                 26,       'float',     null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.width',                  27,       'float',     '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.height',                 28,       'float',     '1',                 @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'UnitWeight',             'product.weight',                 29,       'float',     null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.dimensionUnitOfMeasure', 30,       null,        'in',                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select null,                     'product.weightUnitOfMeasure',    31,       null,        'lb',                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'dbo.fn_API_6River_PickWave_BuildArrayOfIdentifiers(TaskDetailId)',
                                         'product.identifiers',            32,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.container */
  union select 'TempLabel',              'container.containerID',          50,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'CartonType',             'container.containerType',        51,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
/* pickWave.Data */
  union select 'WaveType',               'data.WaveType',                  70,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WaveId',                 'data.WaveId',                    71,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WaveNo',                 'data.WaveNo',                    72,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'OrderId',                'data.OrderId',                   73,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'PickTicket',             'data.PickTicket',                74,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'OrderType',              'data.orderType',                 76,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit
  union select 'WavePriority',           'data.priority',                  77,       null,        null,                @vProcessName,  @vDataSetName,  @vBusinessUnit

Go
