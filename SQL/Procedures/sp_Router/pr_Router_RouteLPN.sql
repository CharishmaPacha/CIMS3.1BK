/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/10/01  PKS     Added pr_Router_RouteLPN
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Router_RouteLPN') is not null
  drop Procedure pr_Router_RouteLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Router_RouteLPN: This is a wrapper procedure for pr_Router_SendRouteInstruction
    which will gets Destination from OH.UDF1 and pass values to pr_Router_SendRouteInstruction
------------------------------------------------------------------------------*/
Create Procedure pr_Router_RouteLPN
  (@LPNId         TRecordId = null,
   @LPN           TLPN,
   @Options       TFlag,
   @WorkId        TWorkId = null,
   @ForceExport   TFlag   = 'N',
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vMessage        TDescription,
          @vDestination    TLocation,
          @vLPNId          TRecordId,
          @vLPNStatus      TStatus,
          @vOrderId        TRecordId;

  declare @ttLPNs          TEntityKeysTable;
begin
  select @vReturnCode  = 0,
         @vMessagename = null;

  select @vLPNId     = LPNId,
         @vLPNStatus = Status,
         @vOrderId   = OrderId
  from LPNs
  where ((LPN = @LPN) or (LPNId = @LPNId));

  if (@vLPNId is null)
    set @vMessageName = 'LPNIsInvalid'
  else
  if (@vLPNStatus in ('C' /* Consumed */,
                      'V' /* Voided */,
                      'O' /* Lost */,
                      'T' /* InTransit */,
                      'L' /* Loaded */,
                      'I' /* InActive */,
                      'S' /* Staged */,
                      'F' /* New Temp */))
    set @vMessageName = 'LPNStatusIsInvalid';

  if (@vMessageName is not null)
    goto ErrorHandler;

  select @vDestination = UDF1
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Executing pr_Router_SendRouteInstruction to creates a Route instruction in our tables*/
  exec pr_Router_SendRouteInstruction @LPNId,
                                      @LPN,
                                      @ttLPNs,
                                      @vDestination,
                                      @WorkId,
                                      @ForceExport,
                                      @BusinessUnit,
                                      @UserId;
ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Router_RouteLPN */

Go
