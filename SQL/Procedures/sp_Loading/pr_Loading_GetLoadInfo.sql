/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/21  TK      pr_Shipping_GetLoadInfo renamed to pr_Loading_GetLoadInfo and migrated from sp_Shipping (S2GCA-970)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loading_GetLoadInfo') is not null
  drop Procedure pr_Loading_GetLoadInfo;
Go
/*------------------------------------------------------------------------------
  pr_Loading_GetLoadInfo:

  Fluid Loading is when LPNs/Pallets are not added to the load first and as they
  are scanned during the RF Loading, they get added to the load. Normal scenario
  is when Orders (and LPNs) are added to Load and
------------------------------------------------------------------------------*/
Create Procedure pr_Loading_GetLoadInfo
  (@LoadId        TRecordId,
   @xmlResult     xml output)
as
  declare @ReturnCode               TInteger,
          @MessageName              TMessageName,
          @Message                  TDescription,

          @vDynamicLoading          TControlValue,

          /* Load variables */
          @vLoadId                  TRecordId,
          @vLoadNumber              TLoadNumber,
          @vDockLocation            TLocation,
          @vShipToId                TShipToId,
          @vShipToName              TName,
          @vLoadWeight              TWeight,
          @vLoadVolume              TVolume,
          @vTrailerNumber           TTrailerNumber,
          @vDesiredShipDate         TDateTime,

          /* Display and Count variables */
          @vPalletsOnLoad           TCount,
          @vLPNsOnLoad              TCount,
          @vPalletsLoaded           TCount,
          @vLPNsLoaded              TCount,
          @vAvailablePallets        TCount,
          @vAvailableLPNs           TCount,
          @vFluidLoading            TControlValue,
          @vBusinessUnit            TBusinessUnit,
          @vAvailableToLoadDisplay  TVarchar,
          @vLoadedCountDisplay      TVarchar,
          @vTotalWtVolDisplay       TVarchar;
begin
  SET NOCOUNT ON;

  /* Get the Load Info */
  select @vLoadId          = LoadId,
         @vLoadNumber      = LoadNumber,
         @vDockLocation    = DockLocation,
         @vShipToId        = ShipToId,
         @vLoadWeight      = Weight,
         @vLoadVolume      = Volume,
         @vTrailerNumber   = TrailerNumber,
         @vDesiredShipDate = DesiredShipDate,
         @vBusinessUnit    = BusinessUnit
  from  Loads
  where (LoadId = @LoadId);

  select @vFluidLoading = dbo.fn_Controls_GetAsString('Loading', 'FluidLoading', 'N', @vBusinessUnit, null);

  /* Get the LPNs counts which are on the load */
  select @vLPNsOnLoad    = count(LPN),
         @vLPNsLoaded    = sum(case when Status in ('L') then 1 else 0 end)
  from LPNs
  where (LoadId = @vLoadId);

  select @vPalletsOnLoad = count(*),
         @vPalletsLoaded = sum(case when Status in ('L') then 1 else 0 end)
  from Pallets
  where (LoadId = @vLoadId);

  /* Get counts of LPNs and Pallets that are not on this load and that
     are available to be loaded. If Fluid loading, then we need to count
     all LPNs/Pallets which are ready to be loaded (picked, staged) and
     for the same ShipTo as the Load */
  if (@vFluidLoading = 'Y')
    select @vAvailablePallets = count(distinct PalletId),
           @vAvailableLPNs    = count(LPN)
    from LPNs L
      join OrderHeaders OH on (L.OrderId = OH.OrderId)
    where (L.Status in ('K', 'G' /* Picked, Staged */)) and
          (OH.ShipToId = @vShipToId) and
          (L.LoadId <> @vLoadId);
  else
    select @vAvailablePallets = @vPalletsOnLoad - @vPalletsLoaded,
           @vAvailableLPNs    = @vLPNsOnLoad - @vLPNsLoaded;

  /* Get the ShipTo Name */
  select @vShipToName = Name
  from Contacts
  where (ContactRefId = @vShipToId) and
        (ContactType  = 'S' /* ShipTo */);

  /* Get the data to the variables to build the response XML */
  select @vLoadedCountDisplay     = Case
                                      when (@vLPNsLoaded = 0) then 'None'
                                      when (@vPalletsLoaded = 0) then dbo.fn_StrUom(@vLPNsLoaded, 'LPN')
                                      else coalesce((nullif(dbo.fn_StrUom(@vPalletsLoaded, 'Pallet'), '') + ', '), '') + dbo.fn_StrUom(@vLPNsLoaded, 'LPN')
                                    end,
         @vAvailableToLoadDisplay = Case
                                      when (@vAvailableLPNs = 0) then 'None'
                                      when (@vAvailablePallets = 0) then dbo.fn_StrUom(@vAvailableLPNs, 'LPN')
                                      else coalesce((nullif(dbo.fn_StrUom(@vAvailablePallets, 'Pallet'), '') + ', '), '') + dbo.fn_StrUom(@vAvailableLPNs, 'LPN')
                                    end,
         @vTotalWtVolDisplay      = cast(coalesce(@vLoadWeight, 0) as varchar(20)) +' lbs' +', '+  cast(coalesce(@vLoadVolume, 0) as varchar(20))+' cu. ft.';

  /* Build the Load Reponse XML */
  select @xmlResult = (select coalesce(@vLoadId, '')                 as LoadId,
                              coalesce(@vLoadNumber, '')             as LoadNumber,
                              coalesce(@vDockLocation, '')           as DockLocation,
                              coalesce(@vShipToName, @vShipToId, '') as ShipTo,
                              coalesce(@vLoadedCountDisplay, '')     as LoadedDisplay,
                              coalesce(@vAvailableToLoadDisplay, '') as AvailableDisplay,
                              coalesce(@vTotalWtVolDisplay, '')      as TotalWtVolDisplay,
                              cast(@vLoadWeight as varchar(20))      as Weight,
                              cast(@vLoadVolume as varchar(20))      as Volume,
                              coalesce(@vTrailerNumber, '')          as TrailerNumber,
                              cast(@vDesiredShipDate as varchar(11)) as DesiredShipDate
                       FOR XML RAW('LoadInfo'), TYPE, ELEMENTS);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  return(coalesce(@ReturnCode, 0));
end /* pr_Loading_GetLoadInfo */

Go
