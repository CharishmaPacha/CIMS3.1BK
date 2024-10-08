/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/09/05  AY      PickBatchAttributes: Added ix_PBAttributes_PickBatchNo
  2015/12/08  RV      PickBatchAttributes: Added ReplenishBatchNo (FB-561)
  2014/05/18  PK      PickBatchAttributes: Added IsReplenished
  2014/04/10  TD      Added new table PickBatchAttributes.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: BatchAttributes:

      AvgUnitsPerOrder  =>  If the average number of units per order for all orders receiving a SKU
                            within a wave exceeds a given number, the entire SKU for that wave
                            should be processed through the PTL.

      UnitsPerLine      =>  If the number of units per line for any SKU exceeds a certain parameter,
                            those units associated with orders exceeding that units per line
                            parameter will be processed through the PTL.

      NumOrdersPerBatch =>  If the % of orders within the wave that receive a specific SKU exceeds a
                            user defined percentage, then the whole SKU for that wave will be
                            processed through the PTL.
------------------------------------------------------------------------------*/
Create Table PickBatchAttributes (
    RecordId                 TRecordId      identity (1,1) not null,

    /* PickBatchRelated */
    PickBatchId              TRecordId,
    PickBatchNo              TPickBatchNo,

    AvgUnitsPerOrder         TInteger,
    UnitsPerLine             TInteger,
    NumSKUOrdersPerBatch     TInteger,

    defaultDestination       TName,

    Status                   TStatus        not null default 'A' /* Active */,
    IsReplenished            TFlag          not null default 'N' /* No */,
    ReplenishBatchNo         TPickBatchNo,
    SorterExportStatus       TFlag,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    Warehouse                TWarehouse,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkPickBatchAttributes_RecordId PRIMARY KEY (RecordId)
);

create index ix_PBAttributes_PickBatchId         on PickBatchAttributes (PickBatchId) Include (PickBatchNo);
create index ix_PBAttributes_PickBatchNo         on PickBatchAttributes (PickBatchNo, IsReplenished, BusinessUnit) Include (PickBatchId);

Go
