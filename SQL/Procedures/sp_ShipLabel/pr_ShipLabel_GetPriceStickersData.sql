/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/04/25  TD      Added new procedure pr_ShipLabel_GetPriceStickersData.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetPriceStickersData') is not null
  drop Procedure pr_ShipLabel_GetPriceStickersData;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetPriceStickersData: Returns all the info associated with the
   LPN/Order/Wave

   <root>
     <Entity>
        <EntityType></EntityType>
        <EntityKey></EntityKey>
        <LabelFormat></LabelFormat>
     <Entity>
   </root>

 Assumption-Caller will take care of validations
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetPriceStickersData
  (@EntityXML  TXML)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMessage             TDescription,
          @vxmlData             xml,
          @vEntityType          TEntity,
          @vEntityKey           TEntity,
          @vLPNId               TRecordId,
          @vWaveId              TRecordId,
          @vOrderId             TRecordId,
          @vLabelFormat         TName;

  declare @ttLabelsToPrintProcess table
          (RecordId           Integer Identity(1,1),

           LPN                TLPN,
           OrderId            TRecordId,
           OrderDetailId      TRecordId,
           SKUId              TRecordId,

           QtyToPrint         TQuantity);

  declare @ttEntitiesToProcess table
          (RecordId           Integer Identity(1,1),

           EntityType         TLPN,
           EntityKey          TEntityKey,
           LabelFormat        TDescription);

begin /* pr_ShipLabel_GetPriceStickersData */
  select @vReturnCode   = 0,
         @vMessagename  = null;

  /* Extracting data elements from XML. */
  set @vxmlData = convert(xml, @EntityXML);

  /* read all data into temp table */
  insert into @ttEntitiesToProcess(EntityType, EntityKey, LabelFormat)
    select Record.Col.value('EntityType[1]', 'TEntity'),
           Record.Col.value('EntityKey[1]',  'TEntityKey'),
           Record.Col.value('LabelFormat[1]', 'TEntityKey')
    from @vxmlData.nodes('/root/Entity') as Record(Col);

  if (not exists (select * from @ttEntitiesToProcess))
    goto ExitHandler;

  /* load entites to process if the given input has lPN in it */
  if (exists (select * from @ttEntitiesToProcess where EntityType = 'LPN'))
    begin
      insert into @ttLabelsToPrintProcess (OrderId, OrderDetailId, SKUId,
                                           QtyToPrint)
        select min(OH.OrderId), min(OD.OrderDetailId), LD.SKUId,
               sum(LD.Quantity)
        from @ttEntitiesToProcess TEP
        join LPNs         L  on TEP.EntityKey         = L.LPN
        join LPNDetails   LD on L.LPNId               = LD.LPNId
        join OrderHeaders OH on LD.OrderId            = OH.OrderId  and
                                OH.PriceStickerFormat = TEP.LabelFormat
        join OrderDetails OD on LD.OrderDetailId      = OD.OrderDetailId
        where (TEP.EntityType = 'LPN')
        group by LD.SKUId, OD.RetailUnitPrice, OD.UnitSalePrice;
    end

  /* load entities to process if the given input has PickTicket in it */
  if (exists (select * from @ttEntitiesToProcess where EntityType = 'PickTicket'))
    begin
      insert into @ttLabelsToPrintProcess (OrderId, OrderDetailId,
                                           SKUId, QtyToPrint)
        select OH.OrderId, min(OD.OrderDetailId),
               OD.SKUId, sum(OD.UnitsAuthorizedtoShip)
        from @ttEntitiesToProcess TEP
        join OrderHeaders OH on TEP.EntityKey   = OH.PickTicket and
                                TEP.LabelFormat = OH.PriceStickerFormat
        join OrderDetails OD on OH.OrderId      = OD.OrderId
        where TEP.EntityType = 'PickTicket'
        group by OH.OrderId, OD.SKUId, OD.RetailUnitPrice, OD.UnitSalePrice;
    end

  /* load entitie here if the gi en inout has pickbatch in it */
  if (exists (select * from @ttEntitiesToProcess where EntityType = 'PickBatch'))
    begin
      insert into @ttLabelsToPrintProcess (OrderId, OrderDetailId,
                                           SKUId, QtyToPrint)
        select OH.OrderId, min(OD.OrderDetailId),
               OD.SKUId, sum(OD.UnitsAuthorizedtoShip)
        from @ttEntitiesToProcess TEP
        join OrderHeaders OH on TEP.EntityKey   = OH.PickBatchNo and
                                TEP.LabelFormat = OH.PriceStickerFormat
        join OrderDetails OD on OH.OrderId      = OD.OrderId
        where TEP.EntityType = 'PickBatch'
        group by OH.OrderId, OD.SKUId, OD.RetailUnitPrice, OD.UnitSalePrice;
    end

  /* send it to caller here */
  select LPN, OH.PickBatchNo, OH.PickTicket, OH.SalesOrder, OH.SoldToId, OH.Account, OH.ShipToStore,
         S.SKUId, S.SKU, S.SKU1, S.SKU2, S.SKU3, S.SKU4, S.SKU5,
         S.Description as SKUDescription, S.SKU1Description, S.SKU2Description, S.SKU3Description,
         S.SKU4Description, S.SKU5Description, S.UPC, OD.RetailUnitPrice, OD.UnitSalePrice,
         OH.UDF1 as OH_UDF1, OH.UDF2 as OH_UDF2, OH.UDF3 as OH_UDF3, OH.UDF4 as OH_UDF4, OH.UDF5  as OH_UDF5,
         OH.UDF6 as OH_UDF6, OH.UDF7 as OH_UDF7, OH.UDF8 as OH_UDF8, OH.UDF9 as OH_UDF9, OH.UDF10 as OH_UDF10,
         OD.UDF1 as OD_UDF1, OD.UDF2 as OD_UDF2, OD.UDF3 as OD_UDF3, OD.UDF4 as OD_UDF4, OD.UDF5  as OD_UDF5,
         OD.UDF6 as OD_UDF6, OD.UDF7 as OD_UDF7, OD.UDF8 as OD_UDF8, OD.UDF9 as OD_UDF9, OD.UDF10 as OD_UDF10,
         TLP.QtyToPrint
  from @ttLabelsToPrintProcess TLP
    join OrderHeaders OH on TLP.OrderId       = OH.OrderId
    join OrderDetails OD on OH.OrderID        = OD.OrderId and
                            TLP.OrderDetailId = OD.OrderDetailId
    join SKUs         S  on TLP.SKUId         = S.SKUId
  order by SKUSortOrder, SKU;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_GetPriceStickersData */

Go
