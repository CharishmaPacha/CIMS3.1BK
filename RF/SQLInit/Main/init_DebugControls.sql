/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/07/21  NB      Initial revision
------------------------------------------------------------------------------*/
/*
  Debug Options : L - Log activity
                  D - Display log
                  M - Marker to isolate the performace issues

  Enabled       : Y - Yes
                  N - No
*/

Go

declare @DebugControls TDebugControlsTable;

/*----------------------------------------------------------------------------*/
/* AMF */
/*----------------------------------------------------------------------------*/
insert into @DebugControls (ProcName,                             Operation,             DebugOptions,      Enabled,       Module)
                    select 'pr_AMF_ExecuteAction',                '',                    'L',               'Y',          'AMF'

/* Enable Logging for all the procedures in Test, Staging and Dev environments */
if ((db_name() like '%Staging%') or (db_name() like '%Test%') or (db_name() like '%Dev%'))
  update @DebugControls set Enabled = 'Y'

exec pr_Setup_DebugControls @DebugControls, 'IU' /* Insert/Update */;

Go
