/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/10  AY      pr_LPNs_IdentifyLPNOrLocation: New procedure to distinguish between LPN and Location (S2GCA-108)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_IdentifyLPNOrLocation') is not null
  drop Procedure pr_LPNs_IdentifyLPNOrLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_IdentifyLPNOrLocation: In some RF functions, we would want the
   to give user the capability to scan either and LPN or a Location and this
   procedure woudl be used to identify which one the user scanned and process
   accordingly. It would return all nulls if it is neither.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_IdentifyLPNOrLocation
  (@Entity           TEntity,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @EntityType       TTypeCode = null output,
   @LPNId            TRecordId = null output,
   @LPN              TLPN      = null output,
   @LocationId       TRecordId = null output,
   @Location         TLocation = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         /* Initialize all output params */
         @EntityType   = null,
         @LPNId        = null,
         @LPN          = null,
         @LocationId   = null,
         @Location     = null;

  /* Find out whether user scanned destination as LPN or Location */
  if (@Entity is null)
    return;

  /* Check if it is a Location */
  select @LocationId = LocationId,
         @Location   = Location,
         @EntityType = 'LOC'
  from Locations
  where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @Entity, null /* DeviceId */, @UserId, @BusinessUnit));

  /* If user didn't scan Location then check if LPN is scanned */
  if (@LocationId is null)
    select @LPNId      = LPNId,
           @LPN        = LPN,
           @EntityType = 'LPN'
    from LPNs
    where (LPNId = dbo.fn_LPNs_GetScannedLPN(@Entity, @BusinessUnit, default /* Options */)) and
          (LPNType <> 'L'/* Picklane */); -- Ignore Picklane LPNs as they are treated as Locations

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_IdentifyLPNOrLocation */

Go
