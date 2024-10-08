/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TBoLCarrierDetails and TBoLCustomerOrderDetails: new reference fields (FB-2225/HA-1954)
  TBoLCarrierDetails.
  2012/12/30  AY      Added TBoLCarrierDetails and TBoLCustomerOrderDetails
  Create Type TBoLCarrierDetails as Table (
  Grant References on Type:: TBoLCarrierDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TBoLCarrierDetails as Table (
    HandlingUnitType         TTypeCode,
    HandlingUnitQty          TQuantity      DEFAULT 0,
    PackageType              TTypeCode,
    PackageQty               TQuantity,
    Weight                   TInteger       DEFAULT 0,
    Hazardous                TFlag          DEFAULT 'N',
    CommDescription          TDescription,
    NMFCCode                 TTypeCode,
    CommClass                TCategory,
    SortSeq                  TInteger       DEFAULT 0,
    BCDGroupCriteria         TCategory,

    BCD_Reference1           TReference,
    BCD_Reference2           TReference,
    BCD_Reference3           TReference,
    BCD_Reference4           TReference,
    BCD_Reference5           TReference,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,
    PageNumber               integer
);

Grant References on Type:: TBoLCarrierDetails to public;

Go
