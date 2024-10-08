/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/26  RIA     pr_Putaway_PALPNResponse: Return the DisplayQty that is sent to the proc (HA-990)
  2020/05/05  RIA     pr_Putaway_PALPNResponse: Changes to send default qty (HA-414)
  2018/12/14  TK      pr_Putaway_PALPNResponse: Changes to display empty if default qty to putaway is zero
  2018/03/15  AY/TD   pr_Putaway_PALPNResponse: Enhanced to show DefaultQty in Cases/Units.
                      pr_Putaway_PALPNResponse:Changes to send PutawayMode based on innerpacks (S2G-361)
  2017/09/26  CK      pr_Putaway_MinimumQtyToPA, pr_Putaway_PALPNResponse: Enahanced to return PromptScreen for redirect to MoveLPN Screen in RF (HPI-1682)
  2017/08/17  TK      pr_Putaway_PALPNResponse: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Putaway_PALPNResponse') is not null
  drop Procedure pr_Putaway_PALPNResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_Putaway_PALPNResponse: Procedure to send a response to user as to how
    much to PA from the LPN into the Location and how to navigate after putaway.

  For Replenish PA, this considers the MinQty to be putaway into the Location.
------------------------------------------------------------------------------*/
Create Procedure pr_Putaway_PALPNResponse
  (@PALPNId            TRecordId,
   @PASKUId            TRecordId,
   @DestLocId          TRecordId,
   @DisplayQty         TDescription,
   @DefaultQty         TQuantity,
   @PromptScreen       TDescription = 'SameScreen',
   @PartialPutaway     TFlags,
   @MsgInfo            TMessage,
   @ConfirmationMsg    TMessage,
   @BusinessUnit       TBusinessUnit,
   @XMLResult          TXML        output)
as
  /*declare variables here..*/
  declare @vReturnCode           TInteger,
          @UserId                TUserId,

          @vSKUId                TRecordId,
          @vSKU                  TSKU,
          @vSKUDescription       TDescription,
          @vSKUUoM               TUoM,

          @vDestLocationId       TRecordId,
          @vDestLocation         TLocation,
          @vDestZone             TLookUpCode,
          @vDestZoneDesc         TDescription,
          @vDestLocationType     TTypeCode,
          @vDestLocStorageType   TTypeCode,

          @vLPNId                TRecordId,
          @vLPN                  TLPN,
          @vLPNInnerPacks        TInnerPacks,
          @vLPNQuantity          TQuantity,
          @vMinIPsToPA           TQuantity,
          @vMinQtyToPA           TQuantity,
          @vSecondaryLocQty      TQuantity,
          @vLPNOrderId           TRecordId,

          @vOrderType            TTypeCode,
          @vInnerPacks           TInnerPacks,
          @vQuantity             TQuantity,
          @vDefaultQty           TVarchar,

          @vConfirmQtyRequired   TFlag,
          @vConfirmPAToDiffLoc   TFlag,
          @vConfirmSKUEnable     TControlValue,
          @vConfirmQtyRequiredForUnitsPA
                                 TFlag,

          @vDefaultQtyStr        TControlValue,
          @vDisplayQty           TDescription,
          @vMsgInfo              TMessage,

          @vXmlLPNInfo           xml,
          @vXmlOptions           xml,
          @vXmlMessage           xml;
begin /* pr_Putaway_PALPNResponse */
  /* Initialize the variable */
  select @vConfirmQtyRequired           = dbo.fn_Controls_GetAsString('Putaway', 'ConfirmQtyRequired', 'N', @BusinessUnit, @UserId),
         @vConfirmQtyRequiredForUnitsPA = dbo.fn_Controls_GetAsString('Putaway', 'ConfirmQtyRequiredForUnitsPA', 'N', @BusinessUnit, @UserId),
         @vConfirmPAToDiffLoc           = dbo.fn_Controls_GetAsString('Putaway', 'ConfirmPAToDiffLoc', 'Y', @BusinessUnit, @UserId),
         @vDefaultQtyStr                = dbo.fn_Controls_GetAsString('Putaway', 'DefaultQty', 'LPNQty'/* LPN Qty */, @BusinessUnit, @UserId);

  /* Get LPN Info */
  select @vLPNId         = LPNId,
         @vLPN           = LPN,
         @vLPNInnerPacks = InnerPacks,
         @vLPNQuantity   = Quantity,
         @vLPNOrderId    = OrderId
  from LPNs
  where (LPNId = @PALPNId);

  /* Get Order Details here */
  select @vOrderType = OrderType
  from OrderHeaders
  where (OrderId = @vLPNOrderId);

  /* Get Location Info */
  select @vDestLocationId     = LocationId,
         @vDestLocation       = Location,
         @vDestLocationType   = LocationType,
         @vDestLocStorageType = StorageType,
         @vDestZone           = PutawayZone,
         @vDestZoneDesc       = PutawayZoneDesc
  from vwLocations
  where (LocationId = @DestLocId);

  /* Get SKU Info */
  select @vSKUId          = SKUId,
         @vSKU            = SKU,
         @vSKUDescription = Description,
         @vSKUUoM         = UoM
  from SKUs
  where (SKUId = @PASKUId);

  /* If the DestLocation is a picklane & it is Replenish PA */
  if (@vDestLocationType = 'K'/* Picklane */) and (@vOrderType in ('R', 'RU', 'RP'))  -- DestLocationtype would be null if LPN does not alreaady have destination
    select @vConfirmSKUEnable = dbo.fn_Controls_GetAsString('ReplenishPutaway', 'ConfirmSKUEnable', 'N' /* NOt Required  */,  @BusinessUnit, @UserId);
  else
    select @vConfirmSKUEnable = dbo.fn_Controls_GetAsString('Putaway', 'ConfirmSKUEnable', 'N' /* NOt Required  */,  @BusinessUnit, @UserId);

  /* Default Qty considering config as well as IPs on from LPN */
  select @vDefaultQty = case when @vDefaultQtyStr = 'MinQtyToPA' and @vLPNInnerPacks > 0 then @vMinIPsToPA
                             when @vDefaultQtyStr = 'MinQtyToPA' and @vMinQtyToPA > 0 then @vMinQtyToPA
                             when @vLPNInnerPacks > 0 then @vLPNInnerPacks
                             else @vLPNQuantity
                        end;

  /* if LPN Qty is greater than zero and system has to prompt response then,
     build result xml which will be used by RF to display LPN info
     if PromptResponse is 'No' then only display confirmation msg */
  if (@vLPNQuantity > 0)
    begin
      set @vXmlLPNInfo = (select @vLPN                          as LPN,
                                 @vSKU                          as SKU,
                                 @vSKUDescription               as SKUDescription,
                                 @vSKUUoM                       as SKUUoM,
                                 @vLPNInnerPacks                as InnerPacks,
                                 @vLPNQuantity                  as Quantity,
                                 @DisplayQty                    as DisplayQty,
                                 coalesce(nullif(@vDefaultQty, 0), '')
                                                                as DefaultQty,
                                 coalesce(@vDestZoneDesc, @vDestZone)
                                                                as DestZone,
                                 @vDestLocation                 as DestLocation,
                                 case
                                   when @vLPNInnerPacks > 0 then 'P' /* cases */
                                   else left(@vDestLocStorageType, 1)
                                 end                            as PutawayMode /* expected values (L/U) */
                          for xml raw('LPNINFO'), elements );

      set @vXmlOptions = (select @vConfirmQtyRequired           as ConfirmQtyRequired,
                                 @vConfirmQtyRequiredForUnitsPA as ConfirmQtyRequiredForUnitsPA,
                                 @vConfirmPAToDiffLoc           as ConfirmPAToDiffLoc,
                                 @PartialPutaway                as PartialPutaway,
                                 @PromptScreen                  as PromptScreen,
                                 @vConfirmSKUEnable             as ConfirmSKUEnable
                          for xml raw('OPTIONS'), elements );
    end

  set @vXmlMessage = (select @MsgInfo            as MsgInformation,
                             @ConfirmationMsg    as ConfirmationMsg
                      for xml raw('MESSAGE'), elements );

  set @XMLResult = '<PUTAWAYLPNDETAILS>' +
                       cast(coalesce(@vXmlLPNInfo, '') as varchar(max)) +
                       cast(coalesce(@vXmlOptions, '') as varchar(max)) +
                       cast(coalesce(@vXmlMessage, '') as varchar(max)) +
                   '</PUTAWAYLPNDETAILS>';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Putaway_PALPNResponse */

Go
