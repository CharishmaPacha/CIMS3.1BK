/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/07/06  KN      pr_Packing_ExecuteAction: pr_Packing_CloseLPN: Input params consolidated to xml
  2014/09/30  DK/VM   pr_Packing_ExecuteAction: New feature - ModifyCarton was included.
  pr_Packing_ExecuteAction: Wrapper procedure to enable further enhancements and
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_ExecuteAction') is not null
  drop Procedure pr_Packing_ExecuteAction;
Go
Create Procedure pr_Packing_ExecuteAction
  (@PackingInfo   varchar(max),
   @LPNContents   varchar(max),
   @OutputXML     TXML    output)
  as
    declare @ReturnCode   TInteger,
            @MessageName  TMessageName ,
            @CartonType   TCartonType,
            @PalletId     TRecordId,
            @OrderId      TRecordId,
            @Weight       TWeight,
            @Volume       TVolume,
            @ToLPN        TLPN,
            @ReturnTrackingNo
                          TTrackingNo,
            @PackStation  TName,
            @Action       TAction,
            @BusinessUnit TBusinessUnit,
            @UserId       TUserId,
            @vPackingInfo xml;
begin
  SET NOCOUNT ON;

  select @vPackingInfo = convert(xml, @PackingInfo)

  select  @CartonType     = Record.Col.value('CartonType[1]', 'TCartonType'),
          @PalletId       = Record.Col.value('PalletId[1]','TRecordId'),
          @OrderId        = Record.Col.value('OrderId[1]','TRecordId'),
          @Weight         = Record.Col.value('Weight[1]','TWeight'),
          @Volume         = Record.Col.value('Volume[1]','TVolume'),
          @ToLPN          = Record.Col.value('ToLPN[1]', 'TLPN'),
          @ReturnTrackingNo
                          = Record.Col.value('ReturnTrackingNo[1]','TTrackingNo'),
          @PackStation    = Record.Col.value('PackStation[1]', 'TName'),
          @Action         = Record.Col.value('Action[1]', 'TAction'),
          @BusinessUnit   = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
          @UserId         = Record.Col.value('UserId[1]', 'TUserId')
  from    @vPackingInfo.nodes('/PackingInfo') as Record(Col);

  select @ReturnCode  = 0,
         @MessageName = null,
         @ToLPN       = nullif(@ToLPN, '');

  /* Validate if it is Modify */
  if @Action = '$ModifyCarton$'
    exec @ReturnCode = pr_Packing_ValidateToModifyLPN @ToLPN;

  if (@ReturnCode > 0)
    goto ExitHandler;

  /* Change action appropriately */
  select @Action = case
                     when (@Action = '$CloseCarton$') or
                          (@Action = '$ClosePackage$') then
                       'CloseLPN'
                     when (@Action = '$PauseCarton$') or
                          (@Action = '$PausePackage$') then
                       'PackLPN'
                     when (@Action = '$ModifyCarton$') then
                       'ModifyLPN' /* Currently it is nothing but reopen and closing it again  */
                     else
                       @Action
                   end;

  /* Just a pass thru procedure for now */
  exec @ReturnCode = pr_Packing_CloseLPN @CartonType,
                                         @PalletId,
                                         null /* From LPN Id */,
                                         @OrderId,
                                         @Weight,
                                         @Volume,
                                         @LPNContents,
                                         @ToLPN,
                                         @ReturnTrackingNo,
                                         @PackStation,
                                         @Action,
                                         @BusinessUnit,
                                         @UserId,
                                         @OutputXML output;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Packing_ExecuteAction */

Go
