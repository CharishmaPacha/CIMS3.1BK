/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2010/11/16  AR      Fixed view name (referenced as vwEmailControls from
                        pr_Email_ConfigureSiteEmail.
  2010/10/26  PK      Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwEmailControls') is null
  exec('Create View dbo.vwEmailControls as select * from Controls')
Go

Alter view  vwEmailControls
  (Enabled,
   AccountName,
   ProfileName,
   MailServer,
   FromAddress,
   FromUserName,
   UserName,
   Password,
   EnableSSL,
   Port)
As
select
  '1',
  'FFIRFCL',
  'FFIRFCL',
  '192.168.100.103',
  'pavan@foxfireindia.com',
  'FFI RFCL',
  'pavan',
  'p@v@n',
  1,
  25;

Go

/* Configure mail system for this site */
exec pr_Email_ConfigureSiteEmail;

Go
