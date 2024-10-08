/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2022/11/02  VM      Change all controls visible to -1, which needs to be ignored to sync up in redgate comparison (CIMSV3-2384)
  2020/07/28  VM      Initial revision for V2 clients to upgrade with V3 (CIMSV3-1044)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Controls settings for generation of unique DeviceIds for DeviceType PC */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Devices_PC';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Device SeqNo',                               '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Length Of Sequence Number',                       '10',                    'I',       0
union select 'Format',                     'Format of PC Device Ids',                         'PC<SeqNo>',             'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
/*----------------------------------------------------------------------------*/
/* Controls settings for generation of unique DeviceIds for DeviceType RF */
/*----------------------------------------------------------------------------*/
declare @Controls TControlsTable, @ControlCategory TCategory = 'Devices_RF';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'NextSeqNo',                  'Next Device SeqNo',                               '1',                     'I',       -1
union select 'SeqNoMaxLength',             'Length Of Sequence Number',                       '10',                    'I',       0
union select 'Format',                     'Format of RF Device Ids',                         'RF<SeqNo>',             'S',       0

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */;

Go
