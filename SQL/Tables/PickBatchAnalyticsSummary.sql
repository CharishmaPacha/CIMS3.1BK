/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: PickBatchAnalyticsSummary
------------------------------------------------------------------------------*/
-- Create Table PickBatchAnalyticsSummary (
--     RecordId                   TRecordId       identity (1,1) not null,
--
--     WaveId                     TRecordId,
--     WaveNo                     TPickBatchNo,
--     SubWaveNo                  TWaveNo,
--     WaveType                   TTypeCode,
--     Description                TDescription,
--     Status                     TStatus default 'A',
--
--     TotalUnits                 TQuantity   default 0,
--
--     AllocUnitsFromReserve      TQuantity   default 0,
--     AllocUnitsFromPTB          TQuantity   default 0,
--     AllocUnitsFromShelving     TQuantity   default 0,
--     AllocUnitsFromNonCon       TQuantity   default 0,
--     AllocForShorts             TQuantity   default 0,
--     AllocForNonSorts           TQuantity   default 0,
--     AllocCartDiscrete          TQuantity   default 0,
--     AllocGlassDiscrete         TQuantity   default 0,
--
--     PckdForNonSort             TQuantity   default 0,
--     PckdCartDiscrete           TQuantity   default 0,
--     PckdGlassDiscrete          TQuantity   default 0,
--     PckdFromShelving           TQuantity   default 0,
--     PckdForECOMPACK            TQuantity   default 0,
--     PckdForPTL                 TQuantity   default 0,
--     PckdForRMT                 TQuantity   default 0,
--     PckdForEMT                 TQuantity   default 0,
--     PckdNonConUnits            TQuantity   default 0,
--     PckdShipDockUnits          TQuantity   default 0,
--     PckdNoLastCarton           TQuantity   default 0,
--
--     ReplnToShelving            TQuantity   default 0,
--     ReplnToPTB                 TQuantity   default 0,
--
--     RtdRMT                     TQuantity   default 0,
--     RtdPTL                     TQuantity   default 0,
--     RtdEMT                     TQuantity   default 0,
--     RtdShipDock                TQuantity   default 0,
--
--     IndctdPrimarySorter        TQuantity   default 0,
--     IndctdSecondarySorter      TQuantity   default 0,
--     IndctdRMT                  TQuantity   default 0,
--
--     PackdUnits                 TQuantity   default 0,
--
--     LoadedUnits                TQuantity   default 0,
--     ShippedUnits               TQuantity   default 0,
--
--     WaveCreatedDate            TDateTime,
--
--     UDF1                       TUDF,   -- RMT started
--     UDF2                       TUDF,   -- PTL started
--     UDF3                       TUDF,
--     UDF4                       TUDF,
--     UDF5                       TUDF,
--     UDF6                       TUDF,
--     UDF7                       TUDF,
--     UDF8                       TUDF,
--     UDF9                       TUDF,
--     UDF10                      TUDF,
--
--     CreatedDate                TDateTime  default current_timestamp,
--     CreatedBy                  TUserId,
--
--     ModifiedDate               TDateTime,
--     ModifiedBy                 TUserId
--
--     constraint pkPickBatchAnalyticsSummary_RecordId PRIMARY KEY (RecordId)
-- );
--
-- create index ix_PickBatchAnalyticsSummary_WaveId   on PickBatchAnalyticsSummary (WaveId, Status) Include (WaveNo, CreatedDate, WaveCreatedDate);

Go
