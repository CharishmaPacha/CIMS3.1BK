/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/05/10  PK/AY   pr_OrderHeaders_GetNextPickTicketNo: New procedure to generate a new number
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_GetNextPickTicketNo') is not null
  drop Procedure pr_OrderHeaders_GetNextPickTicketNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_GetNextPickTicketNo
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_GetNextPickTicketNo
  (@OrderType     TTypeCode,
   @PickBatchNo   TPickBatchNo,
   @BusinessUnit  TBusinessUnit,
  -----------------------------------
   @PickTicket    TPickTicket output)
as
  declare @vPickTicketFormat   TVarChar,
          @vPickTicket         TPickTicket,
          @vPickTicketSeqNo    TVarChar,
          @SeqNoIncrement      TInteger,
          @vUserId             TUserId,
          @vControlCategory    TCategory;
begin
  /* Assiging values to declared variables */
  select @vUserId          = System_User,
         @vControlCategory = 'PickTicket_' + @OrderType;

  select @vPickTicketFormat = dbo.fn_Controls_GetAsString(@vControlCategory, 'PickTicketFormat', '<OrderType><SeqNo>',
                                                          @BusinessUnit, @vUserId);

  /* PickTicketNo is generated starting with the format and replacing each
     component as necessary */
  select @vPickTicket = @vPickTicketFormat;

  /* Replace <BatchNo> */
  if (@vPickTicket like ('%<BatchNo>%'))
    select @vPickTicket = replace(@vPickTicket, '<BatchNo>', @PickBatchNo);

  /* Replace <OrderType> */
  if (@vPickTicket like ('%<OrderType>%'))
    select @vPickTicket = replace(@vPickTicket, '<OrderType>', @OrderType);

  /* Replace <SeqNo> with Sequence No */
  if (@vPickTicket like ('%<SeqNo>%'))
    begin
      /* Get the Next PickTicketNo */
      exec pr_Controls_GetNextSeqNoStr 'PickTicket', 1, @vUserId, @BusinessUnit,
                                       @vPickTicketSeqNo output;

      /* Formating PickTicketNo by adding Sequence No */
      select @vPickTicket = replace(@vPickTicket, '<SeqNo>', @vPickTicketSeqNo);
    end

  select @PickTicket = @vPickTicket;
end /* pr_OrderHeaders_GetNextPickTicketNo */

Go
