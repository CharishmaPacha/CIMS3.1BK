/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/24  AY      pr_Tasks_GetNextBatchNo: Performance optimization
  2014/03/03  NY      pr_Tasks_GetNextBatchNo : Changed CC BatchFormat to include year(YY).
  2011/12/28  YA      Added pr_Tasks_GetNextBatchNo and pr_Tasks_CreateCycleCountTasks.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_GetNextBatchNo') is not null
  drop Procedure pr_Tasks_GetNextBatchNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_GetNextBatchNo
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_GetNextBatchNo
  (@TaskType         TTypeCode,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   --------------------------------------
   @TaskBatchNo      TTaskBatchNo output)
as
  declare @vTaskBatchNo       TControlValue,
          @vTaskBatchNoFormat TVarChar,
          @vYear              TVarChar,
          @vMonth             TVarChar,
          @vDate              TVarChar,
          @vTaskBatchSeqNo    TVarChar,
          @SelectTaskBatchNo  TTaskBatchNo,
          @vLastTaskBatchNo   TTaskBatchNo,
          @vNextSeqNo         TInteger,
          @vSeqNoMaxLength    TInteger,
          @SeqNoIncrement     TInteger,
          @vUserId            TUserId,
          @vControlCategory   TCategory;
begin
  /* Assiging values to declared variables */
  select @UserId           = coalesce(@UserId, System_User),
         @vControlCategory = 'TaskBatch';

  select @vTaskBatchNoFormat = dbo.fn_Controls_GetAsString(@vControlCategory, 'BatchFormat', '<YY><MM><DD><SeqNo>',
                                                           @BusinessUnit, @UserId),
         @vSeqNoMaxLength    = dbo.fn_Controls_GetAsInteger(@vControlCategory, 'SeqNoMaxLength', '3',
                                                            @BusinessUnit, @UserId);

  /* TaskBatchNo is generated starting with the format and replacing each
     component as necessary */
  select @vTaskBatchNo = @vTaskBatchNoFormat;

  /* Replace <YY> with year */
  if (@vTaskBatchNo like ('%<YY>%'))
    begin
      select @vYear        = right(datepart(YY, getdate()), 2);
      select @vTaskBatchNo = replace(@vTaskBatchNo, '<YY>', @vYear);
    end

  /* Replace <mm> with month */
  if (@vTaskBatchNo like ('%<MM>%'))
    begin
      select @vMonth      = dbo.fn_pad(datepart(MM, getdate()), 2);
      select @vTaskBatchNo = replace(@vTaskBatchNo, '<MM>', @vMonth);
    end

  /* Replace <dd> with day */
  if (@vTaskBatchNo like ('%<DD>%'))
    begin
      select @vDate       = dbo.fn_pad(datepart(DD, getdate()), 2);
      select @vTaskBatchNo = replace(@vTaskBatchNo, '<DD>', @vDate);
    end

  /* Replace <SeqNo> with Sequence No */
  if (@vTaskBatchNo like ('%<SeqNo>%'))
    begin
      /* we need to find the next sequence no for the batch - may be for today
         or this month. to do so, we need to find what is the last sequence
         number used. First, prepare the param for the select clause */
      select @SelectTaskBatchNo = replace(@vTaskBatchNo, '<SeqNo>', '%');

      select top 1 @vLastTaskBatchNo = BatchNo
      from Tasks
      where (BatchNo like @SelectTaskBatchNo) and
            (TaskType = coalesce(@TaskType, TaskType))
      order by TaskId desc;

      /* If there is no Batch matching the pattern, then start with a new
         sequence number for the day/month etc., else increment the existing one
         and use it */
      select @SeqNoIncrement = case when (@vLastTaskbatchNo is null) then null else 1 end;

      /* Get the Next TaskBatchNo, if SeqNoIncrement is null, then it is initialized to 1 */
      exec pr_Controls_GetNextSeqNo @vControlCategory, @SeqNoIncrement,
                                    @vUserId, @BusinessUnit,
                                    @vNextSeqNo output;

       /* Applying MaxLength of Sequence No to New SeqNo */
      set @vTaskBatchSeqNo = dbo.fn_LeftPadNumber(@vNextSeqNo, @vSeqNoMaxLength);

      /* Formating TaskBatchNo by adding Sequence No */
      select @vTaskBatchNo = replace(@vTaskBatchNo, '<SeqNo>', @vTaskBatchSeqNo);
    end

  select @TaskBatchNo = @vTaskBatchNo;
end /* pr_Tasks_GetNextBatchNo */

Go
