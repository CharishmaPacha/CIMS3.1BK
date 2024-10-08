/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/09  SK      Initial Revision (HA-2972)
------------------------------------------------------------------------------*/

Go

declare @FormName TName;

/*------------------------------------------------------------------------------*/
/* select Locations Parameter Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Analytics_ProductivitySummary';  -- This should be like ParentMenuId_MenuId, since it is input Param Dataset

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
             (FieldName,               ControlName,           FieldCaption,                IsRequired,    DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'Operation',             'OperationType_DD',     'Operation Type',            1,             null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'SummarizeBy',           'ProdSumBy_DD',         'Summarize By',              0,             'UserDate',   2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'StartDateTime',         'DatePast',             'Date From',                 0,             null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'EndDateTime',           'DateAny',              'Date To',                   0,             null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'WaveType',              'WaveType_DD',          'Wave Type',                 0,             null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Warehouse',             'Warehouse_DBDD',       'Warehouse',                 0,             null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

Go