/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/02/01  OK      Added a new procedure pr_RFC_CC_ValidateSKUInLPN (GNC-1412)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CC_ValidateSKUInLPN') is not null
  drop Procedure pr_RFC_CC_ValidateSKUInLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CC_ValidateSKUInLPN:
    This  will validate whether the scanned SKU was exists in the scanned LPN or
     not
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CC_ValidateSKUInLPN
  (@xmlInput   xml,
   @xmlResult  xml          output)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vRecordId       TRecordId,

          @SKUId           TRecordId,
          @SKU             TSKU,
          @LPNId           TRecordId,
          @LPN             TLPN,
          @vSKUId          TRecordId,
          @vSKU            TSKU,
          @vLPNId          TRecordId,
          @vLPN            TLPN,
          @Operation       TOperation,
          @BusinessUnit    TBusinessUnit,
          @UserId          TUserId,
          @DeviceId        TDeviceId,
          @vXMLData        TXML,
          @vActivityLogId  TRecordId;

begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the XML User inputs into the local variables */
  select @LPNId        = Record.Col.value('LPNId[1]'        , 'TRecordId'),
         @LPN          = Record.Col.value('LPN[1]'          , 'TLPN'),
         @SKU          = Record.Col.value('SKU[1]'          , 'TSKU'),
         @Operation    = Record.Col.value('Operation[1]'    , 'TOperation'),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]' , 'TBusinessUnit'),
         @UserId       = Record.Col.value('UserId[1]'       , 'TUserId'),
         @DeviceId     = Record.Col.value('DeviceId[1]'     , 'TDeviceId')
  from @xmlInput.nodes('ValidateSKU') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @LPNId, @LPN, 'LPN',
                      @ActivityLogId = @vActivityLogId output;

  /* Fetch details from tables/views */
  select @vSKUId  = SKUId,
         @vSKU    = SKU
  from dbo.fn_SKUs_GetScannedSKUs (@SKU, @BusinessUnit);

  begin transaction

  /* Fetch details from tables/views */
  select @vLPNId  = LPNId,
         @vLPN    = LPN
  from LPNs
  where (LPN          = @LPN) and
        (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'InvalidLPN';
  else
  if (@vSKUId is null)
    set @vMessageName = 'InvalidSKU';
  else
  if (not exists (select * from LPNDetails where LPNId = @vLPNId and SKUId = @vSKUId))
    set @vMessageName = 'CC_SKUIsNotExistsInTheLPN';

  if (@vMessageName is not null)
    goto ErrorHandler;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_BuildRFErrorXML @xmlResult output;

  /* Logging error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;

  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_CC_ValidateSKUInLPN */

Go
