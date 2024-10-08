/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/28  RKC     pr_Locations_Build: Added Warehouse parm (BK-440)
  2015/10/14  PK/SV   pr_Locations_Build, pr_Locations_Generate: Included Bay in the location format.
                         in pr_Locations_Build procedure.
                      pr_Locations_Build : Trimed data because it is generating 3 spaces for first 5 records.
  2011/01/18  VM      pr_Locations_Generate, pr_Locations_Build: Added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Build') is not null
  drop Procedure pr_Locations_Build;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Build:
    As the name is itself self explanatory, it is used to builds Locations
    based on the given format. It assumes that the caller passes a valid LocationType,
    LocationFormat. It also assumes that the caller passes appropriate parameters
    for Row, Section, Level, if they are used in LocationFormat (for example, if the caller
    wants to use Row, LocationFormat should contain in it some where like this <Row>).
    It assumes that the caller uses Row in LocationFormat, if starting value is passed
    for Row, ie @StartRow. Likewise for Section and Level. So the caller needs
    to validate those before calling this procedure.

    ** Currently we would like to use @RowCharSet as 'A' for 'Alphabets only' or
      'N' for 'Numerics only' and leave 'AN' - 'Alpha Numeric' for now. We can
      do that later enhancements. So the caller should take care of using either only
      alphabets or Numerics in @StartRow and @EndRow. Likewise for Section, Level.

    ** It returns the created LPN's list and existing LPN's list within the specified region.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Build
  (@BusinessUnit     TBusinessUnit,
   @Warehouse        TWarehouse,
   @UserId           TUserId,

   @LocationType     TLocationType,
   @LocationFormat   TControlValue,

   /* Row */
   @StartRow         TRow     = null,
   @EndRow           TRow     = null,
   @RowIncrement     TRow     = '1',
   @RowCharSet       TCharSet = null, /* A - Alphabets only, N - Numerics only */

   /* Section */
   @StartSection     TSection = null,
   @EndSection       TSection = null,
   @SectionIncrement TSection = '1',
   @SectionCharSet   TCharSet = null, /* A - Alphabets only, N - Numerics only */

   /* Level */
   @StartLevel       TLevel   = null,
   @EndLevel         TLevel   = null,
   @LevelIncrement   TLevel   = '1',
   @LevelCharSet     TCharSet = null, /* A - Alphabets only, N - Numerics only */

   /* Bay */
   @StartBay         TBay     = null,
   @EndBay           TBay     = null,
   @BayIncrement     TBay     = '1',
   @BayCharSet       TCharSet = null) /* A - Alphabets only, N - Numerics only */
as
  declare @ttLocations Table
    (RecordId          TRecordId identity (1,1),
     Location          TLocation,
     LocationRow       TRow,
     LocationLevel     TLevel,
     LocationSection   TSection,
     LocationBay       TBay,
     LocationExists    TFlag)
begin
  declare @vRowIncrement     TInteger,
          @vRow              TRow,
          @vRowTmp           TRow,
          @vRowMaxLength     TInteger,

          @vSectionIncrement TInteger,
          @vSection          TSection,
          @vSectionTmp       TSection,
          @vEndSection       TSection,
          @vSectionMaxLength TInteger,

          @vLevelIncrement   TInteger,
          @vLevel            TLevel,
          @vLevelTmp         TLevel,
          @vEndLevel         TLevel,
          @vLevelMaxLength   TInteger,

          @vBayIncrement     TInteger,
          @vBay              TBay,
          @vBayTmp           TBay,
          @vEndBay           TBay,
          @vBayMaxLength     TInteger,

          @vIncrementLength  TInteger,
          @vLocation         TLocation;

  select @LocationFormat = coalesce(@LocationFormat,
                                    dbo.fn_Controls_GetAsString('Location', 'LocationFormat',
                                                                '<LocationType>-<Row>-<Section>-<Level>',
                                                                @BusinessUnit, @UserId));

  select @LocationFormat = replace(@LocationFormat, '<Aisle>', '<Row>'),
         @LocationFormat = replace(@LocationFormat, '<Slot>', '<Section>');

  /* Replace <LocationType>, <BusinessUnit>, if used in format */
  select @LocationFormat = @LocationFormat,
         /* Replace LocationType, if it is in format */
         @LocationFormat = replace(@LocationFormat, '<LocationType>', @LocationType),
         /* Replace BusinessUnit, if it is in format */
         @LocationFormat = replace(@LocationFormat, '<BusinessUnit>', @BusinessUnit),
         @LocationFormat = replace(@LocationFormat, '<Warehouse>',    @Warehouse);;

  if (PatIndex('%<Row>%',     @LocationFormat) = 0) and
     (PatIndex('%<Section>%', @LocationFormat) = 0) and
     (PatIndex('%<Level>%',   @LocationFormat) = 0) and
     (PatIndex('%<Bay>%',     @LocationFormat) = 0)
    /* Custom format */
    insert into @ttLocations(Location) select @LocationFormat;
  else
    /* Replace <Row>, <Section>, <Level>, if used in format */
    begin
      /* Set the Row details only when format has <Row> in it */
      if (PatIndex('%<Row>%', @LocationFormat) > 0)
        select @vRowIncrement = cast(@RowIncrement as integer),
               @vRowMaxLength = dbo.fn_Controls_GetAsInteger('Location', 'RowMaxLength',     3, @BusinessUnit, @UserId),
               @StartRow      = dbo.fn_pad(@StartRow, @vRowMaxLength),
               @EndRow        = dbo.fn_pad(@EndRow,   @vRowMaxLength);
      else
        select @StartRow      = null,
               @EndRow        = null;

      /* Set the Section details only when format has <Section> in it */
      if (PatIndex('%<Section>%', @LocationFormat) > 0)
        select @vSectionIncrement = cast(@SectionIncrement as integer),
               @vSectionMaxLength = dbo.fn_Controls_GetAsInteger('Location', 'SectionMaxLength', 3, @BusinessUnit, @UserId),
               @StartSection      = dbo.fn_pad(@StartSection, @vSectionMaxLength),
               @EndSection        = dbo.fn_pad(@EndSection,   @vSectionMaxLength);
      else
        select @StartSection  = null,
               @EndSection    = null;

      /* Set the Level details only when format has <Level> in it */
      if (PatIndex('%<Level>%', @LocationFormat) > 0)
        select @vLevelIncrement   = cast(@LevelIncrement   as integer),
               @vLevelMaxLength   = dbo.fn_Controls_GetAsInteger('Location', 'LevelMaxLength',   3, @BusinessUnit, @UserId),
               @StartLevel        = dbo.fn_pad(@StartLevel,   @vLevelMaxLength),
               @EndLevel          = dbo.fn_pad(@EndLevel,     @vLevelMaxLength);
      else
        select @StartLevel        = null,
               @EndLevel          = null;

     /* Set the Bay details only when format has <Bay> in it */
      if (PatIndex('%<Bay>%', @LocationFormat) > 0)
        select @vBayIncrement = cast(@BayIncrement as integer),
               @vBayMaxLength = dbo.fn_Controls_GetAsInteger('Location', 'BayMaxLength',     3, @BusinessUnit, @UserId),
               @StartBay      = dbo.fn_pad(@StartBay, @vBayMaxLength),
               @EndBay        = dbo.fn_pad(@EndBay,   @vBayMaxLength);
      else
        select @StartBay      = null,
               @EndBay        = null;

      /* Insert the locations into temporary table */
      set @vRow = rtrim(@StartRow);

      while (@vRow is null) /* to loop through atleast once */ or (@vRow <= @EndRow)
        begin
          select @vRowTmp     = @vRow,
                 @vSection    = rtrim(@StartSection),
                 @vEndSection = @EndSection;

          while (@vSection is null) /* to loop through atleast once */ or (@vSection <= @vEndSection)
            begin
              select @vSectionTmp = @vSection,
                     @vLevel      = rtrim(@StartLevel),
                     @vEndLevel   = @EndLevel;

              while (@vLevel is null) /* to loop through atleast once */ or (@vLevel <= @vEndLevel)
                begin
                  select @vLevelTmp = @vLevel,
                         @vBay      = rtrim(@StartBay),
                         @vEndBay   = @EndBay;

                  while (@vBay is null) /* to loop through atleast once */ or (@vBay <= @vEndBay)
                    begin
                      set @vBayTmp = @vBay;

                      /* Build Location string with Row, Section, Level and Bay */
                      select @vLocation = replace(@LocationFormat, '<Row>',     coalesce(@vRow, '')),
                             @vLocation = replace(@vLocation,      '<Section>', coalesce(@vSection, '')),
                             @vLocation = replace(@vLocation,      '<Level>',   coalesce(@vLevel, '')),
                             @vLocation = replace(@vLocation,      '<Bay>',     coalesce(@vBay, ''));

                      insert into @ttLocations(Location, LocationRow, LocationLevel, LocationSection, LocationBay)
                        select @vLocation, @vRow, @vLevel, @vSection, @vBay;

                      if (@vBay is not null)
                        begin
                          set @vIncrementLength = Len(@vBay);
                          exec pr_IncrementString @vBay, @vIncrementLength, @vBayIncrement, @BayCharSet,
                                              @vBay output;

                          /* Special Cases:
                             If the start value and the incremented value are the same
                             then append a character to the current value so that the loop exits.
                             This is true for row, section, level and Bay */
                          /* Bay could be null if the new Bay exceeds the length - like when current Bay is 9
                             and Bay Length is 1, then new Bay would be null - not 10 */
                          if ((@vBay = @vBayTmp) or (@vBayTmp = @EndBay))
                            set @vBay = 'Z' + coalesce(@vBay, 'ZZ');
                        end
                      else /* @vBay is null */
                        /* Special Cases:
                           If the Bay is null (As we are trying to loop through atleast once if the value is null)
                           then append a character to the current value so that the loop exits.
                           This is true for row, section, level and bay */
                        select @vBay = 'ZZ', @vEndBay = 'Z';
                    end /* while (@vBay <= @sEndBay) */

                  if (@vLevel is not null)
                    begin
                      set @vIncrementLength = Len(@vLevel);
                      exec pr_IncrementString @vLevel, @vIncrementLength, @vLevelIncrement, @LevelCharSet,
                                              @vLevel output;

                      /* Special Cases:
                         If the start value and the incremented value are the same
                         then append a character to the current value so that the loop exits.
                         This is true for row, section, and level. */
                      /* Level could be null if the new Level exceeds the length - like when current Level is 9
                         and Level Length is 1, then new level would be null - not 10 */
                      if ((@vLevel = @vLevelTmp) or (@vLevelTmp = @EndLevel))
                        set @vLevel = 'Z' + coalesce(@vLevel, 'ZZ');
                    end
                  else /* @vLevel is null */
                    /* Special Cases:
                       If the Level is null (As we are trying to loop through atleast once if the value is null)
                       then append a character to the current value so that the loop exits.
                       This is true for row, section, and level. */
                    select @vLevel = 'ZZ', @vEndLevel = 'Z';
                end /* while (@vLevel <= @sEndLevel) */

            if (@vSection is not null)
              begin
                set @vIncrementLength = Len(@vSection);
                exec pr_IncrementString @vSection, @vIncrementLength, @vSectionIncrement, @SectionCharSet,
                                        @vSection output;

                if ((@vSection = @vSectionTmp) or (@vSectionTmp = @EndSection))
                  set @vSection = 'Z' + coalesce(@vSection, 'ZZ');;
              end
            else
              select @vSection = 'ZZ', @vEndSection = 'Z';
          end /* while (@vSection <= @sEndSection) */

          if (@vRow is not null)
            begin
              set @vIncrementLength = Len(@vRow);
              exec pr_IncrementString @vRow, @vIncrementLength, @vRowIncrement, @RowCharSet,
                                      @vRow output;

              if ((@vRow = @vRowTmp) or (@vRowTmp = @EndRow))
                set @vRow = 'Z' + coalesce(@vRow, 'ZZ');
            end
          else
            select @vRow = 'ZZ', @EndRow = 'Z';
        end /* while (@vRow <= @EndRow) */
    end /* if LocationFormat consists of '<Row> or <Section> or <Level>' */

  /* Update LocationExists flag */
  update @ttLocations
  set LocationExists = case
                         when (L.LocationId is null) then
                           'N' /* No */
                         else
                           'Y' /* Yes */
                       end
  from @ttLocations TL
    left outer join Locations L on (TL.Location = L.Location);

  select * from @ttLocations;
end /* pr_Locations_Build */

Go
