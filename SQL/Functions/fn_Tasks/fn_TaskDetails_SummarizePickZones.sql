/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/08  AY      fn_TaskDetails_SummarizePickZones: Revised with new option (S2GCA-749)
  2019/04/20  TK      fn_TaskDetails_SummarizePickZones: Initial Revision (CID-265)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_TaskDetails_SummarizePickZones') is not null
  drop Function fn_TaskDetails_SummarizePickZones;
Go
/*------------------------------------------------------------------------------
  fn_TaskDetails_SummarizePickZones: This function returns the pickzones from the allocated
    picks of the order/cubed carton with comma separated

  Method: UNIQUE/LIST
  UNIQUE: if it is single zone, then it gives that zone, else MIXED
  LIST: Gives the list of zones in CSV format
------------------------------------------------------------------------------*/
Create Function fn_TaskDetails_SummarizePickZones
  (@OrderId    TRecordId  = null,
   @LPNId      TRecordId  = null,
   @Operation  TOperation = null,
   @Method     TOperation = null)
 --------------------------------
  returns      TVarchar
as
begin
  declare @vPickZones  TVarchar,
          @vZoneCount  TInteger;

  /* If caller has passed in LPNId then get zones of all the picks going to that carton */
  if (@Method = 'LIST')
    if (@LPNId is not null)
      select @vPickZones =  stuff((select ',' + Loc.PickingZone
                                   from TaskDetails TD
                                     join Locations Loc on (Loc.LocationId = TD.LocationId)
                                   where (TD.TempLabelId = @LPNId) and
                                         (Loc.PickingZone is not null)
                                   group by Loc.PickingZone
                                   order by Loc.PickingZone
                                   for XML PATH(''), type).value('.','TVarchar'), 1, 1,'');
    else
      /* Get zones of all the picks for that Orders */
      select @vPickZones = stuff((select ',' + Loc.PickingZone
                                  from TaskDetails TD
                                    join Locations Loc on (Loc.LocationId = TD.LocationId)
                                  where (TD.OrderId = @OrderId) and
                                        (Loc.PickingZone is not null)
                                  group by Loc.PickingZone
                                  order by Loc.PickingZone
                                  for XML PATH(''), type).value('.','TVarchar'), 1, 1,'');

  /* If Method is Unique, then we get the distinct zone of all concerned entities. If not, we
     return mixed */
  if (@Method = 'UNIQUE')
    begin
      if (@LPNId is not null)
        select @vPickZones = min(Loc.PickingZone),
               @vZoneCount = count(distinct Loc.PickingZone)
         from TaskDetails TD
           join Locations Loc on (Loc.LocationId = TD.LocationId)
         where (TD.TempLabelId = @LPNId) and
               (Loc.PickingZone is not null)
      else
        select @vPickZones = min(Loc.PickingZone),
               @vZoneCount = count(distinct Loc.PickingZone)
         from TaskDetails TD
           join Locations Loc on (Loc.LocationId = TD.LocationId)
         where (TD.OrderId = @OrderId) and
               (Loc.PickingZone is not null);

      if (@vZoneCount > 1) select @vPickZones = 'Mixed';
    end

  return(@vPickZones);
end /* fn_TaskDetails_SummarizePickZones */

Go
