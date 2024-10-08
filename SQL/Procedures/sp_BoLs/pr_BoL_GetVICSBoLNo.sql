/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_GetVICSBoLNo') is not null
  drop Procedure pr_BoL_GetVICSBoLNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_GetVICSBoLNo
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_GetVICSBoLNo
  (@BusinessUnit  TBusinessUnit,
   ---------------------------------------
   @VICSBoLNumber   TVICSBoLNumber output,
   @VICSBoLSequence TBoLNumber     output)
as
  declare @vUserId           TUserId,
          @vCompanyId        TControlValue,
          @vSeqNumber        varchar(9),
          @vNextSeqNo        int,
          @vSeqNoCount       int,
          @vCheckDigit       varchar(1);
begin
  /* Assiging values to declared variables */
  select @vUserId    = System_User,
         @vCompanyId = dbo.fn_Controls_GetAsString ('VICSBoL', 'CompanyId', '0123456' /* Default */, @BusinessUnit, @vUserId),
         @vSeqNoCount = 1;

  exec pr_Controls_GetNextSeqNoStr 'VICSBoLSequence', @vSeqNoCount,
                                   @vUserId, @BusinessUnit,
                                   @VICSBolSequence output;

  set @vCheckDigit = dbo.fn_BoL_GetMod10CheckDigit(@vCompanyId+@VICSBolSequence);

  select @VICSBoLNumber = @vCompanyId + @VICSBolSequence + @vCheckDigit;
end /* pr_BoL_GetVICSBoLNo */

Go
