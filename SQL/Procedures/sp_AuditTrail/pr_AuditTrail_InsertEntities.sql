/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/05/19  AY      pr_AuditTrail_InsertEntities: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AuditTrail_InsertEntities') is not null
  drop Procedure pr_AuditTrail_InsertEntities;
Go
/*------------------------------------------------------------------------------
  Proc pr_AuditTrail_InsertEntities:
    This proc will insert the audit entities for the given audit trail record
------------------------------------------------------------------------------*/
Create Procedure pr_AuditTrail_InsertEntities
  (@AuditRecordId    TRecordId,
   @EntityType       TEntity,
   @ttAuditEntities  TEntityKeysTable ReadOnly,
   @BusinessUnit     TBusinessUnit)
As
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName;
begin
  select @ReturnCode  = 0,
         @MessageName = null;

  /* Insert all valid entities into AuditEntities table */
  insert into AuditEntities(AuditId, BusinessUnit,
                            EntityType, EntityId, EntityKey, EntityDetails)
    select @AuditRecordId, @BusinessUnit,
           @EntityType, EntityId, EntityKey, null
    from @ttAuditEntities
    where (EntityId is not null) and (EntityKey is not null);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_AuditTrail_InsertEntities */

Go
