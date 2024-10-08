/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2103/08/27  TD      pr_SKUAttributes_Modify:Building error message properly.
  2013/08/07  TD      pr_SKUAttributes_Modify, pr_SKUAttributes_Delete: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUAttributes_Modify') is not null
  drop Procedure pr_SKUAttributes_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUAttributes_Modify:
------------------------------------------------------------------------------*/
Create Procedure pr_SKUAttributes_Modify
  (@SKUId             TRecordId,
   @AttributeType     TTypeCode,
   @AttributeValue    TAttribute,
   @Operation         TOperation  = null,

   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   ------------------------------------------
   @SKUAttributeId    TRecordId = null output,
   @Message           TNVarChar = null output)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName;

   declare @vNote1             TDescription,
           @vActivityType      TActivityType,
           @vAuditId           TRecordId,
           @vAuditRecordId     TRecordId,
           @vTransType         TTypeCode,
           @vUPCStripped       TUPC,
           @vAttributeValue    TAttribute,
           @vAttributeSKUId    TRecordId,
           @vSKU               TSKU,
           @vAlternateSKU      TSKU;
  /* Temp table to hold all the SKUs to be updated */
  declare @ttSKUsUpdated TEntityKeysTable;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* get SKU here */
  select @vSKU         = SKU,
         @vNote1       = @AttributeValue,
         @vUPCStripped = @AttributeValue
  from SKUs
  where (SKUId = @SKUId);

  if (Len(@AttributeValue) = 12 /* UPC-A format */)
    select @vUPCStripped = right(LEFT(@AttributeValue, LEN(@AttributeValue) - 1), LEN(@AttributeValue)-2);

  select @vAttributeValue = AttributeValue,
         @vAttributeSKUId = SKUId
  from SKUAttributes
  where (AttributeType = @AttributeType) and
        ((AttributeValue = @AttributeValue) or (AttributeValue = @vUPCStripped));

  if (coalesce(@vAttributeSKUId, 0) = 0)
   begin
      /* Get SKU here */
      select @vAlternateSKU   = SKU,
             @vAttributeSKUId = SKUId,
             @vAttributeValue = UPC
      from SKUs
      where ((UPC = @AttributeValue) or (UPC = @vUPCStripped));
   end

  /* Validations */
  if (@Operation = 'UPC+') and (@vAttributeValue is not null) and (@SKUId <> @vAttributeSKUId)
    set @MessageName = 'UPCAssociatedWithOtherSKU';
  else
  if (@Operation = 'UPC+') and (@vAttributeValue is not null) and (@SKUId = @vAttributeSKUId)
    set @MessageName = 'UPCAssociatedWithSameSKU';

  if (@MessageName is not null)
    begin
      /* Get Message here */
      exec @Message = dbo.fn_Messages_Build @MessageName, @vAlternateSKU;

     goto ErrorHandler;
    end

  if (@Operation = 'UPC+')
    begin
       /* AT related */
       select @vActivityType  = 'UPCAddedToSKU',
              @Message        = 'SKU_UPCAdded_Successful',
              @AttributeValue = case when (LEN(@AttributeValue) = 12 ) then   /* remove first and last char here */
                                       @vUPCStripped
                                     --when (LEN(@AttributeValue) = 11 ) then
                                     --  LEFT(@AttributeValue, LEN(@AttributeValue) - 1)
                                     else @AttributeValue
                                end;
      /* insert data into SKUAttributes here */
      insert into SKUAttributes (SKUId, AttributeType, AttributeValue, BusinessUnit, CreatedBy)
        select @SKUId, @AttributeType, @AttributeValue, @BusinessUnit, @UserId;

      select @SKUAttributeId = SCOPE_IDENTITY();
    end
  else
  if (@Operation = 'UPC-')
    begin
      /* AT related */
      select @vActivityType = 'UPCRemovedFromSKU',
             @Message       = 'SKU_UPCRemoved_Successful';

      /* If the caller does not send the SKUAttributeid  then we need to get it */
      if (coalesce(@SKUAttributeId, 0) = 0)
        begin
          select @SKUAttributeId = SKUAttributeId
          from SKUAttributes
          where (SKUId          = SKUId) and
                (AttributeType  = @AttributeType) and
                ((AttributeValue = @AttributeValue) or (AttributeValue = @vUPCStripped));
         end

      /* Delete fro mthe table for the given id  */
      delete from SKUAttributes
      where (SKUAttributeId = @SKUAttributeId);
    end
  else
    begin
      /* If the action is not one of the above, send a message to UI saying Unsupported Action*/
      set @MessageName = 'UnsupportedAction';
      goto ErrorHandler;
    end;

    /* Insert data into temptable */
  insert into @ttSKUsUpdated(EntityId, EntityKey)
    select @SKUId, @vSKU;

  /* generate Audit list here */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                            @SKUID         = @SKUId,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1,
                            @AuditRecordId = @vAuditId output;

  /* Call Export Proc here t oexport data */
  exec pr_Exports_SKUData @Operation, @ttSKUsUpdated /* temp table */, null,
                          @AttributeValue /* UPC */, @BusinessUnit, @UserId;

  /* Get Message here */
  exec @Message = dbo.fn_Messages_Build @Message, @AttributeValue, @vSKU;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @Message;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_SKUAttributes_Modify */

Go
