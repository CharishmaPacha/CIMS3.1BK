/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_LPNs_ReverseReceipt: Do not pass Receiver Number for Reference (S2GCA-461)
  pr_LPNs_ReverseReceipt: Changes as per the change in signature of pr_LPNs_Void (HPI-1921)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_ReverseReceipt') is not null
  drop Procedure pr_LPNs_ReverseReceipt;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_ReverseReceipt: This Procedure will take LPN(s), ReasonCode,
           ReceiverNumber as input and will void all the LPNs and will export
           -ve receiving exports.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_ReverseReceipt
  (@LPNId            TRecordId,
   @LPNsToRevReceive TEntityKeysTable readonly,
   @ReasonCode       TReasonCode,
   @ReceiverNumber   TReceiverNumber,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId  = null,
   @Message          TDescription = null output)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vLPNsToVoid       TXML;

begin /* pr_LPNs_ReverseReceipt */
  select @vReturnCode     = 0,
         @vMessageName    = null;

  if (@LPNId is not null)
    begin
      /* Build xml here */
      select @vLPNsToVoid = ('<ModifyLPNs>' +
                            (select @LPNId as LPNId
                             for xml Path('LPNContent'), root('LPNs')) +
                             '</ModifyLPNs>')
    end
  else
    begin
      /* Build xml here */
      select @vLPNsToVoid = ('<ModifyLPNs>' +
                              (select EntityId as LPNId
                               from @LPNsToRevReceive
                               for xml Path('LPNContent'), root('LPNs')) +
                             '</ModifyLPNs>')
    end

  /* cal LPNs void procedure here */
  /* We don't need to pass Receiver number for Reference field since we have now added revceiver number to Exports table
     and it is being populated as well */
  exec pr_LPNs_Void @vLPNsToVoid, @BusinessUnit, @UserId, @ReasonCode,
                    @ReceiverNumber /* Reference */, 'ReverseReceiving', @Message output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_ReverseReceipt */

Go
