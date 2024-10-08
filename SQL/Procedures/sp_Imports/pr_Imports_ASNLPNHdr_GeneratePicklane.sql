/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNHdr_GeneratePicklane') is not null
  drop Procedure pr_Imports_ASNLPNHdr_GeneratePicklane;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNLPNHdr_GeneratePicklane: if attempting to import a logical
   LPN, then generate it
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNHdr_GeneratePicklane
  (@ImportASNLPNHeaders  TASNLPNImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vLPNId             TRecordId,
          @vLPN               TLPN,
          @vLocation          TLocation,
          @vLocationid        TRecordId,
          @vWarehouse         TWarehouse,
          @vCreatedBy         TUserId,
          @vBusinessUnit      TBusinessUnit;
begin
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Loop thru each record and generate the logical LPN */
  while exists (select * from @ImportASNLPNHeaders where RecordId > @vRecordId and RecordAction = 'L')
    begin
      select top 1 @vLPN          = LPN,
                   @vRecordId     = RecordId,
                   @vWarehouse    = DestWarehouse,
                   @vBusinessUnit = BusinessUnit,
                   @vCreatedBy    = CreatedBy
      from @ImportASNLPNHeaders
      where (RecordId > @vRecordId) and (RecordAction = 'L');

      select @vLocationId = LocationId,
             @vLocation    = Location
      from Locations
      where (Location = @vLPN) and (BusinessUnit = @vBusinessUnit);

      exec @vReturnCode = pr_Locations_GenerateLogicalLPN 'L' /* Logical Carton */, 1 /* NumberOfLPNs */,
                                                          'N' /* New - LPN Status */,
                                                          @vLocationId,
                                                          @vLocation,
                                                          null /* SKU */,
                                                          @vWarehouse,
                                                          @vBusinessUnit,
                                                          @vCreatedBy,
                                                          @vLPNId output;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ASNLPNHdr_GeneratePicklane */

Go
