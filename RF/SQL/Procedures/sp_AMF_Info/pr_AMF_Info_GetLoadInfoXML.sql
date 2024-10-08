/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  RKC     pr_AMF_Info_GetLoadInfoXML: Changes to get the Loaded and avilable Units, LPNs, Pallets counts (HA-2862)
  2021/04/26  AY      pr_AMF_Info_GetLoadInfoXML: Return more fields (HA-2675)
  2021/03/19  RIA     pr_AMF_Info_GetLoadInfoXML: Added (HA-2347)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Info_GetLoadInfoXML') is not null
  drop Procedure pr_AMF_Info_GetLoadInfoXML;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Info_GetLoadInfoXML: Procedure to get all the info for a Load
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Info_GetLoadInfoXML
  (@LoadId              TRecordId,
   @IncludeDetails      TFlags = 'N',
   @Operation           TOperation = null,
   @LoadInfoXML         TXML       = null output, -- var char in XML format
   @LoadDetailsXML      TXML       = null output,
   @xmlLoadInfo         xml        = null output, -- true xml data type
   @xmlLoadDetails      xml        = null output
   )
as
  declare @vRecordId                  TRecordId,

          /* Display and Count variables */
          @vPalletsOnLoad             TCount,
          @vPalletsLoaded             TCount,
          @vLPNsOnLoad                TCount,
          @vLPNsLoaded                TCount,
          @vUnitsLoaded               TCount,
          @vTotalUnits                TCount,
          @vLPNsLoadedCountDisplay    TVarchar,
          @vUnitsLoadedCountDisplay   TVarchar,
          @vPalletsLoadedCountDisplay TVarchar,

          @vxmlLoadInfo               xml,
          @vxmlLoadDetails            xml;
begin /* pr_AMF_Info_GetLoadInfoXML */

  /* Get the LPNs counts for the load */
  select @vPalletsOnLoad = count(distinct PalletId),
         @vLPNsOnLoad    = count(*),
         @vTotalUnits    = sum(Quantity),
         @vPalletsLoaded = count(distinct case when Status in ('L') then PalletId else null end),
         @vLPNsLoaded    = sum(case when Status in ('L') then 1 else 0 end),
         @vUnitsLoaded   = sum(case when Status in ('L') then Quantity else 0 end)
  from LPNs
  where (LoadId = @LoadId);

  -- /* Get the Pallets counts that are loaded to the load */
  -- select @vPalletsOnLoad = count(*),
  --        @vPalletsLoaded = sum(case when Status in ('L') then 1 else 0 end)
  -- from Pallets
  -- where (LoadId = @LoadId);

  /* Get the data to the variables to build the response XML */
  select @vLPNsLoadedCountDisplay    = case
                                         when (@vLPNsOnLoad = 0) then 'None'
                                         else concat(@vLPNsLoaded, ' of ', @vLPNsOnLoad)
                                       end,
         @vPalletsLoadedCountDisplay = case
                                         when (@vPalletsOnLoad = 0) then 'None'
                                         else concat(@vPalletsLoaded, ' of ', @vPalletsOnLoad)
                                       end,
         @vUnitsLoadedCountDisplay   = case
                                         when (@vTotalUnits = 0) then 'None'
                                         else concat(@vUnitsLoaded, ' of ', @vTotalUnits)
                                       end

  /* Capture Load Information */
  select @vxmlLoadInfo = (select LoadId, LoadNumber, LoadType, LoadTypeDescription,
                                 Status, StatusDescription, RoutingStatus, RoutingStatusDesc,
                                 NumOrders, NumPallets, NumLPNs, NumUnits,
                                 @vPalletsLoadedCountDisplay PalletsLoaded, @vLPNsLoadedCountDisplay LPNsLoaded,
                                 @vUnitsLoadedCountDisplay  UnitsLoaded,
                                 NumPackages, Volume, Weight, LPNVolume,
                                 ShipToId, ShipToName, ShipToDesc, SoldToId,
                                 ShipVia, ShipViaDescription, ClientLoad,
                                 ProNumber, TrailerNumber, SealNumber, MasterTrackingNo,
                                 ShipFrom, Account, AccountName, MasterBoL,
                                 cast(DesiredShipDate as varchar(11)) DesiredShipDate, -- Format Apr 26 2021
                                 UDF1, UDF2, UDF3, UDF4, UDF5
                          from vwLoads
                          where (LoadId = @LoadId)
                          for xml raw('LoadInfo'), Elements);

  select @LoadInfoXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('LoadInfo_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlLoadInfo.nodes('/LoadInfo/*') as t(c)
  )
  select @LoadInfoXML = @LoadInfoXML + DetailNode from FlatXML;

  select @xmlLoadInfo = convert(xml, @LoadInfoXML);

  /* Get the Details: PL - Pallet List */
  if (@IncludeDetails = 'PL')
    select @vxmlLoadDetails = (select Pallet, LPNStatusDesc, ShipToName, CustPO,
                               count(*) as NumLPNs, Location
                               from vwLPNs
                               where (LoadId = @LoadId)
                               group by Pallet, LPNStatusDesc, ShipToName, CustPO, Location
                               order by ShipToName, CustPO, Pallet
                               for Xml Raw('LoadDetail'), elements XSINIL, Root('LoadDetails'));

  select @LoadDetailsxml = coalesce(convert(varchar(max), @vxmlLoadDetails), '');
end /* pr_AMF_Info_GetLoadInfoXML */

Go

