/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/17  OK      pr_Loads_AutoBuild: Changes to get the orders to load from Load Warehouse only (BK-498)
  2021/06/01  RKC     pr_Loads_AutoBuild: Made changes to return if no records exist in temp table (OB2-1830)
  2021/05/16  TK      pr_Loads_AutoBuild: Changes to get ship from of Loads (HA-2788)
  2021/01/18  RT      pr_Loads_AutoBuild: Included #ResultMessages (BK-56)
                      pr_Loads_AutoBuild, pr_Load_UI_AddOrders: Pass the Operation parm to pr_Load_AddOrders
              AY      renamed pr_Load_AutoAddOrderstoLoad to pr_Loads_AutoBuild and code cleanup (HA-1060)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_AutoBuild') is not null
  drop Procedure pr_Loads_AutoBuild;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_AutoBuildLoads: Procedure that runs in a job that selects Loads
   and Orders and adds the Orders to the respective Loads. Operation can be used
   to narrow down to adding orders for different criteria at different times.
   LoadNumber can be specified to only add orders to the specific Load.
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_AutoBuild
  (@Operation       TOperation  = 'Loads_AutoBuild',
   @LoadNumber      TLoadNumber = null,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vRecordId         TRecordId,
          @xmlRulesData      TXML,
          /* Load */
          @vLoadId           TRecordId,
          @vLoadNumber       TLoadNumber,
          @vLoadType         TTypeCode,
          @vWarehouse        TWarehouse,
          /* Ship via */
          @vShipVia          TShipVia,
          @vCarrier          TCarrier,

          @vGenerateLoads    TControlValue;

  declare @ttOrders          TEntityKeysTable;
  declare @ttResultMessages  TResultMessagesTable;
  declare @ttAutoBuildLoads table (RecordId   TRecordId identity (1,1),
                                   LoadId     TRecordId,
                                   LoadNumber TLoadNumber,
                                   LoadType   TTypeCode,
                                   ShipFrom   TShipFrom,
                                   ShipVia    TShipVia,
                                   Warehouse  TWarehouse);

  declare @ttAutoBuildLoadAddOrders table (RecordId    TRecordId identity (1,1),
                                           OrderId     TRecordId,
                                           PickTicket  TPickTicket,
                                           OrderType   TTypeCode,
                                           SortOrder   TSortOrder);

begin /* pr_Loads_AutoBuild */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0

  if object_id('tempdb..#AutoBuildLoads') is null
    select * into #AutoBuildLoads from @ttAutoBuildLoads;

  if object_id('tempdb..#AutoBuildLoadAddOrders') is null
    select * into #AutoBuildLoadAddOrders from @ttAutoBuildLoadAddOrders;

  select * into #ResultMessages from @ttResultMessages;

  /* Get Controls */
  select @vGenerateLoads = dbo.fn_Controls_GetAsString('Loads', 'AutoOrderstoLoad', 'N' /* No */, @BusinessUnit, @UserId);

  /* Build the rules data */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                           dbo.fn_XMLNode('UserId',        @UserId) +
                           dbo.fn_XMLNode('Operation',     @Operation) +
                           dbo.fn_XMLNode('LoadNumber',    @vLoadNumber));

  /* Get all the Qualified Loads */
  exec pr_RuleSets_ExecuteAllRules 'Loads_AutoBuild_GetLoadsToBuild', @xmlRulesData, @BusinessUnit;

  select @vRecordId = 0;

  /* Loop thru each of the Loads and add Orders to them */
  while exists (select * from #AutoBuildLoads where RecordId > @vRecordId)
    begin
       select top 1 @vRecordId   =  AL.RecordId,
                    @vLoadId     =  AL.LoadId,
                    @vLoadNumber =  AL.LoadNumber,
                    @vLoadType   =  AL.LoadType,
                    @vShipVia    =  AL.ShipVia,
                    @vWarehouse  =  AL.Warehouse
      from #AutoBuildLoads AL
      where (RecordId > @vRecordId)
      order by RecordId;

     /* Build the rules data to fetch all the Orders that can be on the Load */
     select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                              dbo.fn_XMLNode('LoadId',        @vLoadId) +
                              dbo.fn_XMLNode('LoadNumber',    @vLoadNumber) +
                              dbo.fn_XMLNode('LoadType',      @vLoadType) +
                              dbo.fn_XMLNode('ShipVia',       @vShipVia) +
                              dbo.fn_XMLNode('Warehouse',     @vWarehouse) +
                              dbo.fn_XMLNode('Operation',     @Operation) +
                              dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit));

      delete from #AutoBuildLoadAddOrders;

      /* Get the all the Orders that can be added to this specific Load */
      exec pr_RuleSets_ExecuteAllRules 'Loads_AutoBuild_GetOrdersToAdd', @xmlRulesData, @BusinessUnit;

      /* Get orders into temp table to be added to the current Load */
      delete from @ttOrders;
      insert into @ttOrders(EntityId, EntityKey)
        select OrderId, PickTicket
        from #AutoBuildLoadAddOrders

      /* If records exists in temp table then only add the Orders to the Respective Load */
      if exists (select * from @ttOrders)
        exec pr_Load_AddOrders @vLoadNumber, @ttOrders, @BusinessUnit, @UserId, 'Y' /* Load Recount */, @Operation;
    end

end /* pr_Loads_AutoBuild */

Go
