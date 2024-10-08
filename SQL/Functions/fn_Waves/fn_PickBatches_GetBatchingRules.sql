/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/15  TK      fn_PickBatches_GetBatchingRules: Changes due to adding new field in TPickbatchRules table type (BK-64)
  fn_PickBatches_GetBatchingRules: Migrated from Prod (S2G-727)
  2016/02/05  TD      fn_PickBatches_GetBatchingRules:Changes to get OH_Category1 to OH_Category5 (NBD-99)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_PickBatches_GetBatchingRules') is not null
  drop Function fn_PickBatches_GetBatchingRules;
Go
/*------------------------------------------------------------------------------
  Proc fn_PickBatches_GetBatchingRules:  This Function will returns the
    Batchingrules.
------------------------------------------------------------------------------*/
Create Function fn_PickBatches_GetBatchingRules
  (@Rules        TXML,
   @BusinessUnit TBusinessUnit )
returns
  /* temp table  to return data */
  @SelectedBatchRules        table
    (RuleId                  TRecordId,
     WaveRuleGroup           TDescription,
     BatchingLevel           TDescription,
     OrderType               TTypeCode,
     OrderPriority           TPriority,
     ShipVia                 TShipVia,
     SoldToId                TCustomerId,
     ShipToId                TShipToId,
     Ownership               TOwnership,
     Warehouse               TWarehouse,
     Account                 TAccount,
     ShipFrom                TShipFrom,
     ShipToStore             TShipToStore,
     BatchType               TTypeCode,
     BatchPriority           TPriority,
     BatchStatus             TStatus,
     MaxOrders               TCount,
     MaxLines                TCount,
     MaxSKUs                 TCount,
     MaxUnits                TCount,
     MaxLPNs                 TCount,
     MaxInnerPacks           TCount,
     MaxWeight               TWeight,
     MaxVolume               TVolume,
     OrderWeightMin          TWeight,
     OrderWeightMax          TWeight,
     OrderVolumeMin          TVolume,
     OrderVolumeMax          TVolume,
     OrderInnerPacks         TInteger,
     OrderUnits              TInteger,
     PickBatchGroup          TWaveGroup,
     OrderDetailWeight       TWeight,
     OrderDetailVolume       TVolume,
     PutawayClass            TCategory,
     ProdCategory            TCategory,
     ProdSubCategory         TCategory,
     PutawayZone             TZoneId,
     SortSeqNo               TSortSeq,
     DestZone                TLookUpCode,
     DestLocation            TLocation,
     PickZone                TZoneId,
     Status                  TStatus,
     UDF1                    TUDF,
     UDF2                    TUDF,
     UDF3                    TUDF,
     UDF4                    TUDF,
     UDF5                    TUDF,
     OH_UDF1                 TUDF,
     OH_UDF2                 TUDF,
     OH_UDF3                 TUDF,
     OH_UDF4                 TUDF,
     OH_UDF5                 TUDF,
     OH_Category1            TCategory,
     OH_Category2            TCategory,
     OH_Category3            TCategory,
     OH_Category4            TCategory,
     OH_Category5            TCategory
    )
as
begin
  declare @vRules xml;

  /* if user does not providethe rules then we need to use system rules */
  if (coalesce(@Rules, '') = '')
    begin
      insert into @SelectedBatchRules
        select RuleId, WaveRuleGroup, BatchingLevel, OrderType, OrderPriority, ShipVia, SoldToId,
               ShipToId, Ownership, Warehouse, Account, ShipFrom, ShipToStore,
               BatchType, BatchPriority, BatchStatus,
               coalesce(MaxOrders, 9999999), coalesce(MaxLines, 9999999),
               coalesce(MaxSKUs, 9999999),   coalesce(MaxUnits, 9999999),
               coalesce(MaxLPNs, 9999999),   coalesce(MaxInnerPacks, 9999999),
               coalesce(MaxVolume, 9999999), coalesce(MaxWeight, 9999999),
               coalesce(OrderWeightMin, 0),  coalesce(OrderWeightMax, 9999999),
               coalesce(OrderVolumeMin, 0),  coalesce(OrderVolumeMax, 9999999),
               coalesce(OrderInnerPacks, 999999), coalesce(OrderUnits,  9999999),
               PickBatchGroup,               coalesce(OrderDetailWeight, 9999999),
               coalesce(OrderDetailVolume,  9999999),
               PutawayClass, ProdCategory, ProdSubCategory, PutawayZone,
               SortSeq, DestZone, DestLocation, PickZone, Status,
               UDF1, UDF2, UDF3, UDF4, UDF5,
               OH_UDF1, OH_UDF2, OH_UDF3, OH_UDF4, OH_UDF5, OH_Category1,
               OH_Category2, OH_Category3, OH_Category4, OH_Category5
        from vwBatchingRules
        where (Status = 'A'/* Active */) and
              (BusinessUnit = @BusinessUnit)
        order by SortSeq
    end
  else
  begin
    /* convert Rules xml data from varchar datatype to xml data type */
    select @vRules  = convert(xml, @Rules);
    /* Insert data into table fro mthe xml  */
    insert into @SelectedBatchRules
      select Record.Col.value('RuleId[1]',       'TRecordId'), -- RuleId,
             Record.Col.value('WaveRuleGroup[1]','TDescription'), -- WaveRuleGroup,
             Record.Col.value('BatchingLevel[1]','TTypeCode'), -- OrderType,
             Record.Col.value('OrderType[1]',    'TTypeCode'), -- OrderType,
             Record.Col.value('OrderPriority[1]','TPriority'), -- OrderPriority,
             Record.Col.value('ShipVia[1]',      'TShipVia'), -- ShipVia,
             Record.Col.value('SoldToId[1]',     'TCustomerId'), -- SoldToId,
             Record.Col.value('ShipToId[1]',     'TShipToId'), -- ShipToId,
             Record.Col.value('Ownership[1]',    'TOwnership'),
             Record.Col.value('Warehouse[1]',    'TWarehouse'),
             Record.Col.value('Account[1]',      'TAccount'),
             Record.Col.value('ShipFrom[1]',     'TShipFrom'),
             Record.Col.value('ShipToStore[1]',  'TShipToStore'),
             Record.Col.value('BatchType[1]',    'TTypeCode'), -- BatchType,
             Record.Col.value('BatchPriority[1]','TPriority'), -- BatchPriority,
             Record.Col.value('BatchStatus[1]',  'TStatus'), -- BatchStatus,
             coalesce(nullif(Record.Col.value('MaxOrders[1]',    'TCount'), 0), 9999999), -- coalesce(nullif(MaxOrders, 0), 99999),
             coalesce(nullif(Record.Col.value('MaxLines[1]',     'TCount'), 0), 9999999), -- coalesce(nullif(MaxLines, 0),  99999),
             coalesce(nullif(Record.Col.value('MaxSKUs[1]',      'TCount'), 0), 9999999), -- coalesce(nullif(MaxSKUs, 0),   99999),
             coalesce(nullif(Record.Col.value('MaxUnits[1]',     'TCount'), 0), 9999999), -- coalesce(nullif(MaxUnits, 0),  99999),
             coalesce(nullif(Record.Col.value('MaxLPNs[1]',        'TCount'), 0), 9999999),
             coalesce(nullif(Record.Col.value('MaxInnerPacks[1]',  'TCount'), 0), 9999999),
             coalesce(nullif(Record.Col.value('MaxWeight[1]',      'TWeight'), 0), 9999999),
             coalesce(nullif(Record.Col.value('MaxVolume[1]',      'TVolume'), 0), 9999999),
             coalesce(nullif(Record.Col.value('OrderWeightMin[1]', 'TWeight'), 0), 0),
             coalesce(nullif(Record.Col.value('OrderWeightMax[1]', 'TWeight'), 0), 9999999),
             coalesce(nullif(Record.Col.value('OrderVolumeMin[1]', 'TVolume'), 0), 0),
             coalesce(nullif(Record.Col.value('OrderVolumeMax[1]', 'TVolume'), 0), 9999999),
             coalesce(nullif(Record.Col.value('OrderInnerPacks[1]','TInteger'), 0), 99999),
             coalesce(nullif(Record.Col.value('OrderUnits[1]',     'TInteger'), 0), 999999),
             Record.Col.value('PickBatchGroup[1]',                 'TWaveGroup'), -- ShipToId,
             coalesce(nullif(Record.Col.value('OrderDetailWeight[1]',   'TWeight'), 0), 9999999),
             coalesce(nullif(Record.Col.value('OrderDetailVolume[1]',   'TVolume'), 0), 9999999),
             Record.Col.value('PutawayClass[1]',       'TCategory'),
             Record.Col.value('ProdCategory[1]',       'TCategory'),
             Record.Col.value('ProdSubCategory[1]',    'TCategory'),
             Record.Col.value('PutawayZone[1]',        'TCategory'),
             Record.Col.value('SortSeq[1]',      'TSortSeq'), -- SortSeq,
             Record.Col.value('DestZone[1]',     'TLookUpCode'), -- DestZone,
             Record.Col.value('DestLocation[1]', 'TLocation'), -- DestLocation,
             Record.Col.value('PickZone[1]',     'TZoneId'), -- DestLocation,
             null /* Status */,
             Record.Col.value('UDF1[1]',         'TUDF'),
             Record.Col.value('UDF2[1]',         'TUDF'),
             Record.Col.value('UDF3[1]',         'TUDF'),
             Record.Col.value('UDF4[1]',         'TUDF'),
             Record.Col.value('UDF5[1]',         'TUDF'),
             Record.Col.value('OH_UDF1[1]',      'TUDF'), -- OH_UDF1,
             Record.Col.value('OH_UDF2[1]',      'TUDF'), -- OH_UDF2,
             Record.Col.value('OH_UDF3[1]',      'TUDF'), -- OH_UDF3,
             Record.Col.value('OH_UDF4[1]',      'TUDF'), -- OH_UDF4,
             Record.Col.value('OH_UDF5[1]',      'TUDF'), -- OH_UDF5
             Record.Col.value('OH_Category1[1]', 'TCategory'),
             Record.Col.value('OH_Category2[1]', 'TCategory'),
             Record.Col.value('OH_Category3[1]', 'TCategory'),
             Record.Col.value('OH_Category4[1]', 'TCategory'),
             Record.Col.value('OH_Category5[1]', 'TCategory')
      from @vRules.nodes('/BatchRules/BatchRule') as Record(Col)
  end

  return;
end /* fn_PickBatches_GetBatchingRules */

Go
