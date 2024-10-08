/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/06/10  RT      pr_Shipping_GetPackingListsToPrint: Included RecordId to sort the records while inserting (S2GCA-837)
  2018/09/04  RT/VM   pr_Shipping_GetPackingListsToPrint: Retain passed in PackingListType to use it for all entities passed (S2GCA-237)
  2018/08/23  RT      pr_Shipping_GetPackingListsToPrint: Added OrderId to get the Packing List Type LPNWithODs for ASD WALMART PL (S2GCA-205)
  2016/07/29  RV      pr_Shipping_GetPackingListsToPrint: Made changes to print appropriate packing list based upon the source and entity type (HPI-385)
  2016/05/09  RV      pr_Shipping_GetPackingListData: Get the Packing list type from pr_Shipping_GetPackingListsToPrint and
                        use for printing the packing list (NBD-493)
  2016/05/05  AY      pr_Shipping_GetPackingListsToPrint: Print Order Packing list when order or PT are given.
  2015/10/30  SV      pr_Shipping_GetPackingListsToPrint: Handled to return the LPNs to print info even if BatchNo is null over PT (CIMS-677)
  2015/03/11  DK      pr_Shipping_GetPackingListData, pr_Shipping_GetPackingListsToPrint : :Made changes to print ReturnPackingSlip.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetPackingListsToPrint') is not null
  drop Procedure pr_Shipping_GetPackingListsToPrint;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetPackingListsToPrint: Returns all the list of entities
    to print the packing lists for, for the given criteria.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetPackingListsToPrint
  (@LPNsXML         XML = null /* Carton */,
   @PickTicketsXML  XML = null,
   @BatchNosXML     XML = null,
   @ShipmentId      TShipmentId  = null,
   @LoadId          TLoadId      = null,
   @PackingListType TTypeCode,
   @Options         XML          = null,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @vOrderId          TRecordId,
          @vPickTicket       TPickTicket,
          @vLPNId            TRecordId,
          @vLPN              TLPN,
          @vLPNsAssigned     TCount,
          @vPackageSeqNo     TInteger,
          @vLPNOrderId       TRecordId,
          @vOrderStatus      TStatus,
          @vBatchNo          TPickBatchNo,
          @vWaveType         TTypeCode,
          @vSource           TName,
          @vEntity           TEntity,
          @vEntityType       TEntity,

          @vPackingListType  TTypeCode,
          @xmlRulesData      TXML;

  declare @Entities             table
          (EntityKey  TEntity,
           EntityType TTypeCode,
           EntityId   TRecordId);

  declare @PackingListsToPrint  table
          (OrderId         TRecordId,
           LPNId           TRecordId,
           LPN             TLPN,
           LoadId          TLoadId,
           PackingListType TTypeCode,
           PrintPL         TBoolean default 1,
           RecordId        TRecordId Identity(1,1));
begin
  if (@BatchNosXML is not null)
    insert into @Entities
    select Record.Col.value('.', 'varchar(max)'), 'PickBatch', null
    from @BatchNosXML.nodes('/BatchNos/BatchNo') as Record(Col)

  if (@PickTicketsXML is not null)
    insert into @Entities
    select Record.Col.value('.', 'varchar(max)'), 'PickTicket', null
    from @PickTicketsXML.nodes('/PickTickets/PickTicket') as Record(Col)

  if (@LPNsXML is not null)
    insert into @Entities
    select Record.Col.value('.', 'varchar(max)'), 'LPN', null
    from @LPNsXML.nodes('/LPNs/LPN') as Record(Col)

  if (@LoadId is not null)
    insert into @Entities
    select @LoadId, 'Load', @LoadId;

  /* Get the Source from the Options input xml */
  if (@Options is not null)
    select @vSource     = nullif(Record.Col.value('Source[1]',     'TName'),''),
           @vEntityType = nullif(Record.Col.value('EntityType[1]', 'TEntity'),'')
    from @Options.nodes('/Options') as Record(Col);

  while exists(select * from @Entities)
    begin
      /* Get first entity */
      select top 1
             @vEntity     = EntityKey,
             @vLPN        = case when EntityType = 'LPN'        then EntityKey else null end,
             @vPickTicket = case when EntityType = 'PickTicket' then EntityKey else null end,
             @vBatchNo    = case when EntityType = 'PickBatch'  then EntityKey else null end
      from @Entities

      /* Initializing local variable with original packing list type for each entity
         as PackingListType could be changed based on rules and also to retain the orginial PackingListType for all entities passed */
      select @vPackingListType = @PackingListType;

      /* If caller requests that an LPN Packing list be printed for an LPN, we don't trust that
         as UI is not doing the right thing now, so we are using rules to figure out what to print
         Get the types of packing lists to print. result could be LPN, ORD or LPN+ORD */
      if (@vPackingListType = 'LPN') and (@vLPN is not null)
        begin
          select @vPackingListType = null;

          select @vLPNId        = LPNId,
                 @vLPNOrderId   = OrderId,
                 @vPackageSeqNo = PackageSeqNo
          from LPNs
          where LPN = @vLPN;

          select @vLPNsAssigned = OH.LPNsAssigned,
                 @vOrderStatus  = OH.Status,
                 @vWaveType     = PB.BatchType
          from OrderHeaders OH
            left outer join PickBatches PB on (OH.PickBatchId = PB.RecordId)
          where OrderId = @vLPNOrderId;

          /* Build the xml data for the given LPN to evaluate the packing list type */
          select @xmlRulesData ='<RootNode>'     +
                                dbo.fn_XMLNode('LPN',           @vLPN) +
                                dbo.fn_XMLNode('OrderId',       @vLPNOrderId) +
                                dbo.fn_XMLNode('PackageSeqNo',  @vPackageSeqNo) +
                                dbo.fn_XMLNode('LPNsAssigned',  @vLPNsAssigned) +
                                dbo.fn_XMLNode('OrderStatus',   @vOrderStatus) +
                                dbo.fn_XMLNode('Operation',     coalesce(@vSource, 'ShippingDocs')) +  /* As of now we have hard coded, In future this parameter passing from UI */
                                dbo.fn_XMLNode('EntityType',    @vEntityType) +
                                dbo.fn_XMLNode('WaveType',      @vWaveType) +
                                '</RootNode>';  -- build the xml data for the given LPN

          exec pr_RuleSets_Evaluate 'PackingListType', @xmlRulesData, @vPackingListType output;
        end

      /* From the Shipping Docs if user scans Wave then Packing List Type sends as 'bn'
         If the Scanned Entity is Wave we need to evaluate Packing list type based on the rules*/
      if (@vPackingListType = 'bn' /* Batch No */ and @vBatchNo is not null)
        begin
          /* Build the xml data for the given LPN to evaluate the packing list type */
          select @xmlRulesData ='<RootNode>'     +
                                dbo.fn_XMLNode('Operation',     coalesce(@vSource, 'ShippingDocs')) +  /* As of now we have hard coded, In future this parameter passing from UI */
                                dbo.fn_XMLNode('EntityType',    @vEntityType) +
                                '</RootNode>';  -- build the xml data for the given LPN

          exec pr_RuleSets_Evaluate 'PackingListType', @xmlRulesData, @vPackingListType output;
        end

      if (@vLPN is not null and @vPackingListType = 'ORD') -- Fechheimer scenario
        begin
          /* Print an Order Packing list for each of the Orders in the LPN */
          insert into @PackingListsToPrint(OrderId, PackingListType)
            select PO.OrderId, @vPackingListType
            from dbo.fn_Shipping_GetPackedOrders(@vLPN) PO;
        end
      else
      if (@vPackingListType = 'ORD') and (@vPickTicket is not null)
        begin
          /* Print Order Packing lists for the specified Order */
          insert into @PackingListsToPrint (OrderId, PackingListType)
            select OrderId, @vPackingListType
            from vwOrderHeaders
            where (PickTicket = @vPickTicket) and
                  (OrderType not in ('B', 'R')); -- Ignore Bulk/Replenish Orders
        end
      else
      if (@vPackingListType = 'ORD') and (@vBatchNo is not null)
        begin
          /* Print Order Packing lists for all Orders of the given batch */
          insert into @PackingListsToPrint (OrderId, PackingListType)
            select OrderId, @vPackingListType
            from vwOrderHeaders
            where (PickBatchNo = @vBatchNo) and
                  (OrderType not in ('B', 'R')); -- Ignore Bulk/Replenish Orders
        end
      else
      if (@vPackingListType = 'LPN') and (@vLPN is not null)
        begin
          /* If the LPN needs a Order packing list, then add to the list to print */
          if (@vPackingListType = 'ORD')
            insert into @PackingListsToPrint (OrderId, PackingListType)
              select @vLPNOrderId, @vPackingListType

          /* If the LPN needs a LPN packing list, then add to the list to print */
          if (@vPackingListType = 'LPN')
            insert into @PackingListsToPrint (LPNId, LPN, OrderId, PackingListType)
              select @vLPNId, @vLPN, @vLPNOrderId, @vPackingListType
        end
      else
      /* LPNWithLDs - Packing List type to print all the LPN details for a LPN
         LPNWithODs - Packing List type to print all the Order details for a LPN  */
      if (@vPackingListType in ('LPN','ReturnLPN', 'LPNWithLDs', 'LPNWithODs'/* for return Packing list */))
        begin
          /* Print Packing list for the individual LPN - like at Loehmanns */
          insert into @PackingListsToPrint (OrderId, LPNId, LPN, PackingListType)
            select L.OrderId, LPNId, LPN, @vPackingListType
            from vwLPNs L inner join OrderHeaders OH on L.OrderId = OH.OrderId
            where (L.LPNType      in ('C', 'S' /* Carton, ShipCarton */)) and
                  (L.LPN          = coalesce(@vLPN,        L.LPN))        and
                  (L.PickTicket   = coalesce(@vPickTicket, L.PickTicket)) and
                  (coalesce(OH.PickBatchNo, '') = coalesce(@vBatchNo, OH.PickBatchNo, ''))
        end
     else
     if (@vPackingListType = 'Load')
       begin
         insert into @PackingListsToPrint (LoadId, PackingListType)
           select @LoadId, @vPackingListType;
       end

      /* Delete the entity that has been processed */
      delete @Entities
      where EntityKey = @vEntity
    end

  select OrderId, LPNId, LPN, LoadId, PackingListType, PrintPL
  from @PackingListsToPrint
  order by RecordId;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_GetPackingListsToPrint */

Go
