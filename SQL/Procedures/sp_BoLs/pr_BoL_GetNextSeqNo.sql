/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_GetNextSeqNo') is not null
  drop Procedure pr_BoL_GetNextSeqNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_GetNextSeqNo

  UNUSED AS OF 2013/01/21
  UNUSED AS OF 2013/01/21
  UNUSED AS OF 2013/01/21

  For BoL Number, the VICS BoL Next Sequence No is used - see pr_BoL_CreateNew
  implementation
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_GetNextSeqNo
  (@BusinessUnit  TBusinessUnit,
   ---------------------------------
   @BoLNumber    TBoLNumber output)
as
  declare @vBoLNumber         TControlValue,
          @vBoLNumberFormat   TVarChar,
          @vMonth             TVarChar,
          @vDate              TVarChar,
          @vSelectBoLNumber  TLoadNumber,
          @vLastBoLNumber    TLoadNumber,
          @vNextSeqNoStr      TVarChar,
          @SeqNoIncrement     TInteger,
          @vUserId            TUserId;
begin
  /* Assiging values to declared variables */
  select @vUserId = System_User;

  select @vBoLNumberFormat = dbo.fn_Controls_GetAsString('BoLNumber', 'BoLFormat', 'BOL<MM><DD><SeqNo>',
                                                         @BusinessUnit, @vUserId);

  /* BoLNumber is generated starting with the format and replacing each
     component as necessary */
  select @vBoLNumber = @vBoLNumberFormat;

  /* Replace <mm> with month */
  if (@vBoLNumber like ('%<MM>%'))
    begin
      select @vMonth      = dbo.fn_pad(datepart(MM, getdate()), 2);
      select @vBoLNumber  = replace(@vBoLNumber, '<MM>', @vMonth);
    end

  /* Replace <dd> with day */
  if (@vBoLNumber like ('%<DD>%'))
    begin
      select @vDate       = dbo.fn_pad(datepart(DD, getdate()), 2);
      select @vBoLNumber  = replace(@vBoLNumber, '<DD>', @vDate);
    end

  /* Replace <SeqNo> with Sequence No */
  if (@vBoLNumber like ('%<SeqNo>%'))
    begin
      /* we need to find the next sequence no for the BoL - may be for today
         or this month. to do so, we need to find what is the last sequence
         number used. First, prepare the param for the select clause */
      select @vSelectBoLNumber = replace(@vBoLNumber, '<SeqNo>', '%');

      select top 1 @vLastBoLNumber = BoLNumber
      from BoLs
      where (BoLNumber like @vSelectBoLNumber)
      order by BoLId desc;

      /* If there is no BoL matching the pattern, then start with a new
         sequence number for the day/month etc., else increment the existing one
         and use it */
      select @SeqNoIncrement = case when (@vLastBoLNumber is null) then null else 1 end;

      /* Get the Next BoLNumber, if SeqNoIncrement is null, then it is initialized to 1 */
      exec pr_Controls_GetNextSeqNoStr 'BoLNumber', @SeqNoIncrement,
                                       @vUserId, @BusinessUnit,
                                       @vNextSeqNoStr output;

      /* Formating BoLNumber by adding Sequence No */
      select @vBoLNumber = replace(@vBoLNumber, '<SeqNo>', @vNextSeqNoStr);
    end

  select @BoLNumber = @vBoLNumber;
end /* pr_BoL_GetNextSeqNo */

Go
