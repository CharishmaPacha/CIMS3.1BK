/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/02  SK      ProductivityDetails: Revisions post the new design discussion (CIMS-2871)
  2017/08/04  TK      ProductivityDetails: Initial Revision (CIMS-1426)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: ProductivityDetails - Is the join between Productivity table and
  AuditTrail + AuditDetails. A single Producitivity record is summarized by a
  group of Audit records and this tables identifies that group.

  Assignment, Ownership, WH & BU are included here only for informational purpose
------------------------------------------------------------------------------*/
Create Table ProductivityDetails (
    ProdDetailId             TRecordId      identity (1,1) not null,

    ProductivityId           TRecordId,
    AuditId                  TRecordId,
    Assignment               TDescription,

    Ownership                TOwnership,
    Warehouse                TWarehouse,
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    CreatedOn                as (cast(CreatedDate as date)),

    constraint pkProductivityDetail         PRIMARY KEY (ProdDetailId),
    constraint ukProductivityDetail_AuditId Unique (AuditId)
);

create index ix_ProductivityDtls_ProductivityId on ProductivityDetails (ProductivityId, Assignment, AuditId) Include (CreatedDate, Warehouse, BusinessUnit);

Go
