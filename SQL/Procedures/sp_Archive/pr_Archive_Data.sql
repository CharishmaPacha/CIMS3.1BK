/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/18  PHK     pr_Archive_Data: Migrated the latest changes from S2G (HA-1377)
  2019/06/17  AY      pr_Archive_Data: Generic procedure to archive any dataset using rules
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Archive_Data') is not null
  drop Procedure pr_Archive_Data;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_Data: Use Rules to archive all the data sets setup in rules. Pass
   a particular entity name in DataSet if you would like to archive that only
   or else leave default and all of them will be archived.
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_Data
  (@DataSet       TName = 'All',
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vMessage      TDescription;

  declare @xmlRulesData  TXML;

begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Build the rules data for archiving */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('DataSet',           @DataSet)      +
                           dbo.fn_XMLNode('UserId',            @UserId)       +
                           dbo.fn_XMLNode('BusinessUnit',      @BusinessUnit));

  /* Execute the archiving updates - for all tables or the given table */
  exec pr_RuleSets_ExecuteAllRules 'ArchiveData', @xmlRulesData, @BusinessUnit;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_Data */

Go
