/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/20  MS      pr_RFC_ValidateScannedLPN: Use LPNStatusDesc in vwLPNs (HA-604)
  2018/10/03  TK      pr_RFC_ValidateScannedLPN: Allow to capture tracking number for picked LPNs as well (S2GCA-333)
  2015/09/26  DK      pr_RFC_ValidateScannedLPN: Enhanced to work for DispositionLPN (FB-389).
  pr_RFC_ValidateScannedLPN: Validation added to validate multi SKU LPN.
  2015/03/16  PK      pr_RFC_ValidateScannedLPN: Enhanced to work for Explode prepacks.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidateScannedLPN') is not null
  drop Procedure pr_RFC_ValidateScannedLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidateScannedLPN: Validate an LPN for a specific operation

  Input:
  <INPUTPARAMS xmlns="INPUTPARAMS">
   <DeviceId>DeviceId1</DeviceId>
   <UserId>UserId1</UserId>
   <BusinessUnit>BusinessUnit1</BusinessUnit>
   <Operation>Operation1</Operation>
   <LPN>LPN1</LPN>
  </INPUTPARAMS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidateScannedLPN
  (@xmlInput     TXML,
   @xmlResult    XML  output)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,
          @vMsgEntity       TDescription,
          @vStatus          TStatus,
          @vStatusDesc      TDescription,
          @vLPNId           TRecordId,
          @vLPN             TLPN,
          @vLPNType         TTypeCode,
          @vSKUId           TRecordId,
          @vSKU             TSKU,
          @LPN              TLPN,
          @vReceiptId       TRecordId,
          @vReceiptType     TReceiptType,
          @vUoM             TUoM,
          @vQuantity        TQuantity,

          /* XML related */
          @xmlInputInfo     xml,
          @vDeviceId        TDeviceId,
          @vBusinessUnit    TBusinessUnit,
          @vUserId          TUserId,

          @vOperation       TDescription,

          @vLoggedInWarehouse   TWarehouse,
          @vLPNDestWarehouse    TWarehouse,
          @vActivityLogId       TRecordId;;
begin
begin try

  SET NOCOUNT ON;
  select @xmlInputInfo = convert(xml, @xmlInput);

   /* Get UserId, BusinessUnit, LPN  from InputParams XML */
  select @vDeviceId     = Record.Col.value('DeviceId[1]',       'TDeviceId'),
         @vUserId       = Record.Col.value('UserId[1]',         'TUserId'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'),
         @LPN           = Record.Col.value('LPN[1]',            'TLPN'),
         @vOperation    = Record.Col.value('Operation[1]',      'TDescription')
  from @xmlInputInfo.nodes('INPUTPARAMS') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInputInfo, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      @vLPNId, @vLPN, 'LPN',
                      @ActivityLogId = @vActivityLogId output;

  /* To track of log before starting the transaction in case of any exceptions */
  begin transaction;

 /* User may scan LPN or UCCBarcode or Tracking Number ..*/
  select @vLPNId      = LPNId,
         @vLPN        = LPN,
         @vStatus     = Status,
         @vStatusDesc = LPNStatusDesc,
         @vSKUId      = SKUId,
         @vSKU        = SKU,
         @vLPNType    = LPNType,
         @vQuantity   = Quantity,
         @vLPNDestWarehouse
                      = DestWarehouse,
         @vReceiptId  = ReceiptId
  from  vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@LPN, @vBusinessUnit, default));

  select @vReceiptType = RH.ReceiptType
  from ReceiptHeaders RH
  where (RH.ReceiptId = @vReceiptId);

  /* Get the UoM of the SKU */
  select @vUoM = UoM
  from SKUs
  where (SKUId = @vSKUId);

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@vDeviceId,@vUserId,@vBusinessUnit);

  if (@vLPNId is null)
    set @MessageName = 'LPNDoesNotExist';
  else
  if (@vOperation = 'UpdateTrackingNoInfo') and (charindex(@vStatus , 'OCVTNJRPU') <> 0)
    select @MessageName = 'CaptureTrackingNo_InvalidStatus',
           @vMsgEntity  = @vStatusDesc;
  else
  if (@vOperation = 'ExplodePrepack')
    begin
      if (@vSKUId is not null) and (@vUoM <> 'PP' /* Prepack */)
        select @MessageName = 'ScannedSKUIsNotAPrepack';
      else
      if (@vSKUId is null)
        select @MessageName = 'CannotExplodeAnLPNWhichHasMultipleSKUs';
      else
      if (@vLPNType = 'L' /* Picklane */)
        select @MessageName = 'LocationTypeIsInvalid';
    end
  else
  if (@vOperation = 'DispositionLPN')
    begin
      if (@vLPNType <> 'C' /* Carton */)
        select @MessageName = 'LPNTypeIsInvalid';
      else
      if (@vStatus <> 'R' /* Received */)
        select @MessageName = 'LPNStatusIsInvalid';
      else
      if (@vReceiptType <> 'R' /* Return */)
        select @MessageName = 'LPNIsInvalid';
    end

  if ((@vOperation <> 'DispositionLPN') and (@vLoggedInWarehouse <> @vLPNDestWarehouse))
    set @MessageName = 'LPNWarehouseMismatch';

  if (@MessageName is not null)
     goto ErrorHandler;

  if (@vOperation = 'ExplodePrepack')
    begin
      /* Form the XML with the UPCs(for now) and send it to caller  */
      set @xmlResult = (select @vLPN             as LPN,
                               ComponentSKU      as ComponentSKU,
                               MasterSKU         as MasterSKU,
                               @vSKU             as DisplaySKU,
                               (ComponentQty * @vQuantity)
                                                 as ComponentQty,
                               @vQuantity        as Quantity,
                               @vQuantity        as DisplayQuantity,
                               @vUoM             as UoM
                         from vwSKUPrepacks
                         where (MasterSKUId = @vSKUId) and
                               (Status      = 'A'/* Active */)
                         FOR XML RAW('SKUPrepackInfo'), TYPE, ELEMENTS XSINIL, ROOT('SKUPrepack'));
    end
  else
    begin
      /* Form the XML with the UPCs(for now) and send it to caller  */
      set @xmlResult = (select LPN         as LPN,
                               UCCBarcode  as UCCBarcode,
                               TrackingNo  as TrackingNumber,
                               ''          as UDF1,
                               ''          as UDF2,
                               ''          as UDF3,
                               ''          as UDF4,
                               ''          as UDF5
                         from LPNs
                         where (LPNid = @vLPNId)
                         FOR XML RAW('TRACKINGNUMBERINFO'), TYPE, ELEMENTS XSINIL, ROOT('TRACKINGNUMBER'));
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @vMsgEntity;

  /* Log the Result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the Error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ValidateScannedLPN */

Go
