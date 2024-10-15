/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/29  VS      TCarrierPackageLabels: Table Type added (FBV3-1752)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
Create Type TCarrierPackageLabels as Table (
    LPNId                    TRecordId,
    LPN                      TLPN,

    PackageSequenceNumber    Tinteger,
    TrackingNumber           TTrackingNo,
    PackageDocumentsJSON     TNVarchar,
    LabelType                TString,
    LabelImageType           TVarchar,
    LabelImage               TVarchar,
    Carrier                  TCarrier,
    RotatedLabelImage        TVarchar,
    ZPLLabel                 TVarchar,
    LabelRotation            TDescription,
    RecordId                 TRecordId
);

grant references on Type:: TCarrierPackageLabels  to public;

Go