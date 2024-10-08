/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/03  AY      ukBoLOrderDetails_BoLId: Added Reference fields as Master BoL can have multiple POs on it (HA-1954)
  2021/01/31  AY      BoLOrderDetails: Add NumPackages (HA-1954)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: BoLOrderDetails
  Details Table to capture the Detailed information - This information will be
       the one to be used by Bill Of Lading Report
------------------------------------------------------------------------------*/
Create Table BoLOrderDetails (

    BoLOrderDetailId         TRecordId      identity (1,1) not null,
    BoLId                    TRecordId                     not null,

    CustomerOrderNo          TCustPO                       not null,

    NumPallets               TCount         default 0,
    NumLPNs                  TCount         default 0,
    NumInnerPacks            TCount         default 0,
    NumUnits                 TCount         default 0,
    NumPackages              TCount         default 0,   /* used for Packages shown on BoL */
    NumShippables            TCount         default 0,   /* deprecated */

    Volume                   TVolume        default 0.0,
    Weight                   TWeight        default 0.0,

    Palletized               TFlag,
    ShipperInfo              TDescription,
    SortSeq                  TSortSeq       not null default 0,
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
    UDF5                     TUDF,

    BusinessUnit             TBusinessUnit not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

  constraint pkBoLOrderDetails_BoLOrderDetailId PRIMARY KEY (BoLOrderDetailId),
  constraint ukBoLOrderDetails_BoLId            UNIQUE (BoLId, CustomerOrderNo, BOD_Reference1, BOD_Reference2, BOD_Reference3, BOD_Reference4, BOD_Reference5)
);

Go
