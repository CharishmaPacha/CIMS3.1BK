/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/26  MS      pr_Loads_AutoShip: Bug fix not to update LoadStatus, as we are already updating in caller (HA-2457)
                      pr_Loads_AutoShip: Changes to autogenerate BOLNum (HA-1206)
  2020/07/27  OK      Renamed pr_Load_AutoShip to pr_Loads_AutoShip and enhanced to use the existing V3 action proc (HA-1128)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_AutoShip') is not null
  drop Procedure pr_Loads_AutoShip;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_AutoShip: Ships all the open Loads
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_AutoShip
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessage,
          @vErrorMsg         TMessage,

          @vRecordId         TRecordId,
          @vLoadId           TRecordId,
          @vLoadNumber       TLoadNumber,
          @xmlRulesData      TXML;

  declare @ttAutoShipLoads table (RecordId        TRecordId identity (1,1),
                                  LoadId          TRecordId,
                                  LoadNumber      TLoadNumber,
                                  LoadType        TTypeCode,
                                  ShipVia         TShipVia,
                                  CreatedDate     TDateTime,
                                  CreatedHour     TInteger,
                                  CurrentHour     TInteger,
                                  ProcessFlag     TFlags,
                                  BolNumGenerated TFlags);

  declare @ttSelectedLoads  TEntityValuesTable,
          @ttResultMessages TResultMessagesTable;
begin /* pr_Load_AutoShip */
  SET NOCOUNT ON;

  select @vRecordId    = 0,
         @vMessageName = null,
         @vMessage     = null;

  select * into #LoadsToAutoShip from @ttAutoShipLoads;
  select * into #ttSelectedEntities from @ttSelectedLoads;
  select * into #ResultMessages from @ttResultMessages;

  /* Build the rules data */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',    'AutoShipLoads') +
                           dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit));

  /* Get all the qualified Loads to Ship */
  exec pr_RuleSets_ExecuteAllRules 'Load_AutoShipLoads', @xmlRulesData, @BusinessUnit;

  insert into #ttSelectedEntities (EntityId, EntityKey, RecordId)
    select LoadId, LoadNumber, LoadId
    from #LoadsToAutoShip
    where ProcessFlag = 'Y';

  /* Ship the Loads */
  exec pr_Loads_Action_MarkAsShipped null /* @xmlData */, @BusinessUnit, @UserId;

  /* If any exceptions are raised in sub procedures, then raise error. So that job will fail and we will get alerts. */
  if (exists(select * from #ResultMessages where MessageType = 'E'))
    raiserror('LoadShip_ErrorProcessing', 16, 1);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_AutoShip */

Go
