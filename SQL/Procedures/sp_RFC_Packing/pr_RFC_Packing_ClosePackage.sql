/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/07/22  OK      pr_RFC_Packing_ClosePackage: Bug Fix: Committed/Rolled back the transaction based on the transaction count (CIMS-1008)
  2016/07/06  KN      pr_RFC_Packing_ClosePackage: Send return tracking no as null to pr_Packing_CloseLPN (NBD-634)
  2016/01/20  TK      pr_RFC_Packing_StartPackage & pr_RFC_Packing_ClosePackage: Final Revision
  2015/12/17  TK      pr_RFC_Packing_ClosePackage: Initial Revision
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Packing_ClosePackage') is not null
  drop Procedure pr_RFC_Packing_ClosePackage;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Packing_ClosePackage:

  @xmlInput Structure:
  <PACKING>
    <CLOSEPACKAGE>
      <LPN></LPN>
      <PickTicket></PickTicket>
      <CartonType></CartonType>
      <CartonWeight></CartonWeight>
      <FromLPN></FromLPN>
      <Action>RFPacking</Action>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
      <LPNCONTENTS>
        <SKUDetails>
          <SKU></SKU>
          <OrderId></OrderId>
          <OrderDetailId></OrderDetailId>
          <LPNId></LPNId>
          <LPNDetailId></LPNDetailId>
          <UnitsPacked></UnitsPacked>
        </SKUDetails>
         .....
         .....
        <SKUDetails>
          <SKU></SKU>
          <OrderId></OrderId>
          <OrderDetailId></OrderDetailId>
          <LPNId></LPNId>
          <LPNDetailId></LPNDetailId>
          <UnitsPacked></UnitsPacked>
        </SKUDetails>
      </LPNCONTENTS>
    </CLOSEPACKAGE>
  </PACKING>

  @xmlResult Structure:
  <SUCCESSDETAILS>
    <SUCCESSINFO>
      <Message>/<Message>
    </SUCCESSINFO>
  </SUCCESSDETAILS>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Packing_ClosePackage
  (@xmlInput   xml,
   @xmlResult  xml          output)
As
  declare @xmlInputInfo        xml,
          @BusinessUnit        TBusinessUnit,
          @UserId              TUserId,
          @DeviceId            TDeviceId,

          @LPN                 TLPN,
          @vToLPN              TLPN,
          @vToLPNId            TRecordId,
          @PalletId            TRecordId,
          @CartonType          TCartonType,

          @PickTicket          TPickTicket,
          @vPickTicket         TPickTicket,
          @vOrderId            TRecordId,

          @vPickBatchNo        TPickBatchNo,

          @LPNContents         TXML,
          @OutputXML           TXML,
          @vResultXML          xml,

          @Weight              TWeight,
          @Volume              TVolume,

          @PackStation         TDescription,

          @Action              TAction,
          @vMessageName        TMessageName,
          @vResultMessage      TDescription,
          @vReturnCode         TInteger,
          @vActivityLogId      TRecordId;

  declare @ttPackDetails table(RecordId         TRecordId Identity(1,1),
                               SKU              TSKU,
                               UnitsPacked      TQuantity,
                               OrderId          TRecordId,
                               OrderDetailId    TRecordId,
                               LPNId            TRecordId,
                               LPNDetailId      TRecordId,
                               SerialNo         TSerialNo,
                               LineType         TFlag);

begin /* pr_RFC_Packing_ClosePackage */
begin try
  begin transaction;
  SET NOCOUNT ON;
  /* convert into xml */
  select @xmlInputInfo = convert(xml, @xmlInput);

   /* get UserId, BusinessUnit, LPN and other stuff  from InputParams XML */
  select @DeviceId      = Record.Col.value('DeviceId[1]'     ,  'TDeviceId'),
         @UserId        = Record.Col.value('UserId[1]'       ,  'TUserId'),
         @BusinessUnit  = Record.Col.value('BusinessUnit[1]' ,  'TBusinessUnit'),
        -- @Operation     = Record.Col.value('Operation[1]'    ,  'TDescription'),
        -- @Pallet        = Record.Col.value('Pallet[1]'       ,  'TPallet'),
         @LPN           = Record.Col.value('LPN[1]'          ,  'TLPN'),
         @PickTicket    = Record.Col.value('PickTicket[1]'   ,  'TPickTicket'),
         @CartonType    = Record.Col.value('CartonType[1]'   ,  'TCartonType'),
         @Action        = Record.Col.value('Action[1]'       ,  'TAction'),
         @Weight        = Record.Col.value('CartonWeight[1]' ,  'TWeight')
        -- @Volume        = Record.Col.value('Volume[1]',         'Tvolume')
  from @xmlInputInfo.nodes('PACKING/CLOSEPACKAGE') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @vOrderId, @vPickTicket, 'Order',
                      @Value1 = @LPN, @Value2 = @CartonType, @Value2 = @Weight,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* get the PickTicket info */
  select @vOrderId     = OrderId,
         @vPickTicket  = PickTicket,
         @vPickBatchNo = PickBatchNo
  from OrderHeaders
  where (PickTicket   = @PickTicket  ) and
        (BusinessUnit = @BusinessUnit);

  /* Get the LPN info */
  select @vToLPNId = LPNId,
         @vToLPN   = LPN
  from LPNs
  where (LPN          = @LPN         ) and
        (BusinessUnit = @BusinessUnit);

  /* insert packdetails into a temp table */
  insert into @ttPackDetails (SKU, UnitsPacked, OrderId, OrderDetailId, LPNId,
                              LPNDetailId, SerialNo, LineType)
    select Record.Col.value('SKU[1]'           ,    'TSKU'),
           Record.Col.value('UnitsPacked[1]'   ,    'TQuantity'),
           Record.Col.value('OrderId[1]'       ,    'TRecordId'),
           Record.Col.value('OrderDetailId[1]' ,    'TRecordId'),
           Record.Col.value('LPNId[1]'         ,    'TRecordId'),
           Record.Col.value('LPNDetailId[1]'   ,    'TRecordId'),
           null /* SerialNo */,
           OD.LineType
    from @xmlInputInfo.nodes('PACKING/CLOSEPACKAGE/LPNCONTENTS/SKUDETAILS') as Record(Col)
      join OrderDetails OD  on (OD.OrderDetailId = Record.Col.value('OrderDetailId[1]' , 'TRecordId'));

  /* Build XML with LPN Contents */
  select @LPNContents = (select SKU,
                                UnitsPacked,
                                OrderId,
                                OrderDetailId,
                                LPNId,
                                LPNDetailId,
                                SerialNo
                         from @ttPackDetails
                         FOR XML raw('CartonDetails'), elements );

  /* Build XML with LPN Contents */
  select @LPNContents =  '<PackingCarton>' + @LPNContents + '</PackingCarton>';

  /* Call Packing Close LPN with the information */
  exec pr_Packing_CloseLPN @CartonType,
                           @PalletId,
                           null /* From LPN Id */,
                           @vOrderId,
                           @Weight,
                           @Volume,
                           @LPNContents,
                           @vToLPN,
                           null /* Return Tracking No */,
                           @PackStation,
                           @Action,
                           @BusinessUnit,
                           @UserId,
                           @OutputXML output

  select @vResultXML = cast(@OutputXML as xml);

  /* Extract the required message to be returned */
  select @vResultMessage = Record.Col.value('ResultMessage[1]' , 'TDescription')
  from @vResultXML.nodes('PackingCloseLPNInfo/Message') as Record(Col);

  select @xmlResult = dbo.fn_XMLNode('SUCCESSDETAILS',
                                      dbo.fn_XMLNode('SUCCESSINFO', dbo.fn_XMLNode('Message' , @vResultMessage)));

  /* Update Device Current Operation Details, etc.,. */
  exec pr_Device_Update @DeviceId, @UserId, 'RFPacking', @OutputXML, @@ProcId;

  /* Log the Results */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the Error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

end catch;
end /* pr_RFC_Packing_ClosePackage */

Go
