/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/09/24  NB/TK   Added pr_PrintServiceRequests_AddOrUpdate and pr_PrintServiceRequests_SetStatus.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PrintServiceRequests_AddOrUpdate') is not null
  drop Procedure pr_PrintServiceRequests_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_PrintServiceRequests_AddOrUpdate:
    Introduces new record for Print Label request or Updates an existing record
------------------------------------------------------------------------------*/
Create Procedure pr_PrintServiceRequests_AddOrUpdate
  ( @UserId             TUserId,
    @PrinterId          TDeviceId,
    @EntityType         TTypeCode,
    @EntityKey          TEntity,
    @RequestInfo        TXML = null,

    @Priority           TPriority,

    @BusinessUnit       TBusinessUnit,
    @RequestId          TRecordId output
  )
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @Message             TDescription;

begin /* pr_PrintServiceRequests_AddOrUpdate */
  select @ReturnCode   = 0,
         @MessageName  = null;

  /* If RequestId is not null, then verify if RequestId exists */
  if (@EntityKey is null)
    set @MessageName  = 'InvalidServiceRequest';
  else
  /* Validate BusinessUnit */
  if(@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';
  else
  /* Validate UserId */
  if (not exists(select *
                 from Users
                 where (UserName = @UserId) and
                       (IsActive = '1'    )))
    set @MessageName = 'UserNameIsInvalid';      -- We dont need this as we validate UserId at the Login time.

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Check whether the RequestId exits for the required task or not */
  if (@RequestId is null)
    select @RequestId = RecordId
    from PrintServiceRequests
    where (EntityType    = @EntityType  ) and
          (EntityKey     = @EntityKey   ) and
          (BusinessUnit  = @BusinessUnit);

  if (@RequestId is null)
    begin
      /* Insert new request into the table */
      insert into PrintServiceRequests
          (PrinterId, EntityType, EntityKey, RequestInfo,
           Priority, BusinessUnit, CreatedBy)
      select @PrinterId, @EntityType, @EntityKey, @RequestInfo,
             @Priority, @BusinessUnit, @UserId;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PrintServiceRequests_AddOrUpdate */

Go
