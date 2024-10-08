/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/12  AY      pr_Replenish_GetNextPickTicketNo: Changed order by from CreatedBy to OrderId for performance reason
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Replenish_GetNextPickTicketNo') is not null
  drop Procedure pr_Replenish_GetNextPickTicketNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Replenish_GetNextPickTicketNo
------------------------------------------------------------------------------*/
Create Procedure pr_Replenish_GetNextPickTicketNo
  (@BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   --------------------------------------
   @PickTicketNo   TPickTicket output)
as
  declare @vReplenishOrderNo       TControlValue,
          @vReplenishOrderNoFormat TVarChar,
          @vMonth                  TVarChar,
          @vDate                   TVarChar,
          @vYear                   TVarChar,
          @vReplenishOrderSeqNo    TVarChar,
          @SelectReplenishOrderNo  TPickBatchNo,
          @vLastReplenishOrderNo   TPickBatchNo,
          @vNextSeqNo              TInteger,
          @vSeqNoMaxLength         TInteger,
          @vNewNextSeqNo           TInteger,
          @SeqNoIncrement          TInteger,
          @vUserId                 TUserId;
begin
  /* Assiging values to declared variables */
  select @vUserId = coalesce(@UserId, System_User);

  select @vReplenishOrderNoFormat = dbo.fn_Controls_GetAsString ('ReplenishOrder', 'OrderFormat', 'R<YY><MM><DD><SeqNo>',
                                                                 @BusinessUnit, @vUserId),
         @vSeqNoMaxLength         = dbo.fn_Controls_GetAsInteger('ReplenishOrder', 'SeqNoMaxLength', '3',
                                                                 @BusinessUnit, @vUserId);

  /* ReplenishOrderNo is generated starting with the format and replacing each component as necessary */
  select @vReplenishOrderNo = @vReplenishOrderNoFormat;

 /* Replace <YY> with year */
  if (@vReplenishOrderNo like ('%<YY>%'))
    begin
      select @vYear        = right(datepart(YY, getdate()), 2);
      select @vReplenishOrderNo = replace(@vReplenishOrderNo, '<YY>', @vYear);
    end

  /* Replace <MM> with month */
  if (@vReplenishOrderNo like ('%<MM>%'))
    begin
      select @vMonth      = dbo.fn_pad(datepart(MM, getdate()), 2);
      select @vReplenishOrderNo = replace(@vReplenishOrderNo, '<MM>', @vMonth);
    end

  /* Replace <DD> with day */
  if (@vReplenishOrderNo like ('%<DD>%'))
    begin
      select @vDate       = dbo.fn_pad(datepart(DD, getdate()), 2);
      select @vReplenishOrderNo = replace(@vReplenishOrderNo, '<DD>', @vDate);
    end

  /* Replace <SeqNo> with Sequence No */
  if (@vReplenishOrderNo like ('%<SeqNo>%'))
    begin
      /* we need to find the next sequence no for the batch - may be for today
         or this month. to do so, we need to find what is the last sequence
         number used. First, prepare the param for the select clause */
      select @SelectReplenishOrderNo = replace(@vReplenishOrderNo, '<SeqNo>', '%');

      select top 1 @vLastReplenishOrderNo = PickTicket
      from OrderHeaders
      where (PickTicket like @SelectReplenishOrderNo)
      order by OrderId desc;

      /* If there is no Batch matching the pattern, then start with a new
         sequence number for the day/month etc., else increment the existing one
         and use it */
      select @SeqNoIncrement = case when (@vLastReplenishOrderNo is null) then null else 1 end;

      /* Get the Next ReplenishBatchNo, if SeqNoIncrement is null, then it is initialized to 1 */
      exec pr_Controls_GetNextSeqNo 'ReplenishOrder', @SeqNoIncrement,
                                    @vUserId, @BusinessUnit,
                                    @vNextSeqNo output;

       /* Applying MaxLength of Sequence No to New SeqNo */
      set @vReplenishOrderSeqNo = dbo.fn_LeftPadNumber(@vNextSeqNo, @vSeqNoMaxLength);

      /* Formating ReplenishBatchNo by adding Sequence No */
      select @vReplenishOrderNo = replace(@vReplenishOrderNo, '<SeqNo>', @vReplenishOrderSeqNo);
    end

  select @PickTicketNo = @vReplenishOrderNo;
end /* pr_Replenish_GetNextPickTicketNo */

Go
