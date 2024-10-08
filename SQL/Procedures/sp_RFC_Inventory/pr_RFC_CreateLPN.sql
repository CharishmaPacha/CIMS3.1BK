/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/03/05  VM      pr_RFC_CreateLPN: Fixed the issue of creating LPN. This should actually use an existing empty LPN.
  2010/12/15  PK      Created pr_RFC_CreateLPN, pr_RFC_ConfirmCreateLPN, Minor Corrections.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CreateLPN') is not null
  drop Procedure pr_RFC_CreateLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CreateLPN:
  RF : Scan LPN: User is presented with an option to scan or enter a new LPN
       for the container of inventory to be added to the system. The entered LPN
       is validated to ensure it is an unused and/or empty LPN
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CreateLPN
  (@LPN            TLPN,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,

          @vLPNId         TRecordId,
          @vLPN           TLPN,
          @vStatus        TStatus;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vLPN     = LPN,
         @vLPNId   = LPNId,
         @vStatus  = Status
  from LPNs
  where (LPN          = @LPN) and
        (BusinessUnit = @BusinessUnit);

  if (@vLPN is null)
    set @MessageName = 'LPNDoesNotExist';
  else
  if (@vStatus <> 'N' /* New */)
    set @MessageName = 'InvalidLPNStatus';

  if (@MessageName is not null)
    goto ErrorHandler;

  select @vLPN as LPN; --return

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_CreateLPN */

Go
