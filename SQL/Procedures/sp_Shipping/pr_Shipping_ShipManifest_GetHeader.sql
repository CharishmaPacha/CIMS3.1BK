/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/21  PHK     pr_Shipping_ShipManifest_GetHeader: Made changes to round TotalLPNWeight (BK-595)
  2021/04/27  SAK     pr_Shipping_ShipManifest_GetDetails: Added InventoryClass1,InventoryClass2,InventoryClass3 field to show in RDLC's,
                      pr_Shipping_ShipManifest_GetHeader:  Added SealNumber field (HA-2674)
  2021/04/13  AY      pr_Shipping_ShipManifest_GetHeader: Add more fields, optimize (HA-2415)
  2021/04/06  RV      pr_Shipping_ShipManifest_GetDetails: Added new parameter xml input to get the action and
                        based upon the action summarize the details
                      pr_Shipping_ShipManifest_GetHeader: Added new parameter for future purpose
                      pr_Shipping_ShipManifest_GetData: Changed callers to include the xml input (HA-2401)
  2021/03/02  PHK     pr_Shipping_ShipManifest_GetHeader: Changes to get DesiredShipDate from Loads (HA-2107)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_ShipManifest_GetHeader') is not null
  drop Procedure pr_Shipping_ShipManifest_GetHeader;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_ShipManifest_GetHeader: Returns all the info associated with the
    Load and it's Cartons to print a shipping manifest.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_ShipManifest_GetHeader
  (@xmlInput        xml,
   @LoadId          TLoadId      = null,
   @ShipmentId      TShipmentId,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @SMHeaderxml     TXML output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @Message           TDescription,
          @vDebug            TFlags = 'N',

          @Reportsxml        varchar(max),
          @vEntityId         TRecordId,
          @vEntityKey        TEntityKey,
          @vEntityType       TEntity,
          @vNoteType         TTypeCOde,
          @vVisibleFlags     TFlags,
          @vPrintFlags       TFlags,
          @vNotes            TVarchar,

          @vLoadId           TLoadId,
          @vLoadNumber       TLoadNumber,
          @vShipmentId       TShipmentId,
          @vOrderId          TRecordId,
          @vReport           TResult,
          @vPickedBy         TUserId,
          @vNumOrders        TCount,
          @vNumPallets       TCount,
          @vNumLPNs          TCount,
          @vNumPackages      TCount,
          @vNumUnits         TCount,

          @vTotalLPNWeight   TInteger,
          @vPalletTareWeight TInteger,
          @vShipmentWeight   TInteger,

          @vShipVia          TShipVia,
          @vShipViaDesc      TDescription,
          @vSCAC             TSCAC,
          @vCarrier          TCarrier,

          @vEntity           varchar(max),
          @Resultxml         varchar(max);

begin /* pr_Shipping_ShipManifest_GetHeader */
  select @ReturnCode   = 0,
         @Messagename  = null;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  /* To get the PickedBy field value into variable */
  select top 1 @vPickedBy = LD.PickedBy
  from LPNs          L
    join LPNDetails  LD on (L.LPNId = LD.LPNId)
  where (L.ShipmentId = @ShipmentId);

  /* To get input parameters of function based on ShipmentId */
  select @vEntityId     = SH.LoadId,
         @vEntityKey    = L.LoadNumber,
         @vEntityType   = 'Load',
         @vNumOrders    = SH.NumOrders,
         @vNumPallets   = SH.NumPallets,
         @vNumLPNs      = SH.NumLPNs,
         @vNumPackages  = SH.NumPackages,
         @vNumUnits     = SH.NumUnits,
         @vShipVia      = coalesce(L.ShipVia, SH.ShipVia)
  from Shipments SH
    join Loads  L on (SH.LoadId  = L.LoadId)
  where (SH.ShipmentId = @ShipmentId);

  exec pr_Notes_GetNotesForEntity @vEntityId, @vEntityKey, @vEntityType, 'SI', null /* Visible flags */,
                                  null /* Pring Flags */, @BusinessUnit, @UserId, @vNotes output;

  /* Get Ship via info */
  select @vShipViaDesc = SV.Description,
         @vCarrier     = Carrier,
         @vSCAC        = SCAC
  from ShipVias SV
  where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

  /* Shipment Weight = Weight of LPNs + Tare Weight of Pallets */
  select @vTotalLPNWeight = Round(sum(LPNWeight), 0)
  from LPNs
  where (ShipmentId = @ShipmentId);

  /* Get the PalletTareWeight and compute ShipmentWeight accordingly */
  select @vPalletTareWeight = dbo.fn_Controls_GetAsInteger('BoL', 'PalletTareWeight', '35' /* lbs */, @BusinessUnit, null);
  select @vShipmentWeight = coalesce(@vNumPallets, 0) * @vPalletTareWeight + @vTotalLPNWeight;

  /* Shipping Manifest Header for the Load */
  set @SMHeaderxml = (select SH.LoadId,
                             L.LoadNumber       LoadNumber,
                             SH.ShipmentId      ShipmentId,
                             coalesce(L.BoLCID, B.ProNumber, B.VICSBoLNumber)
                                                BoLNumber,
                             B.VICSBoLNumber    VICSBoLNumber,
                             coalesce(B.ProNumber, L.ProNumber)
                                                ProNumber,
                             L.ShippedDate      ShippedDate,
                             L.DesiredShipDate  DesiredShipDate,
                             L.TrailerNumber    TrailerNumber,
                             L.SealNumber       SealNumber,
                             L.ClientLoad       ClientLoad,
                             /* Ship From Address */
                             SH.ShipFrom        ShipFrom,
                             SHFR.Name          ShipFromName,
                             SHFR.AddressLine1  ShipFromAddressLine1,
                             SHFR.AddressLine2  ShipFromAddressLine2,
                             SHFR.City          ShipFromCity,
                             SHFR.State         ShipFromState,
                             SHFR.Country       ShipFromCountry,
                             SHFR.Zip           ShipFromZip,
                             SHFR.CityStateZip  ShipFromCityStateZip,
                             SHFR.PhoneNo       ShipFromPhoneNo,
                             /* Sold To Address */
                             SH.SoldTo          SoldToId,
                             STA.Name           SoldToCustomerName,
                             STA.AddressLine1   SoldToAddressLine1,
                             STA.AddressLine2   SoldToAddressLine2,
                             STA.City           SoldToCity,
                             STA.State          SoldToState,
                             STA.Country        SoldToCountry,
                             STA.Zip            SoldToZip,
                             STA.CityStateZip   SoldToCityStateZip,
                             /* Ship To Address */
                             SH.ShipTo          ShipToId,
                             SHTA.Name          ShipToCustomerName,
                             SHTA.AddressLine1  ShipToAddressLine1,
                             SHTA.AddressLine2  ShipToAddressLine2,
                             SHTA.City          ShipToCity,
                             SHTA.State         ShipToState,
                             SHTA.Country       ShipToCountry,
                             SHTA.Zip           ShipToZip,
                             SHTA.CityStateZip  ShipToCityStateZip,
                             /* Ship Via */
                             @vShipVia          ShipVia,
                             @vShipViaDesc      ShipViaDesc,
                             @vSCAC             SCAC,
                             @vCarrier          Carrier,
                             /* Other info */
                              'Apparel'         Description,
                             @vNotes            ShippingInstructions,
                             /* Load UDFs */
                             L.UDF1             LD_UDF1, /* PalletDimensions */
                             L.UDF2             LD_UDF2,
                             L.UDF3             LD_UDF3, /* CheckedBy */
                             L.UDF4             LD_UDF4,
                             L.UDF5             LD_UDF5,
                             L.UDF6             LD_UDF6,
                             L.UDF7             LD_UDF7,
                             L.UDF8             LD_UDF8,
                             L.UDF9             LD_UDF9,
                             L.UDF10            LD_UDF10,
                             /* Counts */
                             @vNumOrders        NumOrders,
                             @vNumPallets       NumPallets,
                             @vNumLPNs          NumLPNs,
                             @vNumPackages      NumPackages,
                             @vNumUnits         NumUnits,
                             @vShipmentWeight   TotalWeight,
                             /* Additional info */
                             @vPickedBy         PickedBy,
                             /* Shipping Manifest Report UDFs */
                             ''                 SMR_UDF1,
                             ''                 SMR_UDF2,
                             ''                 SMR_UDF3,
                             ''                 SMR_UDF4,
                             ''                 SMR_UDF5,
                             ''                 SMR_UDF6,
                             ''                 SMR_UDF7,
                             ''                 SMR_UDF8,
                             ''                 SMR_UDF9,
                             ''                 SMR_UDF10
                      from Shipments SH
                        left outer join Loads              L on (SH.LoadId         = L.LoadId)
                        left outer join Contacts         STA on (STA.ContactType = 'C') and
                                                                (STA.ContactRefId  = SH.SoldTo)  /* Sold To Address */
                        cross apply dbo.fn_Contacts_GetShipToAddress (null /* Order Id */, SH.ShipTo) SHTA /* Ship To Address */
                        left outer join Contacts        SHFR on (SHFR.ContactRefId = SH.ShipFrom) and  /* Ship From Address */
                                                                (SHFR.ContactType  = 'F' /* Ship From */)
                        left outer join BoLs               B on (SH.BoLId          = B.BoLId)
                      where (SH.ShipmentId = @ShipmentId)
                      for xml raw('SHIPPINGMANIFESTHEADER'), elements);

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_ShipManifest_GetHeader */

Go
