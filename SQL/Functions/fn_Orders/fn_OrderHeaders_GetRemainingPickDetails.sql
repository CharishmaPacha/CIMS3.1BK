/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/12  TD      Added fn_OrderHeaders_GetRemainingPickDetails.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_OrderHeaders_GetRemainingPickDetails') is not null
  drop Function dbo.fn_OrderHeaders_GetRemainingPickDetails;
Go
/*------------------------------------------------------------------------------
  Function fn_OrderHeaders_GetRemainingPickDetails:

------------------------------------------------------------------------------*/
Create Function fn_OrderHeaders_GetRemainingPickDetails
  (@OrderId             TRecordId,
   @SorterId            varchar(30),
   @Operation           TDescription)
returns
  /* temp table  to return data */
  @RemainingDetails   table
    (OrderId            TRecordId,
     OrderDetailId      TRecordId,
     SKUId              TRecordId,
     UnitsToShip        TQuantity,
     UnitsAssigned      TQuantity,
     UnitsToAllocate    TQuantity,
     UnitsToPick        TQuantity,
     IsSortable         TFlag,

     PickPath           TLocation,
     Location           TLocation,
     PutawayZone        TZoneId,

     DestZone           TZoneId,
     PutawayPath        TLocationPath,

     RecordId           TRecordId identity (1,1),
     Primary Key        (RecordId)
    )
as
begin

  if (@Operation = 'ToteCompleteDetails')
    begin
      /* Get all the OrderDetails that are not fulfilled yet
           - then we need to make sure that there aren't picks for those in PTL/Sorter    */
      insert into @RemainingDetails (OrderId, OrderDetailId, SKUId, UnitsToShip, UnitsAssigned,
                                     UnitsToAllocate, IsSortable, DestZone, Location, PutawayZone,
                                     Putawaypath, Pickpath)
        select OD.OrderId, OD.OrderDetailId, OD.SKUId, OD.UnitsAuthorizedToShip, OD.UnitsAssigned,
               OD.UnitsToAllocate, S.IsSortable, OD.DestZone, LOC.Location, LOC.PutawayZone,
               LOC.PutawayPath, LOC.PickPath
        from OrderDetails OD
        join SKUs S        on (OD.SKUId     = S.SKUId)
        join LPNs L        on (OD.SKUId     = L.SKUId)
        join Locations LOC on (L.LocationId = LOC.LocationId)
        where (OD.OrderId  = @OrderId                     ) and
              (OD.DestZone = coalesce(@SorterId, OD.DestZone)) and
              (OD.UnitsToAllocate > 0                      ) and
              (LOC.StorageType  = 'U' /* Units */          ) and
              (LOC.LocationType = 'K' /* Picklane */       ) and
              (L.LPNType        = 'L' /* Logical */        );

      /* Get all the outstanding picks for this order */
      insert into @RemainingDetails(OrderId, OrderDetailId, SKUId, UnitsToShip, UnitsAssigned,
                                    UnitsToPick, PickPath, Location, PutawayZone,
                                    DestZone, PutawayPath)
        select @OrderId, OrderDetailId, SKUId, sum(UnitsToPick), sum(UnitsToPick),
               sum(UnitsToPick), min(PickPath), min(Location), min(LocationPAZone),
               min(DestZone), min(PutawayPath)
        from vwPickTasks PT
        where (OrderId      = @OrderId) and
              (DestZone     = coalesce(@SorterId, DestZone)) and
              (TaskSubType  = 'U') and
              (LocationType = 'K') and
              (TaskDetailstatus not in ('X', 'C' /* Cancelled, completed */))
        group by OrderDetailId, SKUId;
    end
  else
  if (@Operation = 'UnallocatedUnits')
    begin
      /* Get all the OrderDetails that are not fulfilled yet
           - then we need to make sure that there aren't picks for those in PTL/Sorter    */
      insert into @RemainingDetails (OrderId, OrderDetailId, SKUId, UnitsToShip, UnitsAssigned,
                                     UnitsToAllocate, IsSortable, DestZone, Location, PutawayZone,
                                     Putawaypath, Pickpath)
        select OD.OrderId, OD.OrderDetailId, OD.SKUId, OD.UnitsAuthorizedToShip, OD.UnitsAssigned,
               OD.UnitsToAllocate, S.IsSortable, OD.DestZone, LOC.Location, LOC.PutawayZone,
               LOC.PutawayPath, LOC.PickPath
        from OrderDetails OD
        join SKUs S        on (OD.SKUId     = S.SKUId)
        join LPNs L        on (OD.SKUId     = L.SKUId)
        join Locations LOC on (L.LocationId = LOC.LocationId)
        where (OD.OrderId  = @OrderId                     ) and
              (OD.DestZone = coalesce(@SorterId, OD.DestZone)) and
              (OD.UnitsToAllocate > 0                      ) and
              (LOC.StorageType  = 'U' /* Units */          ) and
              (LOC.LocationType = 'K' /* Picklane */       ) and
              (L.LPNType        = 'L' /* Logical */        );
    end
  if (@Operation = 'OpenTaskDetails')
    begin
      /* Get all the outstanding picks for this order */
      insert into @RemainingDetails(OrderId, OrderDetailId, SKUId, UnitsToShip, UnitsAssigned,
                                    UnitsToPick, PickPath, Location, PutawayZone,
                                    DestZone, PutawayPath)
        select @OrderId, OrderDetailId, SKUId, sum(UnitsToPick), sum(UnitsToPick),
               sum(UnitsToPick), min(PickPath), min(Location), min(LocationPAZone),
               min(DestZone), min(PutawayPath)
        from vwPickTasks PT
        where (OrderId      = @OrderId) and
              (DestZone     = coalesce(@SorterId, DestZone)) and
              (TaskSubType  = 'U') and
              (LocationType = 'K') and
              (TaskDetailstatus not in ('X', 'C' /* Cancelled, completed */))
        group by OrderDetailId, SKUId;
    end

  return;
end /* fn_OrderHeaders_GetRemainingPickDetails */

Go
