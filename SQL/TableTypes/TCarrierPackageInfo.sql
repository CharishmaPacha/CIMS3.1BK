/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/29  VS      TCarrierPackageInfo: Table Type added (FBV3-1752)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
Create Type TCarrierPackageInfo as Table (
    LPNId                    TRecordId,
    LPN                      TLPN,

    PackageSequenceNumber    TInteger,
    TrackingNumber           TTrackingNo,
    MasterTrackingNo         TTrackingNo,
    Reference1Type           TString,
    Reference1Value          TString,
    Reference2Type           TString,
    Reference2Value          TString,
    Reference3Type           TString,
    Reference3Value          TString,
    IsUsDomestic             TFlags,
    Carrier                  TCarrier,
    RecordId                 TRecordId
);

grant references on Type:: TCarrierPackageInfo  to public;

Go