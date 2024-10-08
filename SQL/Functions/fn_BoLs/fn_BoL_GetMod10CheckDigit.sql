/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_BoL_GetMod10CheckDigit') is not null
  drop Function fn_BoL_GetMod10CheckDigit;
Go
/*------------------------------------------------------------------------------
  fn_BoL_GetMod10CheckDigit :

------------------------------------------------------------------------------*/
Create Function fn_BoL_GetMod10CheckDigit
  (@Barcode   TBarcode)
------------------------------
   returns     TVarChar
as
begin
  declare @CheckDigit    TVarchar,
          @OddDigitSum   Int,
          @EvenDigitSum  Int,
          @DigitPosition Int;

  select @DigitPosition = 1,
         @CheckDigit    = 0,
         @OddDigitSum   = 0,
         @EvenDigitSum  = 0;

  /* Get the sum of even and odd digits */
  while (@DigitPosition <= Len(@Barcode))
    begin
      if (@DigitPosition % 2 = 1)
        select @OddDigitSum = @OddDigitSum + substring(@Barcode, @DigitPosition, 1);
      else
        select @EvenDigitSum = @EvenDigitSum + substring(@Barcode, @DigitPosition, 1);

      set @DigitPosition = @DigitPosition + 1;
    end

  /* Compute the Check Digit */
  select @CheckDigit = 10 - (((@EvenDigitSum * 3) +  @OddDigitSum) % 10);

  /* If there is no remainder then the check digit will become 10.
     We need to set the value with zero. */
  if (@CheckDigit = 10)
    set @CheckDigit = 0;

  return (@CheckDigit)
end /* fn_BoL_GetMod10CheckDigit */

Go
