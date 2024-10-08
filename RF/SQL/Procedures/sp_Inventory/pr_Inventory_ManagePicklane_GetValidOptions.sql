/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_ManagePicklane_GetValidOptions') is not null
  drop Procedure pr_Inventory_ManagePicklane_GetValidOptions;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Inventory_ManagePicklane_GetValidOptions: Returns the operations
   that can be performed on the scanned picklane.

 Assumption: Input Locationid is valid.
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_ManagePicklane_GetValidOptions
  (@LocationId      TRecordId,
   @BusinessUnit    TBusinessUnit,
   @DisplayOptions  TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vSKUExists                TFlag,
          @vLocationStatus           TStatus,
          @vAllowMultipleSKUs        TFlags;
begin /* pr_Inventory_ManagePicklane_GetValidOptions */

  /* Get the SKU that is associated with the location */
  select @vSKU               = S.SKU,
         @vSKUId             = S.SKUId,
         @vSKUExists         = case when LOC.NumLPNs > 0 then 'Y' else 'N' end,
         @vLocationStatus    = LOC.Status,
         @vAllowMultipleSKUs = LOC.AllowMultipleSKUs
  from Locations LOC
    left outer join LPNs L  on L.LocationId = LOC.LocationId
    left outer join SKUs S on S.SKUId = L.SKUId
  where (LOC.LocationId = @LocationId);

  /* Now determine what are valid options for user to perform for this picklane */

  /* Can always setup picklane - even if it is empty and even if does not have a SKU */
  select @DisplayOptions = dbo.fn_XMLNode('SetupPicklane', 'Y');

  /* If picklane has SKU, then can user may be able to remove it */
  if (@vSKUExists = 'Y')
    select @DisplayOptions += dbo.fn_XMLNode('RemoveSKU', 'Y');

  /* If SKU does not exist in the Location or Location Allow Multiple SKUs, then
     user can add a SKU */
  if (@vSKUExists = 'N') or (@vAllowMultipleSKUs = 'Y')
    select @DisplayOptions += dbo.fn_XMLNode('AddSKU', 'Y');

  /* User can always add a SKU and add inventory or add inventory for an existing SKU */
  select @DisplayOptions += dbo.fn_XMLNode('AddInventory', 'Y');

end /* pr_Inventory_ManagePicklane_GetValidOptions */

Go

