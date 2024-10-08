/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  AuditEntities: Added Index ixAuditIdEntityType
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: AuditEntities
   EntityType    - can be LPN, Pallet, Order, Location, PickBatch
   EntityId      - should be the original Id of Entity, like LPNId, PalletId, PickBatchId etc.
   EntityKey     - the primary key information of the entity like LPN, Pallet, PickbatchNo etc.
   EntityDetails - should be an xml data type and should hold all the fine details - FUTURE USE.
------------------------------------------------------------------------------*/
Create Table AuditEntities (
    AuditDetailId            TRecordId identity (1,1) not null,
    AuditId                  TRecordId,

    EntityType               TTypeCode,
    EntityId                 TRecordId,
    EntityKey                TEntity,

    EntityDetails            TXML,          /* Future Use */
    BusinessUnit             TBusinessUnit  not null,

    constraint pkAuditEntities_AuditDetailId PRIMARY KEY (AuditDetailId)
);

create index ix_AuditEntity_Id              on AuditEntities (EntityId, EntityType) Include (AuditId)
create index ix_AuditEntity_Key             on AuditEntities (EntityKey, EntityType, BusinessUnit) Include (AuditId, EntityDetails);
create index ix_AuditEntity_AuditIdType     on AuditEntities (AuditId, EntityType);

Go
