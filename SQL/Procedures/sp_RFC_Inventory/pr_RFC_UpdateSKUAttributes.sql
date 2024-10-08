/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/12/11  SV      pr_RFC_AddSKUToLocation, pr_RFC_RemoveSKUFromLocation, pr_RFC_UpdateSKUAttributes, pr_RFC_ValidateLocation,
  2013/08/28  TD      pr_RFC_UpdateSKUAttributes: Building Error message properly.
  2013/08/09  TD      Added pr_RFC_ValidateSKU,pr_RFC_UpdateSKUAttributes and Ordered alphabetically.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_UpdateSKUAttributes') is not null
  drop Procedure pr_RFC_UpdateSKUAttributes;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_UpdateSKUAttributes:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_UpdateSKUAttributes
  (@SKU           TSKU,
   @UPC           TUPC,
   @Operation     TDescription,
   @DeviceId      TDeviceId,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit,
   @xmlResult     xml output)
as
  declare @ReturnCode      TInteger,
          @MessageName     TMessageName,
          @Message         TDescription,
          @vMsgParam1      TDescription,
          @vSKUId          TRecordId,
          @vUPCStripped    TUPC,
          @vAlternateSKU   TSKU,
          @AttributeType   TTypeCode,
          @vAlternateSKUId TRecordId;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Assume : All the validations will be done in RF side. */
  /* Get SKUId here for given SKU */
  select top 1 @vSKUId = SKUId
  from fn_SKUs_GetScannedSKUs(@SKU, @BusinessUnit);

  if (Len(@UPC) = 12 /* UPC-A format */)
    select @vUPCStripped = right(LEFT(@UPC, LEN(@UPC) - 1), LEN(@UPC)-2);

  /* We need to validte here if the given UPC is already exists on any other SKU */
  if (@Operation = 'UPC+')
    begin
      select @vAlternateSKU   = S.SKU,
             @vAlternateSKUId = S.SKUId
      from SKUAttributes SA left outer join SKUs S on SA.SKUId = S.SKUId
      where (SA.SKUId <> @vSKUId) and
            ((SA.AttributeValue = @UPC) or (SA.AttributeValue = @vUPCStripped)) and
            (SA.AttributeType  = 'UPC');

      if (@vAlternateSKUId is not null) and (@vAlternateSKUId <> @vSKUId)
        begin
          select @MessageName = 'UPCAssociatedWithOtherSKU',
                 @vMsgParam1  = @vAlternateSKU;
        end
      else
      if (@vAlternateSKUId is not null) and (@vAlternateSKUId = @vSKUId)
        begin
          select @MessageName = 'UPCAssociatedWithSameSKU';
        end
    end

  if (@MessageName is not null)
    begin
      /* Get Message here */
      exec @Message = dbo.fn_Messages_Build @MessageName, @vAlternateSKU;

     goto ErrorHandler;
    end

  /* In future there may be some other operation, so need to send activitytype
     based on operation  */
  if (@Operation like 'UPC%')
    begin
      set @AttributeType = 'UPC';
    end

  /* call the procedure here to add or Update UPC to SKU. */
  exec pr_SKUAttributes_Modify @vSKUId, @AttributeType, @UPC, @Operation,
                               @BusinessUnit, @UserId,  @Message = @Message output;

  /* build success message here */
  select @Message = dbo.fn_Messages_GetDescription(@Message);
  set @xmlResult = (select 0        as ErrorNumber,
                           @Message as ErrorMessage
                        FOR XML RAW('SKUATTRIBUTES'), TYPE, ELEMENTS XSINIL, ROOT('SKU'));

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @Message;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_UpdateSKUAttributes */

Go
