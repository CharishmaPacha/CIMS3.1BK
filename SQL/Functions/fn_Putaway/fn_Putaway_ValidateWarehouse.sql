/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/08/30  TD      Added fn_Putaway_ValidateWarehouse.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Putaway_ValidateWarehouse') is not null
  drop Function fn_Putaway_ValidateWarehouse;
Go
/*------------------------------------------------------------------------------
  Proc fn_Putaway_ValidateWarehouse: Validates if an LPN of the specified
    Warehouse can be accepted into a Location of the specified Warehouse.
    This function uses mapped Warehouses to validate the match between physical and
    Logical/virtual Warehouses.
------------------------------------------------------------------------------*/
Create Function fn_Putaway_ValidateWarehouse
  (@LocWarehouse TWarehouse,
   @LPNWarehouse TWarehouse,
   @Operation    TDescription,
   @BusinessUnit TBusinessUnit)
 -------------------------------
   returns          TDescription
as
begin /* fn_Putaway_ValidateWarehouse */
  declare  @MessageName                 TMessageName,
           @vAllowMoveBetweenWarehouses TControlValue;;

  select @MessageName = null;

  select @vAllowMoveBetweenWarehouses = dbo.fn_Controls_GetAsString('Inventory', 'MoveBetweenWarehouses', 'Y' /* Yes */,
                                                                    @BusinessUnit, null /* Userid */);

  if (@vAllowMoveBetweenWarehouses = 'N' /* No */) and
     (@LocWarehouse not in (select TargetValue
                            from dbo.fn_GetMappedValues('CIMS', @LPNWarehouse,'CIMS', 'Warehouse', @Operation, @BusinessUnit)))
    begin /* set  messgae based on the Operation */
      if (@Operation = 'LPNPutaway')
        set @MessageName = 'WarehouseMismatch'
      else
      if (@Operation ='LPNMove')
        set @MessageName = 'LPNMove_WarehouseMismatch'
    end

  return @MessageName;
end /* fn_Putaway_ValidateWarehouse */

Go
