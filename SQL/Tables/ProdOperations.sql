/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/10/10  PKS     ProdOperations: Added EntityType
  BusinessUnit to ProdOperations Table.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: ProdOperations

    Mapping table between ActivityType and

 Operation - can be Picking
 SubOperation - can be PalletPick, LPNPick, Unit Pick

 Mode: S - Starting Operation, D - Detail Operation, E - Ending Operation

 Updatecounts: Denotes which counts have to be update
               U - Units, I - Inner Packs, L - LPNs, S - SKUs, O - Orders, C - Location

 StandardOp: Y/N. A standard operation is any process that is done as part of
   the expected work i.e. Receiving, Putaway, Picking, Packing, Shipping etc.
   A non-standard operation is misc. work like servicing equipment, Cleaning, Meeting etc.
------------------------------------------------------------------------------*/
Create Table ProdOperations (
    RecordId                 TRecordId      identity (1,1) not null,

    ActivityType             TDescription,
    Operation                TDescription,
    SubOperation             TDescription,
    JobCode                  TJobCode,

    EntityType               TTypeCode,
    Mode                     TFlag,
    UpdateCounts             TFlags,
    StandardOp               TFlag,
    Status                   TStatus        not null default 'A' /* Active */,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkProdOperations   PRIMARY KEY (RecordId)
);

create index ix_ProdOperations_ActivityType on ProdOperations (ActivityType) Include (Status);

Go
