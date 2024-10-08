/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/12/01  OK      pr_RFC_ValidateScannedSKU: Added the procedure to validate given Sku and return the SKU data (CIMS-565)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidateScannedSKU') is not null
  drop Procedure pr_RFC_ValidateScannedSKU;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidateScannedSKU: Validate the SKU for a UoM

  Input:
  <INPUTPARAMS xmlns="INPUTPARAMS">
   <SKU>LPN1</SKU>
   <Operation>Operation1</Operation>
   <BusinessUnit>BusinessUnit1</BusinessUnit>
   <UserId>UserId1</UserId>
   <DeviceId>DeviceId1</DeviceId>
  </INPUTPARAMS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidateScannedSKU
  (@xmlInput     TXML,
   @xmlResult    XML  output)
as
  declare @ReturnCode    TInteger,
          @MessageName   TMessageName,
          @Message       TDescription,
          @vSKUId        TRecordId,
          @vUoM          TUoM,
          @vQuantity     TQuantity,

          /* XML related */
          @vSKU          TSKU,
          @xmlInputInfo  xml,
          @vDeviceId     TDeviceId,
          @vBusinessUnit TBusinessUnit,
          @vUserId       TUserId,

          @vOperation    TDescription,
          @vActivityLogId
                         TRecordId;

begin
begin try

  SET NOCOUNT ON;
  select  @xmlInputInfo = convert(xml, @xmlInput);

  /* Get UserId, BusinessUnit, SKU  from InputParams XML */
  select @vDeviceId     = Record.Col.value('DeviceId[1]',     'TDeviceId'),
         @vUserId       = Record.Col.value('UserId[1]',       'TUserId'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @vSKU          = Record.Col.value('SKU[1]',          'TSKU'),
         @vOperation    = Record.Col.value('Operation[1]',    'TDescription')
  from @xmlInputInfo.nodes('INPUTPARAMS') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInputInfo, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vSKUId, @vSKU, 'SKU',
                      @ActivityLogId = @vActivityLogId output;

 /* User may scan SKU or UPC */
  select @vSKUId = SKUId,
         @vSKU   = SKU
  from dbo.fn_SKUs_GetScannedSKUs (@vSKU, @vBusinessUnit);

  /* Validate the scanned SKU */
  if (@vSKUId is null)
    set @MessageName = 'SKUDoesNotExist';

  if (@MessageName is not null)
     goto ErrorHandler;

  /* Form the XML with the SKU and default UoM and send it to caller  */
  if (@vOperation in ('AddSKUToLPN'))
    set @xmlResult = (select SKU  as SKU,
                             UoM  as UoM
                       from SKUs
                       where (SKUId  = @vSKUId) and
                             (Status = 'A'/* Active */)
                       FOR XML RAW('AddSKUTOLPNSKUInfo'), TYPE, ELEMENTS XSINIL);

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the Result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

end try
begin catch
  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the Error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ValidateScannedSKU */

Go
