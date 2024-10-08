/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/30  SJ      pr_Load_AutoGenerate, pr_Load_ValidateAddOrder: Calling ShipVia.SCAC instead of StandardAttributes.SCAC (HA-2693)
  2016/08/08  PK      pr_Load_AutoGenerate: Adding current day's processed orders to current day's load.
  2016/07/21  TK      pr_Load_AutoGenerate: Initial Revision (HPI-265)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_AutoGenerate') is not null
  drop Procedure pr_Load_AutoGenerate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_AutoGenerate:
     AutoGenerate procedure calls pr_Load_Generate with all orders where batches
     are released for picking
------------------------------------------------------------------------------*/
Create Procedure pr_Load_AutoGenerate
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,

          @vRecordId         TRecordId,
          @vOrderId          TRecordId,
          @vShipVia          TShipVia,
          @vCarrier          TCarrier,
          @vShipViaSCAC      TTypeCode,
          @vLoadId           TRecordId,

          @vGenerateLoads    TControlValue;

  declare @ttOrdersToLoad table (OrderId       TRecordId,
                                 PickTicket    TPickTicket,
                                 ShipVia       TShipVia,
                                 Carrier       TCarrier,
                                 ShipViaSCAC   TTypecode,

                                 RecordId      TRecordId identity (1, 1));

begin /* pr_Load_AutoGenerate */
  select @ReturnCode      = 0,
         @vRecordId       = 0,
         @vLoadId         = null,
         @MessageName     = null;

  /* Get Contols */
  select @vGenerateLoads = dbo.fn_Controls_GetAsString('Loads', 'AutoGenerateLoad', 'N' /* No */, @BusinessUnit, @UserId);

  /* Get the Orders which are ready to Load */
  insert into @ttOrdersToLoad (OrderId, PickTicket, ShipVia, Carrier, ShipViaSCAC)
    select OH.OrderId,
           OH.PickTicket,
           SV.ShipVia,
           SV.Carrier,
           SV.SCAC
    from OrderHeaders OH
      join PickBatches PB on (OH.PickBatchId = PB.RecordId)
      join ShipVias    SV on (OH.ShipVia     = SV.ShipVia )
    where ((PB.BatchType in ('PP', 'SW', 'SP')) and
           (OH.Status in ('P', 'K', 'G', 'L' /* Picked, Packed, Staged, Loaded */)))
          or
          ((PB.BatchType in ('PC', 'SLB')) and
           (OH.Status in ('K', 'G', 'L' /* Packed, Staged, Loaded */)))
          and
          (OH.BusinessUnit = @BusinessUnit);

  /* delete the Orders which are already on Load */
  delete OTL
  from @ttOrdersToLoad OTL join vwOrderShipments OS on OTL.OrderId = OS.OrderId
  where (OS.LoadId > 0);

  /* Return if there are none to Load */
  if (@@rowcount = 0)
    return;

  /* Loop thru all the Orders and add them to Load */
  while exists (select * from @ttOrdersToLoad where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId    = RecordId,
                   @vOrderId     = OrderId,
                   @vShipVia     = ShipVia,
                   @vCarrier     = Carrier,
                   @vShipViaSCAC = ShipViaSCAC
      from @ttOrdersToLoad
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Find available Load matching ShipViaSCAC or Carrier */
      select top 1 @vLoadId = LoadId
      from Loads
      where ((LoadType = @vShipViaSCAC) or
             ((LoadType = @vCarrier and ShipVia = @vShipVia))) and
             (cast(CreatedDate as Date) = cast(current_timestamp as Date)) and
            (Status not in ('S', 'X' /* Shipped, Cancelled */));

      /* If there is no available load to add then generate new one */
      if (@vLoadId is null) and (@vGenerateLoads = 'Y' /* Yes */)
        begin
          /* TODO LATER:

             Generate Load and return LoadId */
         return;
        end

      /* Add order to the Load */
      if (@vLoadId is not null)
        begin
          exec pr_Load_AddOrder @vLoadId, @vOrderId, @BusinessUnit, @UserId;

          /* Recount the loads to update the counts on the Loads */
          exec pr_Load_Recount @vLoadId;
        end

      select @vLoadId = null;
    end

end /* pr_Load_AutoGenerate */

Go
