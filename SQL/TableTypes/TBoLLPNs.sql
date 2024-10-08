/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  RV      TBoLLPNs: Added BOD_ShipperInfo (HA-2390)
  2021/02/02  AY/RT   TBoLLPNs: Included Reference feilds and Added to summarize LPNs on a BoL
  Create Type TBoLLPNs as Table (
  Grant References on Type:: TBoLLPNs to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TBoLLPNs as Table (
    BoLId                    TRecordId,
    LPNId                    TRecordId,
    OrderId                  TRecordId,
    ShipmentId               TRecordId,
    CustPO                   TCustPO,
    ShipToId                 TShipToId,
    ShipToStore              TShipToStore,
    PalletId                 TRecordId,
    InnerPacks               TInnerPacks,
    Quantity                 TQuantity,
    Packages                 TInteger,
    LPNWeight                TWeight      DEFAULT 0,
    LPNVolume                TVolume      DEFAULT 0,

    BOD_GroupCriteria        TCategory,
    BOD_Reference1           TReference,
    BOD_Reference2           TReference,
    BOD_Reference3           TReference,
    BOD_Reference4           TReference,
    BOD_Reference5           TReference,
    BOD_ShipperInfo          TDescription,

    BCD_GroupCriteria        TCategory,
    BCD_Reference1           TReference,
    BCD_Reference2           TReference,
    BCD_Reference3           TReference,
    BCD_Reference4           TReference,
    BCD_Reference5           TReference,

    BL_UDF1                  TUDF,
    BL_UDF2                  TUDF,
    BL_UDF3                  TUDF,
    BL_UDF4                  TUDF,
    BL_UDF5                  TUDF,

    RecordId                 TRecordId
);

Grant References on Type:: TBoLLPNs to public;

Go
