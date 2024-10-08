/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/16  VM      pr_DBAdmin_GetRandomString: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DBAdmin_GetRandomString') is not null
  drop Procedure pr_DBAdmin_GetRandomString;
Go
/*------------------------------------------------------------------------------
  pr_DBAdmin_GetRandomString:
  To get a random string to use it for passwords
------------------------------------------------------------------------------*/
Create Procedure pr_DBAdmin_GetRandomString
  (@Length       TDescription,
   @RandomString TDescription output)
as
  declare @charI         TInteger     = 0,
          @char          char         = '',
          @vRandomString TDescription = '';
begin
  while (@Length > 0)
    begin
      select @charI = ROUND(RAND()*100, 0);
      select @char = CHAR(@charI);

      if (@charI > 48) and (@charI < 122) and (@charI not in (59, 60, 62, 92, 96)) -- avoid <>/`
        begin
          select @vRandomString += @char,
                 @Length         = (@Length  - 1);
        end
    end

  select @RandomString = @vRandomString;
end  /* pr_DBAdmin_GetRandomString */

Go
