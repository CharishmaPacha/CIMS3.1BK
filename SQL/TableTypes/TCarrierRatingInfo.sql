/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/29  VS      TCarrierRatingInfo: Table Type added (FBV3-1752)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
Create Type TCarrierRatingInfo as Table (
    LPNId                    TRecordId,
    LPN                      TLPN,

    PackageSequenceNumber    TInteger,
    TrackingNumber           TTrackingNo,
    PackageRatingJSON        TNVarchar,
    RateType                 TString,
    RatedWeightMethod        TString,
    BillingWeight_Value      TFloat,
    DimWeight_Value          TFloat,
    BaseCharge_Amount        TMoney,
    NetFreight_Amount        TMoney,
    TotalSurcharges_Amount   TMoney,
    NetCharge_Amount         TMoney

);

grant references on Type:: TCarrierRatingInfo  to public;

Go