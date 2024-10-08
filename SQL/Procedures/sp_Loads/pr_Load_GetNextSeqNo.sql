/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

              AY      pr_Load_GetNextSeqNo: Changed to use ShipToId in LoadNumber
  2013/01/24  PKS     pr_Load_GetNextSeqNo: Changes as Year is added to Load Format
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_GetNextSeqNo') is not null
  drop Procedure pr_Load_GetNextSeqNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_GetNextSeqNo
------------------------------------------------------------------------------*/
Create Procedure pr_Load_GetNextSeqNo
  (@BusinessUnit  TBusinessUnit,
   @ShipToId      TShipToId,
   ----------------------------------
   @LoadNumber    TLoadNumber output)
as
  declare @vLoadNumber        TControlValue,
          @vLoadNumberFormat  TVarChar,
          @vYear              TVarChar,
          @vMonth             TVarChar,
          @vDate              TVarChar,
          @vSelectLoadNumber  TLoadNumber,
          @vLastLoadNumber    TLoadNumber,
          @vPrevChar          TVarchar,
          @vNextSeqNoStr      TVarChar,
          @SeqNoIncrement     TInteger,
          @vOverflow          TInteger,
          @vUserId            TUserId;
begin
  /* Assiging values to declared variables */
  select @vUserId = System_User;

  select @vLoadNumberFormat = dbo.fn_Controls_GetAsString('LoadNumber', 'LoadFormat', 'LD<YY><MM><DD><SeqNo>',
                                                           @BusinessUnit, @vUserId);

  /* LoadNumber is generated starting with the format and replacing each
     component as necessary */
  select @vLoadNumber = @vLoadNumberFormat;

  /* Replace <YY> with year */
  if (@vLoadNumber like ('%<YY>%'))
    begin
      select @vYear       = right(datepart(YY, getdate()), 2);
      select @vLoadNumber = replace (@vLoadNumber, '<YY>', @vYear);
    end

  /* Replace <mm> with month */
  if (@vLoadNumber like ('%<MM>%'))
    begin
      select @vMonth       = dbo.fn_pad(datepart(MM, getdate()), 2);
      select @vLoadNumber  = replace(@vLoadNumber, '<MM>', @vMonth);
    end

  /* Replace <dd> with day */
  if (@vLoadNumber like ('%<DD>%'))
    begin
      select @vDate        = dbo.fn_pad(datepart(DD, getdate()), 2);
      select @vLoadNumber  = replace(@vLoadNumber, '<DD>', @vDate);
    end

  /* Replace ShipToId */
  if (@ShipToId is not null)
    select @vLoadNumber  = replace(@vLoadNumber, '<ShipTo>', @ShipToId);

  /* Replace <SeqNo> with Sequence No */
  if (@vLoadNumber like ('%<SeqNo>%'))
    begin
      /* we need to find the next sequence no for the batch - may be for today
         or this month. to do so, we need to find what is the last sequence
         number used. First, prepare the param for the select clause */
      select @vSelectLoadNumber = replace(@vLoadNumber, '<SeqNo>', '%');

      select top 1 @vLastLoadNumber = LoadNumber
      from Loads
      where (LoadNumber like @vSelectLoadNumber)
      order by LoadId desc;

      /* If there is no Load matching the pattern, then start with a new
         sequence number for the day/month etc., else increment the existing one
         and use it */
      select @SeqNoIncrement = case when (@vLastLoadNumber is null) then null else 1 end;

      /* Get the Next LoadNumber, if SeqNoIncrement is null, then it is initialized to 1 */
      exec pr_Controls_GetNextSeqNoStr 'LoadNumber', @SeqNoIncrement,
                                       @vUserId, @BusinessUnit,
                                       @vNextSeqNoStr output;

      /* Formating LoadNumber by adding Sequence No */
      select @vLoadNumber = replace(@vLoadNumber, '<SeqNo>', @vNextSeqNoStr);
    end

  /* Replace <SeqChar> with next character */
  if (@vLoadNumber like ('%<SeqChar>%'))
    begin
      /* we need to find the next sequence no for the batch - may be for today
         or this month. to do so, we need to find what is the last sequence
         number used. First, prepare the param for the select clause */
      select @vSelectLoadNumber = replace(@vLoadNumber, '<SeqChar>', '%');

      select top 1 @vLastLoadNumber = LoadNumber
      from Loads
      where (LoadNumber like @vSelectLoadNumber)
      order by LoadId desc;

      /* If there is no Load matching the pattern, then start with a new
         character for the day/month etc., else increment the existing one
         and use it */
      if (@vLastLoadNumber is null)
        select @vNextSeqNoStr = 'A'
      else
        begin
          select @vPrevChar = substring(@vLastLoadNumber, 8, 1); /* these should be control vars */
          exec pr_SuccChar @vPrevChar, 1 /* Increment */, 'A' /* CharSet: Alpha only */,
                           @vNextSeqNoStr output, @vOverflow output;
        end

      /* Formating LoadNumber by adding Sequence No */
      select @vLoadNumber = replace(@vLoadNumber, '<SeqChar>', @vNextSeqNoStr);
    end

  select @LoadNumber = @vLoadNumber;
end /* pr_Load_GetNextSeqNo */

Go
