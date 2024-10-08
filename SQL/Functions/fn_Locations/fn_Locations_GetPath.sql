/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2011/11/03  YA      Added funtion 'fn_Locations_GetPath', Regarding PickPath.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Locations_GetPath') is not null
  drop Function fn_Locations_GetPath;
Go
/*------------------------------------------------------------------------------
  fn_Locations_GetPickPath:
  Function that returns the PickPath for the given location based on the given format.
  Returns the same Location, if format is null.

  ** @PickPathFormats for Loehmanns could be
     <LocationType>-<Row>-<Section>-<Level>
     <LocationType>-<OddRow-1>-<Section>-<Level>
     <LocationType>-<OddRow+1>-<Section>-<Level>

  ** WARNING!!! This function currently support Loehmann's only.
------------------------------------------------------------------------------*/
Create Function fn_Locations_GetPath
  (@Location           TLocation,
   @PathFormat         TLocationPath,
   @PathType           TString,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
  ----------------------------------
   returns             TLocation
as
begin
  declare @vLocationId       TRecordId,
          @vLocationPrefix   TFlag,
          @vRow              TRow,
          @vSection          TSection,
          @vLevel            TLevel,
          @vsRow             TRow,
          @vsBay             TBay,
          @vsMaxBay          TBay,
          @vsBayReverse      TBay,
          @vsSection         TSection,
          @vsSectionReverse  TSection,
          @vsMaxSection      TSection,
          @vsLevel           TLevel,
          @viRow             TInteger,
          @viSection         TInteger,
          @viLevel           TInteger,
          @vRowMaxLength     TInteger,
          @vIsRowOdd         TBoolean,
          @vIsLevelOdd       TBoolean,
          @vIsSectionOdd     TBoolean,
          @viPickRow         TRow,
          @vLocationPath     TLocationPath;

  /* If no pick path format is given get from control var */
  if (@PathFormat is null)
    select @vLocationPath = dbo.fn_Controls_GetAsString('Location', @PathType,'<LocationType><Row>-<Section>', @BusinessUnit, @UserId);

  /* Assuming that for Loehmann's the format of the location is <LocationPrefix>-<Row>-<Level>-<Section>,
     retreive all attributes of given location.
     ex: K15-1-003 */
  select @vLocationId     = LocationId,
         @vLocationPrefix = LocationType,
         @vsRow           = LocationRow,
         @vsBay           = LocationBay,
         @vsLevel         = LocationLevel,
         @vsSection       = LocationSection
  from Locations
  where (Location = @Location);

  if (@Pathformat like '%<BayRev>%')
    begin
      select @vsMaxBay = Max(LocationBay)
      from Locations
      where (LocationType = @vLocationPrefix and LocationRow = @vsRow) and Status in ('E', 'U')

      select @vsBayReverse = cast(@vsMaxBay as int) - cast(@vsBay as int) + 1;
      select @vsBayReverse = dbo.fn_Pad(@vsBayReverse, len(@vsBay));
    end

  if (@Pathformat like '%<SectionRev>%')
    begin
      select @vsMaxSection = Max(LocationSection)
      from Locations
      where (LocationType = @vLocationPrefix and LocationRow = @vsRow) and
            (Status in ('E', 'U'))  and
            (LocationBay = @vsBay);

      select @vsSectionReverse = cast(@vsSection as int) - cast(@vsSection as int) + 1;
      select @vsSectionReverse = dbo.fn_Pad(@vsSectionReverse, len(@vsSection));
    end

  /* If Row/Section/level are not numeric and the PickPathformat determines that
     we need to add or subtract to them then return null as we cannot comply with
     the format */
  if ((IsNumeric(@vsRow)=0) and
      ((@PathFormat like '%Row+1%') or
       (@PathFormat like '%Row-1%')))
      or
     ((IsNumeric(@vsLevel)=0) and
      ((@PathFormat like '%Level+1%') or
       (@PathFormat like '%Level-1%')))
      or
     ((IsNumeric(@vsSection)=0) and
      ((@PathFormat like '%Section+1%') or
       (@PathFormat like '%Section-1%')))
    return (null);

  select @vRowMaxLength = dbo.fn_Controls_GetAsInteger('Location', 'RowMaxLength', 3, @BusinessUnit, @UserId);

  select @vLocationPath     = coalesce (@PathFormat, @vLocationPath),
         @vIsRowOdd         = null,
         @vIsLevelOdd       = null,
         @vIsSectionOdd     = null;

  /* convert row to numeric if required only i.e. pick path format has + or - */
  if ((@PathFormat like '%Row+1%') or
      (@PathFormat like '%Row-1%'))
    begin
      /* Obviously, if we got here, it means vsRow is numeric, or else we would
         have exit early on */
      select @viRow     = @vsRow,
             @vIsRowOdd = @viRow % 2;

      /* Compute PickRow */
      select @viPickRow = Case
                            when (@vIsRowOdd = 1) and (@PathFormat like '%OddRow+1%') then
                              @viRow + 1
                            when (@vIsRowOdd = 1) and (@PathFormat like '%OddRow-1%') then
                              @viRow - 1
                            when (@vIsRowOdd = 0) and (@PathFormat like '%EvenRow+1%') then
                              @viRow + 1
                            when (@vIsRowOdd = 0) and (@PathFormat like '%EvenRow-1%') then
                              @viRow - 1
                            else
                              @viRow
                          end;

      /* Pad zeroes to row based on max length */
      select @vsRow          =  dbo.fn_LeftPadNumber(@viPickRow, @vRowMaxLength);
    end

  /* Future use.... ToDo */
  /* convert level to numeric if required only i.e. pick path format has + or - */
  if ((@PathFormat like '%Level+1%') or
      (@PathFormat like '%Level-1%'))
    begin
      select @viLevel     = @vsLevel,
             @vIsLevelOdd = @viLevel % 2;
    end

  /* Future use.... ToDo */
  /* convert section to numeric if required only i.e. pick path format has + or - */
  if ((@PathFormat like '%Section+1%') or
      (@PathFormat like '%Section-1%'))
    begin
      select @viSection     = @vsSection,
             @vIsSectionOdd = @viSection % 2;
    end

  /* Update Location Pick Path to return */
  select @vLocationPath = replace(@vLocationPath, '<LocationType>', @vLocationPrefix),
         /* One of these possibilities for Row will be in the format */
         @vLocationPath = replace(@vLocationPath, '<Row>',          @vsRow),
         @vLocationPath = replace(@vLocationPath, '<OddRow+1>',     @vsRow),
         @vLocationPath = replace(@vLocationPath, '<OddRow-1>',     @vsRow),
         @vLocationPath = replace(@vLocationPath, '<EvenRow+1>',    @vsRow),
         @vLocationPath = replace(@vLocationPath, '<EvenRow-1>',    @vsRow),
         @vLocationPath = replace(@vLocationPath, '<Section>',      @vsSection),
         @vLocationPath = replace(@vLocationPath, '<Level>',        @vsLevel),
         @vLocationPath = replace(@vLocationPath, '<Bay>',          @vsBay),
         @vLocationPath = replace(@vLocationPath, '<BayRev>',       coalesce(@vsBayReverse, '')),
         @vLocationPath = replace(@vLocationPath, '<SectionRev>',   coalesce(@vsSectionReverse, ''));

  /* if for whatever reason LocationPath is null, then initialize to Location */
  return(coalesce(@vLocationPath, @Location));
end /* fn_Locations_GetPath */

Go
