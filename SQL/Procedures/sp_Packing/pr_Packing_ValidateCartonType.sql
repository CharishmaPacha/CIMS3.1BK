/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_ValidateCartonType') is not null
  drop Procedure pr_Packing_ValidateCartonType;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_ValidateCartonType:
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_ValidateCartonType
  (@CartonType         TCartonType,
   @ValidCartonType    TCartonType  output,
   @CartonDescription  TDescription output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vCartonStatus      TStatus;
begin /* pr_Packing_ValidateCarton */

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Carton info, if no description then return carton type itself */
  select @ValidCartonType   = CartonType,
         @CartonDescription = coalesce(Description, @ValidCartonType),
         @vCartonStatus     = Status
  from  vwCartonTypes
  where (CartonType = @CartonType);

  /* Validate the Carton */
  if (@ValidCartonType is null)
    set @vMessageName = 'CartonTypeDoesNotExist';
  else
  /* Validate Carton Status */
  if (@vCartonStatus not in ('A'/* Active */))
    set @vMessageName = 'CartonTypeNotAvailableForPacking';

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_ValidateCarton */

Go

/*------------------------------------------------------------------------------
  Proc pr_Packing_Unpack: The procedure gets called from pr_Entities_ExecuteAction.
  It is used to unpack all orders in a wave  or the selected orders in the input data.

  UnPack: Process of taking any packed LPNs and reverting the contents of the LPN
    back to a cart position for repacking.

  When mulitple orders are given, each order is unpacked to an existing position on the
     cart if the order is already on the cart or else to a new position.
------------------------------------------------------------------------------*/
