/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNDtl_AddSKUsToPicklane') is not null
  drop Procedure pr_Imports_ASNLPNDtl_AddSKUsToPicklane;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNLPNDtl_AddSKUsToPicklane: Add the given lines to the picklane
    LPN
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNDtl_AddSKUsToPicklane
  (@ImportASNLPNDetails  TASNLPNImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vLocation          TLocation,
          @vLocationid        TRecordId,
          @vSKUId             TRecordId,
          @vInnerPacks        TInnerPacks,
          @vQuantity          TQuantity,
          @vWarehouse         TWarehouse,
          @vCreatedBy         TUserId,
          @vBusinessUnit      TBusinessUnit;
begin
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Loop thru each record and add SKU to each of the picklanes */
  while exists (select * from @ImportASNLPNDetails where RecordId > @vRecordId and RecordAction = 'L')
    begin
      select top 1 @vLPN          = LPN,
                   @vRecordId     = RecordId,
                   @vSKUId        = SKUId,
                   @vInnerPacks   = InnerPacks,
                   @vQuantity     = Quantity,
                   @vWarehouse    = DestWarehouse,
                   @vBusinessUnit = BusinessUnit,
                   @vCreatedBy    = CreatedBy
      from @ImportASNLPNDetails
      where (RecordId > @vRecordId) and (RecordAction = 'L');

      select @vLocationId = LocationId,
             @vLocation    = Location
      from Locations
      where (Location = @vLPN) and (BusinessUnit = @vBusinessUnit);

      exec pr_Locations_AddSKUToPicklane @vSKUId,
                                         @vLocationId,
                                         @vInnerPacks,
                                         @vQuantity,
                                         '+' /* Update Option */,
                                         'N' /* Export Option */,
                                         @vCreatedBy,
                                         '999' /* ReasonCode - Initial Inventory */,
                                         @vLPNId output;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ASNLPNDtl_AddSKUsToPicklane */

Go
