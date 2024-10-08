/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/02/19  OK      pr_Receivers_GetNextReceiverNo to get the Next Receiver Number based on time stamp(CIMS-778)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_GetNextReceiverNo') is not null
  drop Procedure pr_Receivers_GetNextReceiverNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_GetNextReceiverNo: This procedure generates the next receiver Number
  based on the last generated Receiver Number.
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_GetNextReceiverNo
  (@ReceiverType     TTypeCode,               -- Future use, we are not using it now
   @BusinessUnit     TBusinessUnit,
   -----------------------------------------
   @ReceiverNo       TReceiverNumber output)
as
  declare @vReceiverNo        TControlValue,
          @vReceiverNoFormat  TVarChar,
          @vYear              TVarChar,
          @vMonth             TVarChar,
          @vDate              TVarChar,
          @vReceiverSeqNo     TVarChar,
          @SelectReceiverNo   TReceiverNumber,
          @vLastReceiverNo    TReceiverNumber,
          @SeqNoIncrement     TInteger,
          @vUserId            TUserId,
          @ControlRecordId    TRecordId;
begin
  /* Assiging values to declared variables */
  select @vUserId       = System_User;

  /* ReceiverNo is generated starting with the format and replacing each
     component as necessary */
  exec pr_Controls_GetSeqNoFormat 'Receiver', 'ReceiverFormat', @vUserId, @BusinessUnit, @vReceiverNo output;

  /* Replace <SeqNo> with Sequence No */
  if (@vReceiverNo like ('%<SeqNo>%'))
    begin
      /* we need to find the next sequence no for the Receiver - may be for today
         or this month. to do so, we need to find what is the last sequence
         number used. First, prepare the param for the select clause */
      select @SelectReceiverNo = replace(@vReceiverNo, '<SeqNo>', '%');

      /* As we are fetching the records using 'like' statement for last Receiver and
         as we recently introduced new Receiver format (prefix with year as well), we included a condition to check with the current year.
         as old Receivers will not contain year as prefixed and there is a chance that they will get from query */
      select top 1 @vLastReceiverNo = ReceiverNumber
      from Receivers
      where (Year(CreatedDate) = Year(getdate())) and
            (ReceiverNumber like @SelectReceiverNo)
      order by CreatedBy desc;

      /* If there is no ReceiverNumber matching the pattern, then start with a new
         sequence number for the day/month etc., else increment the existing one
         and use it */
      select @SeqNoIncrement = case when (@vLastReceiverNo is null) then null else 1 end;

      /* Get the Next ReceiverNumber, if SeqNoIncrement is null, then it is initialized to 1 */
      exec pr_Controls_GetNextSeqNoStr 'Receiver', @SeqNoIncrement,
                                       @vUserId, @BusinessUnit,
                                       @vReceiverSeqNo output;

      /* Formating ReceiverNumber by adding Sequence No */
      select @vReceiverNo = replace(@vReceiverNo, '<SeqNo>', @vReceiverSeqNo);
    end

  select @ReceiverNo = @vReceiverNo;
end /* pr_Receivers_GetNextReceiverNo */

Go
