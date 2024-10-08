/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/11  AY/TK   pr_Wave_ReleaseForAllocation: Change to send CasesToShip and RemUnitsToShip for Rules
                      pr_PickBatch_GetNextBatchNo: Replenish Wave should be created with suffix 'R' (S2G-612)
  2013/01/28  PKS     pr_PickBatch_GetNextBatchNo: PickBatch Format changes migrated from LOEH, Year was added (<YY>).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_GetNextBatchNo') is not null
  drop Procedure pr_PickBatch_GetNextBatchNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_PickBatch_GetNextBatchNo
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_GetNextBatchNo
  (@PickBatchType    TTypeCode,
   @BusinessUnit     TBusinessUnit,
   --------------------------------------
   @PickBatchNo      TPickBatchNo output)
as
  declare @vPickBatchNo       TControlValue,
          @vPickBatchNoFormat TVarChar,
          @vYear              TVarChar,
          @vMonth             TVarChar,
          @vDate              TVarChar,
          @vPickBatchSeqNo    TVarChar,
          @SelectPickBatchNo  TPickBatchNo,
          @vLastPickBatchNo   TPickBatchNo,
          @SeqNoIncrement     TInteger,
          @vUserId            TUserId,
          @ControlRecordId    TRecordId;
begin
  /* Assiging values to declared variables */
  select @vUserId       = System_User;

  select @vPickBatchNoFormat = dbo.fn_Controls_GetAsString('PickBatch', 'BatchNoFormat', '<YY><MM><DD><SeqNo>',
                                                           @BusinessUnit, @vUserId);

  /* PickBatchNo is generated starting with the format and replacing each
     component as necessary */
  select @vPickBatchNo = @vPickBatchNoFormat;

  /* Replace <YY> with year */
  if (@vPickBatchNo like ('%<YY>%'))
    begin
      select @vYear        = right(datepart(YY, getdate()), 2);
      select @vPickBatchNo = replace(@vPickBatchNo, '<YY>', @vYear);
    end

  /* Replace <mm> with month */
  if (@vPickBatchNo like ('%<MM>%'))
    begin
      select @vMonth       = dbo.fn_pad(datepart(MM, getdate()), 2);
      select @vPickBatchNo = replace(@vPickBatchNo, '<MM>', @vMonth);
    end

  /* Replace <dd> with day */
  if (@vPickBatchNo like ('%<DD>%'))
    begin
      select @vDate        = dbo.fn_pad(datepart(DD, getdate()), 2);
      select @vPickBatchNo = replace(@vPickBatchNo, '<DD>', @vDate);
    end

  /* Replace <SeqNo> with Sequence No */
  if (@vPickBatchNo like ('%<SeqNo>%'))
    begin
      /* we need to find the next sequence no for the batch - may be for today
         or this month. to do so, we need to find what is the last sequence
         number used. First, prepare the param for the select clause */
      select @SelectPickBatchNo = replace(@vPickBatchNo, '<SeqNo>', '%');

      /* As we are fetching the records using 'like' statement for last batch and
         as we recently introduced new batch format (prefix with year as well), we included a condition to check with the current year.
         as old batches will not contain year as prefixed and there is a chance that they will get from query */
      select top 1 @vLastPickBatchNo = BatchNo
      from PickBatches
      where (Year(CreatedDate) = Year(getdate())) and
            (BatchNo like @SelectPickBatchNo) and
            (BusinessUnit = @BusinessUnit)
      order by CreatedDate desc;

      /* If there is no Batch matching the pattern, then start with a new
         sequence number for the day/month etc., else increment the existing one
         and use it */
      select @SeqNoIncrement = case when (@vLastPickbatchNo is null) then null else 1 end;

      /* Get the Next PickBatchNo, if SeqNoIncrement is null, then it is initialized to 1 */
      exec pr_Controls_GetNextSeqNoStr 'PickBatch', @SeqNoIncrement,
                                       @vUserId, @BusinessUnit,
                                       @vPickBatchSeqNo output;

      /* Formating PickBatchNo by adding Sequence No */
      select @vPickBatchNo = case when (@PickBatchType in ('R', 'RU', 'RP'/* Replenish */))
                                    then replace(@vPickBatchNo, '<SeqNo>', @vPickBatchSeqNo) + 'R' -- Add suffix 'R' for Replenish Wave
                                  else replace(@vPickBatchNo, '<SeqNo>', @vPickBatchSeqNo)
                             end;
    end

  select @PickBatchNo = @vPickBatchNo;
end /* pr_PickBatch_GetNextBatchNo */

Go
