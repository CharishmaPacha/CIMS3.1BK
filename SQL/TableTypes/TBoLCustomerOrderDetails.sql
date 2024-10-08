/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  TBoLCarrierDetails and TBoLCustomerOrderDetails: new reference fields (FB-2225/HA-1954)
  2018/06/08  VM      TBoLCustomerOrderDetails: Included UDF1..5 (S2G-923)
  2013/01/04  TD      Added PageNumber to the TBoLCustomerOrderDetails,
  2012/12/30  AY      Added TBoLCarrierDetails and TBoLCustomerOrderDetails
  Create Type TBoLCustomerOrderDetails as Table (
  Grant References on Type:: TBoLCustomerOrderDetails to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TBoLCustomerOrderDetails as Table (
    CustomerOrderNumber      varchar(max),
    NumPackages              TQuantity      DEFAULT 0,
    Weight                   TWeight        DEFAULT 0.0,
    Palletized               TFlag,
    AdditionalShipperInfo    varchar(max),
    SortSeq                  TInteger       DEFAULT 0,
    PageNumber               TInteger,
    BODGroupCriteria         TCategory,

    BOD_Reference1           TReference,
    BOD_Reference2           TReference,
    BOD_Reference3           TReference,
    BOD_Reference4           TReference,
    BOD_Reference5           TReference,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF
);

Grant References on Type:: TBoLCustomerOrderDetails to public;

Go
