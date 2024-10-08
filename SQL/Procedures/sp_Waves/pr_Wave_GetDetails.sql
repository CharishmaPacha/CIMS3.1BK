/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/13  SK      pr_Wave_GetDetails: Ignore unwaved orders if already assocaited with wave and a minor fix (HA-1911)
  2020/05/19  MS/HYP  pr_Wave_GetDetails: Changed the order for dataset (HA-509)
  2018/07/04  NB      Added pr_Wave_GetDetails(CIMSV3-153)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_GetDetails') is not null
  drop Procedure pr_Wave_GetDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_GetDetails:
  Procedure returns the wave details for the given input wave, unwaved order, waved orders, etc.,
  all the inputs for wave, orders are in xml format
  The procedure summarizes the totals for the wave, with the selected unwaved orders and without the selected
  waved orders. In other words, the procedure calculates the Wave details if the unwaved orders were added to the wave
  and if the waved orders were removed from the wave
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_GetDetails
  (@WaveInput             TXML,
   @UnwavedOrdersInput    TXML = null,
   @WavedOrderInput       TXML = null,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId)
as
  declare @vxmlWaveInput            xml,
          @vxmlUnwavedOrdersInput   xml,
          @vWaveEntity              TEntity,
          @vUnwavedOrdersEntity     TEntity;

  declare @ttWaveSelectedEntities           TEntityValuesTable;
  declare @ttUnwavedOrdersSelectedEntities  TEntityValuesTable;

  declare @ttWaveDetails Table
          (WaveNo       TWaveNo,
           WaveTypeDesc TDescription,
           NumOrders    TCount,
           NumSKUs      TCount,
           NumLines     TCount,
           NumUnits     TCount);

  declare @ttUnwavedOrdersDetails Table
          (NumOrders    TCount,
           NumSKUs      TCount,
           NumLines     TCount,
           NumUnits     TCount);
begin /* pr_Wave_GetDetails */
  /* Process Selected Wave Details */
  select @vxmlWaveInput = cast(@WaveInput as Xml);

  select @vWaveEntity = Record.Col.value('Entity[1]', 'TEntity')
  from @vxmlWaveInput.nodes('//Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlWaveInput = null ));

  /* Create a Temp Table with the same Structures as ttSelectedEntities table var */
  select * into #ttSelectedEntities from @ttWaveSelectedEntities;

  /* This procedure inserts the records into #ttSelectedEntities temp table */
  exec pr_Entities_GetSelectedEntities @vWaveEntity, @vxmlWaveInput, @BusinessUnit, @UserId;

  /* insert the selected entities records into table var from temp table to pass into action procedures */
  insert into @ttWaveSelectedEntities select * from #ttSelectedEntities;

   /* Capture Wave details for the selected wave */
  insert into @ttWaveDetails (WaveNo, WaveTypeDesc, NumOrders, NumSKUs, NumLines, NumUnits)
    select BatchNo, BatchTypeDesc, coalesce(NumOrders, 0), coalesce(NumSKUs, 0), coalesce(NumLines, 0), coalesce(NumUnits, 0)
    from vwPickBatches VPB
    join @ttWaveSelectedEntities WS on ((WS.EntityId = VPB.RecordId) or (WS.EntityKey = VPB.BatchNo));

  /* Procedure Unwaved Orders Input */
  if (@UnwavedOrdersInput is not null)
    begin
      select @vxmlUnwavedOrdersInput = cast(@UnwavedOrdersInput as Xml);

      select @vUnwavedOrdersEntity = Record.Col.value('Entity[1]', 'TEntity')
      from @vxmlUnwavedOrdersInput.nodes('//Root') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @vxmlUnwavedOrdersInput = null ));

      /* Temp table is already created. clear the table for the new list to be inserted */
      delete from #ttSelectedEntities;

      /* This procedure inserts the records into #ttSelectedEntities temp table */
      exec pr_Entities_GetSelectedEntities @vUnwavedOrdersEntity, @vxmlUnwavedOrdersInput, @BusinessUnit, @UserId;

      /* insert the selected entities records into table var from temp table to pass into action procedures */
      insert into @ttUnwavedOrdersSelectedEntities select * from #ttSelectedEntities;

      /* Capture the Totals for the Unwaved Orders if it is not associated to selected wave already */
      insert into @ttUnwavedOrdersDetails
        select count(OH.OrderId) NumOrders, sum(OH.NumSKUs) NumSKUs, sum(OH.NumLines) NumLines, sum(OH.NumUnits) NumUnits
        from OrderHeaders OH
        join @ttUnwavedOrdersSelectedEntities UOS on ((UOS.EntityKey = OH.PickTicket) or (UOS.EntityId = OH.OrderId))
        left join @ttWaveDetails TWD on OH.PickBatchNo = TWD.WaveNo
        where (OH.BusinessUnit = @BusinessUnit) and
              (TWD.WaveNo is null);

      /* Update the totals in Wave Details to reflect the totals from Unwaved orders */
      update WD
      set WD.NumOrders = WD.NumOrders + coalesce(UOD.NumOrders, 0),
          WD.NumLines  = WD.NumLines  + coalesce(UOD.NumLines,  0),
          WD.NumSKUs   = WD.NumSKUs   + coalesce(UOD.NumSKUs,   0),
          WD.NumUnits  = WD.NumUnits  + coalesce(UOD.NumUnits,  0)
      from @ttWaveDetails WD, @ttUnwavedOrdersDetails UOD;
    end

  /* TODO TODO TODO */
  /* Process Waved Orders Inouts */
  /* Capture the Totals for the Waves Orders*/
  /* Update the totals in Wave Details to reflect the totals from Waved orders - Deduct the totals from Wave Details */

  /* Return the Wave Details */
  select * from @ttWaveDetails;
end /*  pr_Wave_GetDetails */

Go
