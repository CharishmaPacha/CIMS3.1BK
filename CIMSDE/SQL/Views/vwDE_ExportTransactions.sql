/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/17  VS      vwDE_ExportTransactions: Initial Version (HA-3080)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwDE_ExportTransactions') is not null
  drop View dbo.vwDE_ExportTransactions;
exec('Create View dbo.vwDE_ExportTransactions as select * from ExportTransactions with (Nolock)');

Go
