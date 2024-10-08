/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this Table exists. Taken here for additional fields.
  So, if there are any common fields to be added, MUST consider adding the same in Base version as well.
  *****************************************************************************

  2021/03/03  AY      Printers: Add Printer Make/Model/SerialNo (HA Mock GoLive)
  2020/08/26  RV      Printers: Added ProcessGroup and PrinterStatus (HA-1324)
  2020/06/04  AY      Printers: Added PrinterZPLCommands & LabelZPLCommands
  2020/04/20  NB      Added Printers table(CIMSV3-221)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.Printers') is not null
/*------------------------------------------------------------------------------
  WMS fields
------------------------------------------------------------------------------*/
alter table Printers add
  Ownership                     TOwnership,
  Warehouse                     TWarehouse;

Go