/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateInputData') is not null
  drop Procedure pr_Imports_ValidateInputData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateInputData: Certain fields are to be validated often
    during import and this logic has been repeated in several places and hence
    all of this code is refactored into this one generic procedure. For some
    imports these fields may not exist, so in that case, we would pass in @@
    to skip the validation of that field.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateInputData
  (@BusinessUnit  TBusinessUnit,
   @Ownership     TOwnership = '@@',
   @Warehouse     TWarehouse = '@@')
as
  declare @vReturnCode   TInteger,
          @vBusinessUnit TBusinessUnit;
begin
  set @vReturnCode = 0;

  select @vBusinessUnit = BusinessUnit
  from vwBusinessUnits
  where (BusinessUnit = @BusinessUnit);

  if (coalesce(@BusinessUnit, '') = '')
    exec pr_Imports_LogError 'BusinessUnitIsRequired';
  else
  if (@vBusinessUnit is null)
    exec pr_Imports_LogError 'BusinessUnitIsInvalid';

  /* Validate Owner if needed */
  if (@Ownership <> '@@')
    exec pr_Imports_ValidateLookUp 'Owner', @Ownership;

  /* Validate Warehouse if needed */
  if (@Warehouse <> '@@')
    exec pr_Imports_ValidateLookUp 'Warehouse', @Warehouse;

  /* If any errors were recorded, then set return code appropriately */
  if exists(select * from #Errors)
    set @vReturnCode = 1;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateInputData */

Go
