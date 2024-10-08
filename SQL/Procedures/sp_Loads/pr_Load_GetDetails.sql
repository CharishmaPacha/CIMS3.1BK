/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/23  AY      pr_Load_GetDetails, pr_Load_ValidateToShip: Performance optimization (HA-3110)
  2020/11/06  RKC     pr_Load_GetDetails: Made changes to return the volume & weight with proper format (HA-1526)
  2020/10/19  SJ      pr_Load_GetDetails: Made changes to return NumLPNs and NumUnits properly (HA-1521)
  2020/06/09  RV      pr_Load_GetDetails: Initial version (HA-839)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_GetDetails') is not null
  drop Procedure pr_Load_GetDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_GetDetails:
  Procedure returns the load details for the given input load, orders to load, loaded orders, etc.,
  all the inputs for load, orders are in xml format
  The procedure summarizes the totals for the load, with the selected orders to load and without the selected
  loaded orders. In other words, the procedure calculates the load details if the orders to load were added to the load
  and if the loaded orders were removed from the load
------------------------------------------------------------------------------*/
Create Procedure pr_Load_GetDetails
  (@LoadInput            TXML,
   @OrdersToShipInput    TXML = null,
   @LoadOrderInput       TXML = null,
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId)
as
  declare @vxmlLoadInput           xml,
          @vxmlOrdersToShipInput   xml,
          @vxmlLoadOrderInput      xml,
          @vLoadEntity             TEntity,
          @vOrdersToShipEntity     TEntity,
          @vCultureName            TName;

  declare @ttLoadSelectedEntities           TEntityValuesTable;
  declare @ttOrdersToShipSelectedEntities   TEntityValuesTable;
  declare @ttOrdersToRemoveSelectedEntities TEntityValuesTable;

  declare @ttLoadDetails Table
          (LoadNumber   TLoadNumber,
           LoadTypeDesc TDescription,
           NumOrders    TCount,
           NumPallets   TCount,
           NumLPNs      TCount,
           NumCases     TCount,
           NumUnits     TCount,
           Volume       Decimal(18,2),
           Weight       Decimal(18,2));

  declare @ttOrdersToShipDetails Table
          (NumOrders    TCount,
           NumPallets   TCount,
           NumLPNs      TCount,
           NumCases     TCount,
           NumUnits     TCount,
           Volume       Decimal(18,2),
           Weight       Decimal(18,2));
begin /* pr_Load_GetDetails */
  /* Process Selected Load Details */
  select @vxmlLoadInput = cast(@LoadInput as Xml);

  select @vLoadEntity = Record.Col.value('Entity[1]', 'TEntity')
  from @vxmlLoadInput.nodes('//Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlLoadInput = null ));

  /* Get selected culture from selected User */
  select @vCultureName = CultureName
  from Users
  where UserName = @UserId;

  /* Create a Temp Table with the same structures as ttSelectedEntities table var */
  select * into #ttSelectedEntities from @ttLoadSelectedEntities;

  /* This procedure inserts the records into #ttSelectedEntities temp table */
  exec pr_Entities_GetSelectedEntities @vLoadEntity, @vxmlLoadInput, @BusinessUnit, @UserId;

  /* If LoadId is not given, then populate it */
  update SE
  set SE.EntityId = LD.LoadId
  from #ttSelectedEntities SE join Loads LD on (SE.EntityKey = LD.LoadNumber) and (LD.BusinessUnit = @BusinessUnit)
  where (SE.EntityId is null) and (SE.EntityKey is not null);

  /* insert the selected entities records into table var from temp table to pass into action procedures */
  insert into @ttLoadSelectedEntities
    select * from #ttSelectedEntities;

   /* Capture Load details for the selected load */
  insert into @ttLoadDetails
    select LoadNumber, LoadTypeDescription, coalesce(NumOrders, 0), coalesce(NumPallets, 0), coalesce(NumLPNs, 0),
           0 NumCases, coalesce(NumUnits, 0), coalesce(Volume, 0.0), coalesce(Weight, 0.0)
    from vwLoads VL
    join @ttLoadSelectedEntities WS on (WS.EntityId = VL.LoadId);

  /* Procedure Orders to Load Input */
  if (@OrdersToShipInput is not null)
    begin
      select @vxmlOrdersToShipInput = cast(@OrdersToShipInput as Xml);

      select @vOrdersToShipEntity = Record.Col.value('Entity[1]', 'TEntity')
      from @vxmlOrdersToShipInput.nodes('//Root') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @vxmlOrdersToShipInput = null ));

      /* Temp table is already created. clear the table for the new list to be inserted */
      delete from #ttSelectedEntities;

      /* This procedure inserts the records into #ttSelectedEntities temp table */
      exec pr_Entities_GetSelectedEntities @vOrdersToShipEntity, @vxmlOrdersToShipInput, @BusinessUnit, @UserId;

      /* If OrderId is not given, then populate it */
      update SE
      set SE.EntityId = OH.OrderId
      from #ttSelectedEntities SE join OrderHeaders OH on (SE.EntityKey = OH.PickTicket) and (OH.BusinessUnit = @BusinessUnit)
      where (SE.EntityId is null) and (SE.EntityKey is not null);

      /* insert the selected entities records into table var from temp table to pass into action procedures */
      insert into @ttOrdersToShipSelectedEntities
        select * from #ttSelectedEntities;

      /* Capture the Totals for the Orders to Load */
      insert into @ttOrdersToShipDetails
        select count(OH.OrderId) NumOrders, 0 NumPallets, sum(OH.NumLPNs) NumLPNs, sum(OH.NumCases) NumCases, sum(OH.NumUnits) NumUnits, sum(coalesce(OH.TotalVolume, 0)) Volume, sum(coalesce(OH.TotalWeight, 0)) Weight
        from OrderHeaders OH
          join @ttOrdersToShipSelectedEntities UOS on (UOS.EntityId = OH.OrderId);

      /* Update the totals in Load Details to reflect the totals from Order to Load */
      update LD
      set LD.NumOrders  = LD.NumOrders  + coalesce(ttOSD.NumOrders,  0),
          LD.NumPallets = LD.NumPallets + coalesce(ttOSD.NumPallets, 0),
          LD.NumLPNs    = LD.NumLPNs    + coalesce(ttOSD.NumLPNs,    0),
          LD.NumUnits   = LD.NumUnits   + coalesce(ttOSD.NumUnits,   0),
          LD.Volume     = LD.Volume     + coalesce(ttOSD.Volume,     0),
          LD.Weight     = LD.Weight     + coalesce(ttOSD.Weight,     0)
      from @ttLoadDetails LD, @ttOrdersToShipDetails ttOSD;
    end

  delete from @ttOrdersToShipDetails;

  /* Load orders have the orders to remove from load, So need to deduct these quantities in load details */
  if (@LoadOrderInput is not null)
    begin
      select @vxmlLoadOrderInput = cast(@LoadOrderInput as Xml);

      /* Temp table is already created. clear the table for the new list to be inserted */
      delete from #ttSelectedEntities;

      /* This procedure inserts the records into #ttSelectedEntities temp table */
      exec pr_Entities_GetSelectedEntities 'Order', @vxmlLoadOrderInput, @BusinessUnit, @UserId;

      /* If OrderId is not given, then populate it */
      update SE
      set SE.EntityId = OH.OrderId
      from #ttSelectedEntities SE join OrderHeaders OH on (SE.EntityKey = OH.PickTicket) and (OH.BusinessUnit = @BusinessUnit)
      where (SE.EntityId is null) and (SE.EntityKey is not null);

      /* insert the selected entities records into table var from temp table to pass into action procedures */
      insert into @ttOrdersToRemoveSelectedEntities
        select * from #ttSelectedEntities;

      /* Capture the Totals for the Orders to Load */
      insert into @ttOrdersToShipDetails
        select count(OH.OrderId) NumOrders, 0 NumPallets, sum(OH.NumLPNs) NumLPNs,
               0 NumCases, sum(OH.NumUnits) NumUnits, sum(coalesce(OH.TotalVolume, 0)) Volume, sum(coalesce(OH.TotalWeight, 0)) Weight
        from OrderHeaders OH
        join @ttOrdersToRemoveSelectedEntities ttORFL on (ttORFL.EntityId = OH.OrderId);

      /* Update the totals in Load Details to reflect the totals from Order to Load */
      update LD
      set LD.NumOrders  = LD.NumOrders  - coalesce(ttOTR.NumOrders,  0),
          LD.NumPallets = LD.NumPallets - coalesce(ttOTR.NumPallets, 0),
          LD.NumLPNs    = LD.NumLPNs    - coalesce(ttOTR.NumLPNs,    0),
          LD.NumUnits   = LD.NumUnits   - coalesce(ttOTR.NumUnits,   0),
          LD.Volume     = LD.Volume     - coalesce(ttOTR.Volume,   0),
          LD.Weight     = LD.Weight     - coalesce(ttOTR.Weight,   0)
      from @ttLoadDetails LD, @ttOrdersToShipDetails ttOTR;
    end

  /* Return the Load Details with proper formats based on the selected user culture */
  select LoadNumber, LoadTypeDesc, format(NumOrders, 'N0', @vCultureName) NumOrders, format(NumLPNs, 'N0', @vCultureName) NumLPNs, format(NumPallets, 'N0', @vCultureName) NumPallets,
         format(NumUnits, 'N0', @vCultureName) NumUnits, format(Weight, 'n2', @vCultureName) Weight, format(Volume, 'n2', @vCultureName) Volume
  from @ttLoadDetails;
end /*  pr_Load_GetDetails */

Go
