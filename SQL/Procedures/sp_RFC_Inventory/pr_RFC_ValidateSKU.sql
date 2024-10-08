/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/15  TK      pr_RFC_ValidateSKU: Return data from SKUs table instead of SKUAttributes (S2G-947)
  2018/05/22  TK      pr_RFC_ValidateSKU: Validate SKU attributes (S2GCA-26)
                      pr_RFC_ValidateSKU: Handle duplicate UPCs i.e. diff SKUs having same UPC (SRI-422)
  2013/09/04  TD      pr_RFC_ValidateSKU: Changes about to validate SKU dimensions.
  2013/08/09  TD      Added pr_RFC_ValidateSKU,pr_RFC_UpdateSKUAttributes and Ordered alphabetically.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidateSKU') is not null
  drop Procedure pr_RFC_ValidateSKU;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidateSKU: Validate a SKU for a specific operation
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidateSKU
  (@SKU           TSKU,
   @Operation     TDescription = null,
   @DeviceId      TDeviceId,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit,
   @xmlResult     xml output)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,
          @vMsgParam1     TDescription,
          @vSKUId         TRecordId,
          @vSKU           TSKU;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Get SKUId here for given SKU */
  select top 1 @vSKUId = SKUId,
               @vSKU   = SKU
  from fn_SKUs_GetScannedSKUs(@SKU, @BusinessUnit);

  if (@vSKUId is null)
    set @MessageName = 'SKUDoesNotExist';
  else
  if (@Operation = 'Receiving')
    set @MessageName = dbo.fn_SKUs_IsOperationAllowed(@vSKUId, 'ReceiveSKU');

  if (@MessageName is not null)
     goto ErrorHandler;

  /* Form the XML with the UPCs(for now) and send it to caller  */
  set @xmlResult = (select SKU,
                           UPC,
                           Description
                    from SKUs
                    where (SKUId = @vSKUId)
                    FOR XML RAW('SKUATTRIBUTES'), TYPE, ELEMENTS XSINIL, ROOT('SKU'));

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ValidateSKU */

Go
