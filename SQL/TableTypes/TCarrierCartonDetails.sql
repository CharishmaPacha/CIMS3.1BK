/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/05/29  VS      TCarrierCartonDetails: Table Type added (FBV3-1752)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
Create Type TCarrierCartonDetails as Table (
    LPNId             TRecordId,
    LPN               TLPN,

    PackageLength     TLength,
    PackageWidth      TLength,
    PackageHeight     TLength,
    PackageWeight     TWeight,
    PackageVolume     TVolume,
    unique(LPN)
);

grant references on Type:: TCarrierCartonDetails  to public;

Go