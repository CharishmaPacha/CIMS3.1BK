/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/09  VS      Initial revision (HA-3084)
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

declare @vBusinessUnit TBusinessUnit = 'HA';

/*----------------------------------------------------------------------------*/
/* List the sequences to be created */

/*                               SeqName                        StartValue      MaxValue        Cycle */
insert into @ttSequences select 'Seq_Imports_ImportBatch',      1,              999999999,      'Cycle'

declare @CreateSQL TNVarchar = '';
declare @DropSQL TNVarchar = '';

/*----------------------------------------------------------------------------*/
/* Build create SQL */
select @CreateSQL += 'Create Sequence ' + S.SeqName + '_' + @vBusinessUnit + ' as bigint ' +
               ' Start with ' + S.StartValue +
               ' MinValue  ' + S.StartValue +
               coalesce(' MaxValue ' + S.MaxValue, '') +
               coalesce (' ' + S.Cycle, '') + ';'
from @ttSequences S;

/*----------------------------------------------------------------------------*/
/* Build drop SQL */
--select @DropSQL += 'Drop Sequence ' + S.SeqName + '_' + @vBusinessUnit + ';'
--from @ttSequences S;

-- select @DropSQL;
-- select @CreateSQL;
--
-- exec sp_executesql @DropSQL;
exec sp_executesql @CreateSQL;

--select name, current_value, last_used_value, maximum_value, minimum_value, * from sys.sequences;

/*----------------------------------------------------------------------------*/
/* Use below to restart sequence at a larger number to avoid conflicts */
--Alter Sequence Seq_Imports_ImportBatch_HA restart with 10000

Go