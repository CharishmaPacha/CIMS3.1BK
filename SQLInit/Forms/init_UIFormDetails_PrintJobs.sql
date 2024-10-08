/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/22  RT      Initial revision
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* PrintJobs_Release Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'PrintJobs_Release';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'LabelPrinterName',      'LabelPrinter_DD',       null,                    1,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'LabelPrinterName2',     'LabelPrinter_DD',       null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ReportPrinterName',     'ReportPrinter_DD',      null,                    1,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

Go
