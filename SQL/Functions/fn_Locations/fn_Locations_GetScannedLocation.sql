/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/19  TK      fn_Locations_GetScannedLocation: Changes made to return location from mapped Warehouse set (HA-223)
  2020/03/30  TK      fn_Locations_GetScannedLocation: Scanned location should be from user logged in Warehouse (HA-75)
  2019/04/12  RIA     fn_Locations_GetScannedLocation: Changes to not consider the deleted locations (HPI-2564)
  2015/04/30  TK      fn_Locations_GetScannedLocation: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Locations_GetScannedLocation') is not null
  drop Function fn_Locations_GetScannedLocation;
Go
/*------------------------------------------------------------------------------
  fn_Locations_GetScannedLocation:
    This function returns LocationId where user Scans Location or Location Barcode.
------------------------------------------------------------------------------*/
Create Function fn_Locations_GetScannedLocation
  (@LocationId         TRecordId,
   @Location           TLocation,
   @DeviceId           TDeviceId,
   @UserId             TUserId,
   @BusinessUnit       TBusinessUnit)
  ----------------------------------
   returns             TRecordId
as
begin
  declare @vLocationId              TRecordId,
          @vLocStatus               TStatus,
          @vScanLocationPreference  TControlValue,
          @vUserLoggedInWH          TWarehouse;
  declare @ttAllowedWHs             TEntityKeysTable;

  select @vLocationId = null;

  /* Get the user logged in Warehouse */
  select @vUserLoggedInWH = dbo.fn_Users_LoggedInWarehouse(@DeviceId, @UserId, @BusinessUnit);

  /* Get the allowed Warehouse from the mapping set up
     There are chances that user might be allowed to perform some operation across the Warehouses so,
     get all the that are allowed for the logged in Warehouse */
  insert into @ttAllowedWHs(EntityKey)
    select TargetValue
    from dbo.fn_GetMappedValues('CIMS', @vUserLoggedInWH,'CIMS', 'Warehouse', null /* Operation */, @BusinessUnit)

  /* if neither are given, or both are given then exit */
  if ((coalesce(@LocationId, 0) = 0) and (@Location is null)) --or
    -- ((coalesce(@LocationId, 0) <> 0) and (@Location is not null)))
    return (null);

  /* If location Id is given, then try it */
  if (coalesce(@LocationId, 0) <> 0)
    begin
      select @vLocationId = LocationId
      from Locations
      where (LocationId = @LocationId) and
            (Status     <> 'D' /* Deleted */);

      return (@vLocationId);
    end

  /* Get Control var to check if the preference of scanning is location or barcode */
  select @vScanLocationPreference = dbo.fn_Controls_GetAsString('Location', 'ScanPreference', 'L' /* Location */, @BusinessUnit, null /* UserId */);

  /* If we are here, then it means the caller has only given Location. In this situation
     we have two choices a. To compare the user scanned value with Barcode or b. Compare
     with Location itself.

     The common practice is to match with 'Location', however for some clients we have to
     match with 'Barcode'. For performance reasons we have to do one or the other and
     so we are using control var for client preference */

  /* if the preference for the client is to compare with "Barcode" then check that first */
  if (@vScanLocationPreference = 'B' /* Barcode */)
    select @vLocationId = LocationId
    from Locations LOC
      join @ttAllowedWHs ttAWHs on (LOC.Warehouse = ttAWHs.EntityKey)
    where (LOC.Barcode      = @Location         ) and
          (LOC.Status       <> 'D' /* Deleted */) and
          (LOC.BusinessUnit = @BusinessUnit     );

  /* If it does not match Barcode field, then try Location */
  if (@vLocationId is null)
    select @vLocationId = LocationId,
           @vLocStatus  = Status
    from Locations LOC
      join @ttAllowedWHs ttAWHs on (LOC.Warehouse = ttAWHs.EntityKey)
    where (LOC.Location     = @Location) and
          (LOC.BusinessUnit = @BusinessUnit);

  /* If location is deleted then it is not a valid location to use, so return null */
  if (@vLocStatus = 'D')
    select @vLocationId = null;

  return(@vLocationId);
end /* fn_Locations_GetScannedLocation */

Go
