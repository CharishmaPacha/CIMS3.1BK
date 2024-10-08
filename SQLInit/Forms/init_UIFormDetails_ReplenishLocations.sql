/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/14  VS      Intial revision (HA-372)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;
/*------------------------------------------------------------------------------*/
/* Create ReplenishOrders Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ReplenishOrders_Generate';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,    IsRequired, DefaultValue,       SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'Priority',              'IntegerMin1',           'Set Priority',  1,          1,                  1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

Go
