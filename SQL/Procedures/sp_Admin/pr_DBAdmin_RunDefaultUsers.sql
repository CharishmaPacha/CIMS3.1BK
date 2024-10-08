/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/26  SK      pr_DBAdmin_RunDefaultUsers: Created different users for different apps to use
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DBAdmin_RunDefaultUsers') is not null
  drop Procedure pr_DBAdmin_RunDefaultUsers;
Go
/*------------------------------------------------------------------------------
  Proc pr_DBAdmin_RunDefaultUsers:
------------------------------------------------------------------------------*/
Create Procedure pr_DBAdmin_RunDefaultUsers
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Should have write/read access to all CIMSDE procs and objects */
  exec pr_DBAdmin_AddUser 'cims_HostInt', 'cimsapp'
  exec pr_DBAdmin_AddUser 'cims_UI',      'cimsapp'  -- for UI app
  exec pr_DBAdmin_AddUser 'cims_DAB',     'cimsapp'  -- for Dashboards
  exec pr_DBAdmin_AddUser 'cims_RF',      'cimsapp'  -- for RF app
  exec pr_DBAdmin_AddUser 'cims_DP',      'cimsapp'  -- for Document processor
  exec pr_DBAdmin_AddUser 'cims_LG',      'cimsapp'  -- for Label Generator
  exec pr_DBAdmin_AddUser 'cims_DE',      'cimsapp'  -- for Data Exchange app
  exec pr_DBAdmin_AddUser 'cims_API',     'cimsapp'  -- for CIMS API
  exec pr_DBAdmin_AddUser 'cims_WS',      'cimsapp'  -- for Webservices

  /* Read only access to CIMSDE */
  exec pr_DBAdmin_AddUser 'cims_ROUser', 'cimsro'
  exec pr_DBAdmin_AddUser 'cims_GR',     'cimsro' -- for Generate Resources tool

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_DBAdmin_RunDefaultUsers */

Go
