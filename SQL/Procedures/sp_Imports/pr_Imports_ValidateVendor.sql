/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/02/07  PK      Created pr_Imports_Vendors, pr_Imports_ASNLPNs, pr_Imports_ASNLPNDetails,
                      pr_Imports_ValidateVendor, pr_Imports_ValidateASNLPNs, pr_Imports_ValidateASNLPNDetails.
                      pr_Imports_ImportRecord: Added support for ASNs and Vendor Imports.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateVendor') is not null
  drop Procedure pr_Imports_ValidateVendor;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateVendor:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateVendor
  (@Action       TFlag output,
   @VendorId     TVendorId,
   @BusinessUnit TBusinessUnit)
as
  declare @vReturnCode   TInteger,
          @vVendor       TName,
          @vVendorId     TVendorId,
          @vBusinessUnit TBusinessUnit;
begin
  set @vReturnCode = 0;

  exec @vReturnCode = pr_Imports_ValidateInputData @BusinessUnit;

  select @vVendor   = VendorName,
         @vVendorId = VendorId
  from Vendors
  where (VendorId     = @VendorId) and
        (Businessunit = @BusinessUnit);

  /* If the user trying to insert an existing record into the db or
                 trying to update or delete the non existing record
     then we need to resolve what to do based upon control value */
  select @Action = dbo.fn_Imports_ResolveAction('VEN', @Action, @vVendor, @BusinessUnit, null /* UserId */);

  if (@Action = 'X'/* Invalid action */)
    exec pr_Imports_LogError 'Import_InvalidAction';

  if (coalesce(@VendorId, '') = '')
    exec pr_Imports_LogError 'VendorIsRequired';

  if (@Action = 'E'/* Error */) and
     (@vVendor is not null)
    exec pr_Imports_LogError 'VendorAlreadyExists';
  else
  if (@Action = 'E' /* Error */) and
     (@vVendor is null)
    exec pr_Imports_LogError 'VendorDoesNotExist';

  /* If any errors were recorded, then set return code appropriately */
  if exists(select * from #Errors)
    set @vReturnCode = 1;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateVendor */

Go
