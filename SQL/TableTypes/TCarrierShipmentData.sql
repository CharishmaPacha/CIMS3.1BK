/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TCarrierShipmentData: Added OrderDate and ReceiverTaxId (CIMSV3-2760)
  TCarrierShipmentData: Added OrderDate, CarrierOptions, TotalPackages, LabelFormatType, LabelStockType etc, (JLFL-320)
  2022/12/23  VS      TCarrierShipmentData: Added PackageWeight and Volume (OBV3-1363)
  2022/11/18  VS      TCarrierShipmentData: Added ShipToInfo (OBV3-1447)
  2022/11/17  AY      TCarrierShipmentData: To hold several pieces of data for carrier integration (OBV3-1447)
  Create Type TCarrierShipmentData as Table (
  grant references on Type:: TCarrierShipmentData to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Data that is to be sent to the Carrier or data that is needed to evaluate
   the information to be sent to Carrier */
Create Type TCarrierShipmentData as Table (
  Carrier                    TCarrier,
  ShipVia                    TShipVia,
  CarrierServiceCode         TName,
  ServiceClass               TDescription,
  SpecialServices            TDescription,
  CarrierPackagingType       TDescription, -- ShipVia.CarrierPackagingType
  StandardAttributes         TXML,
  CarrierInterface           TTypeCode,
  ShipmentType               TTypeCode,
  ManifestAction             TDescription,
  ClearanceFacility          TControlValue,
  --  Mail Innovations Info
  MICostCenter               TDescription,
  MIPackageId                TDescription,
  MailerId                   TDescription,
  -- SmartPost Info
  SmartPostIndiciaType       TDescription,
  SmartPostHubId             TDescription,
  SmartPostEndorsement       TDescription,
  -- LPN Info
  LPNId                      TRecordId,
  LPN                        TLPN,
  --Order info
  OrderId                    TRecordId,
  PickTicket                 TPickTicket,
  OrderDate                  TDateTime,
  FutureShipDate             TDateTime,
  FreightTerms               TDescription,
  TotalPackages              TCount,
  CarrierOptions             TDescription,
  -- ShipTo Info
  ShipToId                   TContactRefId,
  ShipToState                TState,
  ShipToCountry              TCountry,
  ShipToAddressRegion        TAddressRegion,
  SoldToId                   TContactRefId,
  -- Shipper Info
  SenderTaxId                TString,
  -- Billing info
  BillToContactType          TContactType,
  BillToContact              TContactRefId,
  -- Recipient Info
  ReceiverTaxId              TString,
  -- Labels
  LabelFormatType            TTypeCode,
  LabelStockType             TTypeCode,
  LabelImageType             TTypeCode,
  LabelRotation              TTypeCode,
  -- Documents
  InternationalDocsRequired  TVarchar,   -- CSV of DocumentTypes CI, CN22 etc.
  /* CI Info */
  CIComments                 TString,
  CIDeclaration              TString,
  CISpecialInstructions      TString,
  PaymentTerms               TString,    -- Not used by FedEx
  Purpose                    TString,
  TermsOfSale                TString,
  CurrencyCode               TTypeCode,
  CustomsValue               TString
);

grant references on Type:: TCarrierShipmentData to public;

Go
