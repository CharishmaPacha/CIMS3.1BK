/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/27  PHK     TPalletShipLabelData: Added NumCases (S2GMI-88)
  2019/01/11  RT/PHK  Added ShipFromPhoneNo, ShipToCountry, NumLPNs and PalletSeqNo, ClientLoad, LoadNumber,SpecialInstructions and Pallet UDFs in TPalletShipLabelData (S2GMI-39)
  2018/04/30  RV      Added ShipFromAddr2 to TPalletShipLabelData (S2G-765)
  2018/04/27  RV      Added TPalletShipLabelData (S2G-686)
  Create Type TPalletShipLabelData as Table (
  Grant References on Type:: TPalletShipLabelData to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TPalletShipLabelData as Table (
    ShipFromName             TName,
    ShipFromAddr1            TAddressLine,
    ShipFromAddr2            TAddressLine,
    ShipFromCity             TCity,
    ShipFromState            TState,
    ShipFromZip              TZip,
    ShipFromCountry          TCountry,
    ShipFromCSZ              TCityStateZip,
    ShipFromPhoneNo          TPhoneNo,
    /* Mark for information */
    MarkForName              TName,
    MarkForReference2        TDescription,
    MarkForAddr1             TAddressLine,
    MarkForAddr2             TCity,
    MarkForCity              TState,
    MarkForState             TZip,
    MarkForZip               TCountry,
    MarkForCSZ               TCityStateZip,
    /* ShipTo information */
    ShipToName               TName,
    ShipToReference2         TDescription,
    ShipToAddr1              TAddressLine,
    ShipToAddr2              TCity,
    ShipToCity               TState,
    ShipToState              TZip,
    ShipToZip                TCountry,
    ShipToCountry            TCountry,
    ShipToCSZ                TCityStateZip,
    /* Shipvia Info */
    ShipVia                  TShipVia,
    ShipViaDesc              TDescription,

    /* Order header Info */
    PickTicket               TPickTicket,
    CustPO                   TCustPO,
    CustPOsOnPallet          TVarchar,      /* stuff all the CustPOs on Pallet */
    OH_UDF1                  TUDF,
    OH_UDF2                  TUDF,
    OH_UDF3                  TUDF,
    VendorId                 TVendorId,
    /* Order Detail Info */
    HostOrderLine            TInteger,
    SKU                      TSKU,
    CustSKU                  TSKU,
    /* Load Info */
    Carrier                  TCarrier,
    BoL                      TBoL,
    LoadNumber               TLoadNumber,
    ClientLoad               TLoadNumber,
    ProNumber                TProNumber,
    LD_UDF1                  TUDF,
    /* Pallet Info */
    Pallet                   TPallet,
    NumLPNs                  TCount,
    NumCases                 TCount,
    NumPallets               TCount,
    PalletSeqNo              TRecordId,
    UCCBarcode               TBarcode,
    TotalCases               TInteger,
    TotalUnits               TInteger,
    TotalWeight              TWeight,
    TotalVolume              TVolume,

    ExpiryDate               TVarChar,
    SKUDescription           TDescription,
    UPC                      TUPC,
    PickDate                 TDate,
    Picker                   TUserId,
    /* Other */
    SpecialInstructions      TVarChar,
    /* UDFs */
    PT_UDF1                  TUDF,
    PT_UDF2                  TUDF,
    PT_UDF3                  TUDF,
    PT_UDF4                  TUDF,
    PT_UDF5                  TUDF,
    PT_UDF6                  TUDF,
    PT_UDF7                  TUDF,
    PT_UDF8                  TUDF,
    PT_UDF9                  TUDF,
    PT_UDF10                 TUDF
);

Grant References on Type:: TPalletShipLabelData to public;

Go
