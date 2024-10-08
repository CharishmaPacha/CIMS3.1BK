/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/18  AY      Added Seq_Batch (HA-1962)
  2021/02/03  PK      Added LPN_Temp (HA-1970)
  2020/11/13  SK      Added Seq_Dashboard_TrackReceiver (JL-288)
  2020/05/09  TK      Added Seq_ShipLabels_ProcessBatch (HA-468)
  2020/02/20  AY      Changed to generate sequences with big int
  2020/01/30  AY      Enhanced to generate sequences using BusinessuUnit.
  2019/10/20  AY      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
Sequences to be used to generate the next sequence number for various entities
------------------------------------------------------------------------------*/

Go

declare @ttSequences as table(
  SeqName    varchar(30),
  StartValue varchar(20),
  MaxValue   varchar(20),
  Cycle      varchar(10)
  )

/*----------------------------------------------------------------------------*/
/* List the sequences to be created */

/*                               SeqName                        StartValue      MaxValue        Cycle */
insert into @ttSequences select 'Seq_COOrder',                  1,              null,           null
insert into @ttSequences select 'Seq_DaB_TrackReceiver',        1,              999999999,      'Cycle'
insert into @ttSequences select 'Seq_LPN',                      1,              999999999,      'Cycle'
insert into @ttSequences select 'Seq_LPN_Temp',                 1,              999999999,      'Cycle'
insert into @ttSequences select 'Seq_LPN_Ship',                 1,              999999999,      'Cycle'
insert into @ttSequences select 'Seq_LPN_Tote',                 1,              999999999,      'Cycle'
insert into @ttSequences select 'Seq_Pallet_I',                 1,              999999,         'Cycle'
insert into @ttSequences select 'Seq_Pallet_C',                 1,              999999,         'Cycle'

insert into @ttSequences select 'Seq_ShipLabels_ProcessBatch',  1,              999999999,      'Cycle'

insert into @ttSequences select 'UCC128_0000000',               1,              999999999,      'Cycle'

/* Generic Batchno for several purposes where we don't care to have a sequential series, but just a unique batch no */
insert into @ttSequences select 'Seq_Batch',                    1,              999999999,      'Cycle'

declare @CreateSQL TNVarchar = '';
declare @DropSQL TNVarchar = '';

/*----------------------------------------------------------------------------*/
/* Build create SQL */
select @CreateSQL += 'Create Sequence ' + S.SeqName + '_' + BU.BusinessUnit + ' as bigint ' +
               ' Start with ' + S.StartValue +
               ' MinValue  ' + S.StartValue +
               coalesce(' MaxValue ' + S.MaxValue, '') +
               coalesce (' ' + S.Cycle, '') + ';'
from @ttSequences S, vwBusinessUnits BU;

/*----------------------------------------------------------------------------*/
/* Build drop SQL */
select @DropSQL += 'Drop Sequence ' + S.SeqName + '_' + BU.BusinessUnit + ';'
from @ttSequences S, vwBusinessUnits BU;

-- select @DropSQL;
-- select @CreateSQL;
--
-- exec sp_executesql @DropSQL;
exec sp_executesql @CreateSQL;

--select name, current_value, last_used_value, maximum_value, minimum_value, * from sys.sequences;

/*----------------------------------------------------------------------------*/
/* Use below to restart sequence at a larger number to avoid conflicts */
--Alter Sequence Seq_ShipLabels_ProcessBatch_HA restart with 10000

Go