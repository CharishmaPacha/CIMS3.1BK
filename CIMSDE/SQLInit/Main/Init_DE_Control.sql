/*-----------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2021/03/09  VS      Initial version (HA-3084)
------------------------------------------------------------------------------*/

Go

/******************************************************************************/
/*                                  Imports                                      */
/******************************************************************************/
declare @Controls        TControlsTable, @ControlCategory TCategory = 'ImportBatch',
        @BusinessUnit    TBusinessUnit = 'HA';

insert into @Controls
            (ControlCode,                  Description,                                       ControlValue,            DataType,  Visible)
      select 'RecordsPerBatch',            'Max no of records per batch',                     '1000',                  'I',       1

exec pr_Controls_Setup @ControlCategory, @Controls, 'IU' /* Insert/Update */, @BusinessUnit;

Go
