/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/09/18  PK      pr_Packing_ValidateToModifyLPN: Allowed Packing Status LPNs to modify and update the CartonType and Weight of the LPNs.
  2016/04/12  RV      pr_Packing_ValidateToModifyLPN: Allow modify Picked LPN also (NBD-371)
              VM      pr_Packing_ValidateToModifyLPN: Added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_ValidateToModifyLPN') is not null
  drop Procedure pr_Packing_ValidateToModifyLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_ValidateToModifyLPN:
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_ValidateToModifyLPN
  (@LPN  TLPN)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vMessage        TDescription,
          @vLPNStatus      TStatus;
begin /* pr_Packing_ValidateToModifyLPN */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get LPN info */
  select @vLPNStatus = Status
  from  LPNs
  where (LPN = @LPN);

  /* Validate LPN */
  if (@vLPNStatus not in ('G', 'K', 'D', 'E' /* Packing, Picked, Packed, Staged */))
    set @vMessageName = 'NotAPackedLPNStatus';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_ValidateToModifyLPN */

Go
