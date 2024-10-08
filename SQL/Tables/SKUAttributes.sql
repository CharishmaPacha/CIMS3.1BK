/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  AY      SKUAttributes: New table
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: SKUAttributes: Table to hold multiple attributes of a particular SKU -
  for example UPC. Earlier we used to have only one UPC per SKU, but we have
  come across a situation where a SKU could have multiple UPCs and therefore
  we are introducing this table to hold such attributes

  AttributeType: Example: 'UPC'
  AttributeValue: Example: UPCNo
------------------------------------------------------------------------------*/
Create Table SKUAttributes (
    SKUAttributeId           TRecordId      identity (1,1) not null,

    SKUId                    TRecordId      not null,

    AttributeType            TTypeCode      not null,
    AttributeValue           TAttribute,

    Status                   TStatus        not null default 'A' /* Active*/,
    SortSeq                  TSortSeq       not null default 0,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkSKUAttribute PRIMARY KEY (SKUAttributeId)
);

create index ix_SKUAttributes_SKUId              on SKUAttributes (SKUId, AttributeType) Include (Status, Archived);
create index ix_SKUAttributes_Attribute          on SKUAttributes (AttributeType, AttributeValue, BusinessUnit) Include (SKUId, Status);

Go
