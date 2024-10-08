/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/17  AY      Added ZebraAY
  2020/02/13  MS      Given Name instead of IP for Zebra printer (JL-39)
  2019/11/04  RV      Added new Zebra printer (FB-1444)
  2016/08/30  VM      Minor changes to FFI environment printers
  2016/02/06  AY      Changed Samsung to be a generic printer
  2015/05/16  AY      Setup printers for FFI environment
  2012/11/21  SP      Added  SortSeq for devices.
  2012/10/05  AA      Clean up entries and update configuration to local environment
  2012/08/29  AA      Printers configured to local printer
  2012/07/12  AA      Configured PANDA printer to SATO
  2012/07/09  AA      Added PANDA device to use in generate printer data stream
                        with test on site generated printToFileLicense key
  2012/02/09  AA      Initial revision.
------------------------------------------------------------------------------*/

delete from Devices where DeviceType='Printer';

Go

/*------------------------------------------------------------------------------*/
/* Devices */
/*------------------------------------------------------------------------------*/

insert into Devices
                (DeviceId,       DeviceName,               Make,                DeviceType, Status,       SortSeq,
                 Configuration, BusinessUnit)
          select 'SAMSUNG',      'Samsung Printer @ FFI',  'Generic',           'Printer',  'A',          2,
                 '<configuration><port>FFIAllInOne01</port><stocksize>4x6</stocksize></configuration>',   BusinessUnit from vwBusinessUnits
union all select 'PDF',          'Print to PDF',           'Generic',           'Printer',  'A',          3,
                 '<configuration><port>PDFCreator</port><stocksize>4x6</stocksize><printToFileLicense /></configuration>',
                                                                                                          BusinessUnit from vwBusinessUnits
union all select 'Zebra',          'Zebra @FFI',            'Zebra',             'Printer',  'A',         4,
                 '<configuration><port>ZDesigner GC420t</port><stocksize>4x6</stocksize><printToFileLicense /></configuration>',
                                                                                                          BusinessUnit from vwBusinessUnits
union all select 'SATOFFI',      'SATO @ FFI',             'SATO',              'Printer',  'A',          1,
                 '<configuration><port>192.168.100.100\SATO CG408TT</port><stocksize>4x6</stocksize><printToFileLicense /></configuration>',
                                                                                                          BusinessUnit from vwBusinessUnits
union all select 'ZebraAY',      'Zebra @ AY',             'Zebra',              'Printer',  'A',          9,
                 '<configuration><port>75.136.102.194:9100</port><stocksize>4x6</stocksize><printToFileLicense /></configuration>',
                                                                                                          BusinessUnit from vwBusinessUnits
union all select 'EpsonAY',      'Epson @ AY',             'Generic',            'Printer',  'A',          8,
                 '<configuration><port>EPSON WF-3270 Series</port><stocksize>4x6</stocksize><printToFileLicense /></configuration>',
                                                                                                          BusinessUnit from vwBusinessUnits

Go
