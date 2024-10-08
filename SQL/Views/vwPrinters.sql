/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/07  PKK     Added PrintStatus (HA-2874)
  2021/03/02  SJ      Added ProcessGroup (HA-2019)
  2020/05/23  AY      Added PrinterNameUnified (CIMSV3-941)
  2020/05/21  YJ      Added changes to use Printers instead of Devices table (CIMSV3-915)
  2020/05/18  AY      Setup fields consistent with future naming convention until we change to use Printers table
  2020/04/24  RT/MS   Included RecordId (HA-99)
                      Convert Xml to varchar
  2020/04/08  OK      Added StatusDescription (HA-46)
  2018/05/01  NB      Added BusinessUnit(CIMSV3-152)
  2012/02/02  AA      Initial revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPrinters') is not null
  drop View dbo.vwPrinters;
Go

Create View dbo.vwPrinters (
    PrinterId,
    DeviceId,    -- deprecated
    DeviceName,  -- deprecated
    PrinterName,
    PrinterDescription,
    PrinterType,

    PrinterConfigName,
    PrinterConfigIP,
    PrinterPort,
    PrinterNameUnified, -- with IP+Port if IP Printer, else the config name
    PrintProtocol,
    PrinterUsability,
    ProcessGroup,
    PrintStatus,

    PrintDelay,
    BufferSize,
    PrintSpeed,
    DPI,
    XOffset,
    YOffset,
    StockSizes,

    Status,
    StatusDescription,
    SortSeq,

    Ownership,
    Warehouse,

    LabelZPLCommands,
    PrinterZPLCommands,

    Printer_UDF1,
    Printer_UDF2,
    Printer_UDF3,
    Printer_UDF4,
    Printer_UDF5,

    BusinessUnit,
    CreatedDate,
    ModifiedDate,
    CreatedBy,
    ModifiedBy
    ) As
select
    P.PrinterId,
    P.PrinterName,        -- DeviceId, deprecated
    P.PrinterDescription, -- DeviceName, deprecated
    P.PrinterName,
    P.PrinterDescription,
    P.PrinterType,

    P.PrinterConfigName,
    P.PrinterConfigIP,
    P.PrinterPort,
    case when PrintProtocol = 'IP' then P.PrinterConfigIP + ':' + P.PrinterPort
         else P.PrinterConfigName
    end, /* PrinterNameUnified */

    P.PrintProtocol,
    P.PrinterUsability,
    P.ProcessGroup,
    P.PrintStatus,

    P.PrintDelay,
    P.BufferSize,
    P.PrintSpeed,
    P.DPI,
    P.XOffset,
    P.YOffset,
    P.StockSizes,

    P.Status,
    ST.StatusDescription,
    P.SortSeq,

    P.Ownership,
    P.Warehouse,

    P.LabelZPLCommands,
    P.PrinterZPLCommands,

    P.Printer_UDF1,
    P.Printer_UDF2,
    P.Printer_UDF3,
    P.Printer_UDF4,
    P.Printer_UDF5,

    P.BusinessUnit,
    P.CreatedDate,
    P.ModifiedDate,
    P.CreatedBy,
    P.ModifiedBy
from
  Printers P
    left outer join Statuses ST on (ST.StatusCode    = P.Status       ) and
                                   (ST.Entity        = 'Status'       ) and
                                   (ST.BusinessUnit  = P.BusinessUnit );

Go
