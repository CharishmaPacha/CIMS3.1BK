/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/01  AY      BolOrderDetails/BoLCarrierDetails: Added new reference fields/renamed UDFs (FB-2225)
  2012/12/07  TD      Added new tables BoL, BoLOrderDetail, BoLCarrierDetails.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: BoLCarrierDetails
    Details Table to capture the Detailed information - This information will be
      the one to be used by Bill Of Lading Report

  Description -- List of NMFC Codes with Descriptions should be in LookUps, and this
         should be filled up accordingly
------------------------------------------------------------------------------*/
Create Table BoLCarrierDetails (

    BoLCarrierDetailId       TRecordId      identity (1,1) not null,
    BoLId                    TRecordId                     not null,

    HandlingUnitQty          TQuantity,
    HandlingUnitType         TTypeCode,
    PackageQty               TQuantity,
    PackageType              TTypeCode,

    Volume                   TVolume        default 0.0,
    Weight                   TWeight        default 0.0,

    Hazardous                TFlag          default 'N',
    CommDescription          TDescription,
    NMFCCode                 TLookUpCode,
    CommClass                TCategory,

    SortSeq                  TSortSeq       not null default 0,
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

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

  constraint pkBoLCarrierDetails_BoLCarrierDetailId PRIMARY KEY (BoLCarrierDetailId)
);

create index ix_BoLCarrierDetails_BolId          on BoLCarrierDetails (BoLId);

Go
