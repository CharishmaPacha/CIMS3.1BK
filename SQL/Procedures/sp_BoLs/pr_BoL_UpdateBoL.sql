/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/01  MOG     pr_BoL_UpdateBoL: pr_BoLs_Action_BoLModify: Logging modified BoL info into AT After performing ModifyBoL Action (HA-2965)
                      pr_BoL_UpdateBoL: Removed ShipToAddress updates (HA-1020)
  2020/06/25  KBB     pr_BoL_UpdateBoL:Added required fields /Changes to return success message to caller (HA-986)
  2013/12/04  PKS     pr_BoL_UpdateBoL: ShipToAddressId, BillToAddressId are now editable columns.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_UpdateBoL') is not null
  drop Procedure pr_BoL_UpdateBoL;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_UpdateBoL:
       Procedure updates the BoL based on the BoLId.
       this is used in BoL Details inline edit in Loads Page(BoL Tab).
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_UpdateBoL
  (@BoLId                TBoLId,
   @BoLNumber            TBoLNumber,
   @TrailerNumber        TTrailerNumber,
   @SealNumber           TSealNumber = null,
   @ProNumber            TProNumber  = null,
   @ShipVia              TShipVia,
   @BillToAddressId      TRecordId,
   @ShipToAddressId      TRecordId,
   @FreightTerms         TLookUpCode,
   @ShipToLocation       TShipToLocation = null,
   @FoB                  TFlags = null,
   @BoLCID               TBoLCID = null,
   @BoLInstructions      TVarchar = null,
   @Message              TDescription output)
as
  declare @ReturnCode    TInteger,
          @MessageName   TMessageName,
          @vBoLId        TBoLId,
          @vLoadId       TLoadId,
          @vBoLType      TTypeCode,
          @vFreightTerms TLookUpCode;

begin /* pr_BoL_UpdateBoLDetails */
  select @ReturnCode   = 0,
         @Message      = null,
         @MessageName  = null;

  select @vBoLId        = BoLId,
         @vBoLType      = BoLType,
         @vLoadId       = LoadId,
         @vFreightTerms = FreightTerms
  from BoLs
  where (BoLNumber = @BoLNumber);

  /* A BoL not exists with the BoLNumber value */
  if (@vBoLId is null)
    set @MessageName = 'InvalidBoL';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update BoL */
  update BoLs
  set FreightTerms    = coalesce(@FreightTerms, FreightTerms),
      SealNumber      = coalesce(@SealNumber, SealNumber),
      ProNumber       = coalesce(@ProNumber, ProNumber),
      TrailerNumber   = coalesce(@TrailerNumber, TrailerNumber),
      BillToAddressId = coalesce(@BillToAddressId, BillToAddressId),
      ShipToAddressId = coalesce(@ShipToAddressId, ShipToAddressId),
      ShipToLocation  = coalesce(@ShipToLocation, ShipToLocation),
      FoB             = coalesce(@FoB, FoB),
      BoLCID          = coalesce(@BoLCID, BoLCID),
      BoLInstructions = coalesce(@BoLInstructions, BoLInstructions)
  where (BoLId = @vBoLId);

  /* Update Freight terms as same as master bol's freight terms */
  If ((@vBoLType = 'M' /* master */) and (@vFreightTerms <> @FreightTerms))
   begin
     update BoLs
     set FreightTerms = @FreightTerms
     where (LoadId = @vLoadId);
   end

  /* Inserted the messages information to display in V3 application */
  set @Message = dbo.fn_Messages_GetDescription('BoL_Modify_Successful');

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_BoL_UpdateBoL */

Go
