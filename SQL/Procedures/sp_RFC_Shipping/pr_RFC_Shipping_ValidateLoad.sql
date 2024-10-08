/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/11  RKC     pr_RFC_Shipping_ValidateLoad, pr_RFC_Shipping_UnLoad: Added validation to not allow to un-load the
                      pr_RFC_Shipping_UnLoad & pr_RFC_Shipping_ValidateLoad:
  2018/12/14  RIA     pr_RFC_Shipping_Load & pr_RFC_Shipping_ValidateLoad (S2GCA-396)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Shipping_ValidateLoad') is not null
  drop Procedure pr_RFC_Shipping_ValidateLoad;
Go
/*------------------------------------------------------------------------------
  pr_RFC_Shipping_ValidateLoad
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Shipping_ValidateLoad
  (@DeviceId      TDeviceId,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit,
   @Load          TLoadNumber,
   @xmlResult     xml output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vActivityLogId         TRecordId,

          @vLoadId                TRecordId,
          @vLoadNumber            TLoadNumber,
          @vLoad                  TLoadNumber,
          @vLoadStatus            TStatus,
          @vDock                  TLocation,
          @vLoadFromWarehouse     TWarehouse,
          @vUserLogInWarehouse    TWarehouse,
          @vLoadCount             TCount,
          @vLoadsAtDock           TCount,
          @vValidLoadStatuses     TStatus;

begin
begin try
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Add to RF Log */
  exec pr_RFLog_Begin null /* xmldata */, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      null, @Load, 'Load',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Verify whether the given Load exists */
  select @vLoadId            = LoadId,
         @vLoadStatus        = Status,
         @vLoadFromWarehouse = FromWarehouse
  from Loads
  where (LoadNumber   = @Load) and
        (BusinessUnit = @BusinessUnit);

  /* If the scanned entity was not a Load, then try with Dock Location */
  if (@vLoadId is null)
    begin
      select @vLoadId            = min(LoadId),
             @Load               = min(LoadNumber),
             @vLoadsAtDock       = count(LoadId),
             @vLoadStatus        = min(Status),
             @vLoadFromWarehouse = min(FromWarehouse)
      from Loads
      where (DockLocation = @Load) and
            (BusinessUnit = @BusinessUnit) and
            (Status <> 'S' /* Shipped */);
    end

  /* Get the User Log in Warehouse from the Devices table */
  select @vUserLogInWarehouse  = Warehouse
  from Devices
  where DeviceId = @DeviceId + '@' + @UserId;

  /* Verify whether the given Load is valid status */
  select @vValidLoadStatuses = dbo.fn_Controls_GetAsString('Loading', 'ValidLoadStatuses', 'NIRML'/* New, In Progress, Ready To Load, Loading, ReadyToShip */, @BusinessUnit, @UserId);

  if (@vLoadId is null)
    select @vMessageName = 'InvalidLoadOrDock'
  else
  if (@vLoadsAtDock > 1)
    select @vMessageName = 'MultipleLoadsForDock';
  else
  if (charindex(@vLoadStatus, @vValidLoadStatuses) = 0)
    select @vMessageName = 'InvalidLoadStatus';
  else
  if (@vLoadFromWarehouse <> @vUserLogInWarehouse)
    select @vMessageName = 'Load_LoginWarehouseMismatch'

  if (@vMessage is not null)
    goto ErrorHandler;

  /* Get the Load Details of scanned Load */
  exec @xmlResult = pr_Loading_GetLoadInfo @vLoadId, @xmlResult output;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLoadId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* call proc to log error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLoadId, @ActivityLogId = @vActivityLogId output;

end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_Shipping_ValidateLoad */

Go
