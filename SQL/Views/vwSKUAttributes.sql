/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/10/10  TD      Added SKU field.
  2013/08/08  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwSKUAttributes') is not null
  drop View dbo.vwSKUAttributes;
Go

Create View dbo.vwSKUAttributes (
  SKUAttributeId,
  SKUId,
  SKU,
  Description,

  Status,

  AttributeType,
  AttributeValue,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  SA.SKUAttributeId,
  SA.SKUId,
  S.SKU,
  S.Description,

  SA.Status,

  SA.AttributeType,
  SA.AttributeValue,

  SA.Archived,
  SA.BusinessUnit,
  SA.CreatedDate,
  SA.ModifiedDate,
  SA.CreatedBy,
  SA.ModifiedBy
from
  SKUAttributes SA
  left join SKUs S on (S.SKUId = SA.SKUId);

Go
