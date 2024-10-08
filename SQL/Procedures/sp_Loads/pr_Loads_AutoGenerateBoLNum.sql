/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/28  MS      Added pr_Loads_AutoGenerateBoLNum
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_AutoGenerateBoLNum') is not null
  drop Procedure pr_Loads_AutoGenerateBoLNum;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_AutoGenerateBoLNum:
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_AutoGenerateBoLNum
  (@BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TMessage,
          @vErrorMsg         TMessage,
          @vRecordId         TRecordId,

          @vVICSBoLNumber    TVICSBoLNumber,
          @vBoLNumber        TBoLNumber,
          @vLoadId           TRecordId;

begin /* pr_Loads_AutoGenerateBoLNum */
  SET NOCOUNT ON;

  select @vRecordId    = 0,
         @vMessageName = null,
         @vMessage     = null;

  /* If there are no records then do not process */
  if (not exists(select * from #LoadsToAutoShip))
    goto Exithandler;

  /* Update the Loads that are going to be Autoshipped with Flag N */
  update #LoadsToAutoShip set BolNumGenerated = 'N' where ProcessFlag = 'Y';

  while exists(select * from #LoadsToAutoShip where (BolNumGenerated = 'N'))
    begin
      /* Generate a VICSBoLNumber */
      exec pr_BoL_GetVICSBoLNo @BusinessUnit, @vVICSBoLNumber output, @vBoLNumber output;

      select @vLoadId = LoadId
      from #LoadsToAutoShip
      where (BoLNumGenerated = 'N');

      /* Update Load with MasterBolNum generated */
      update Loads
      set MasterBoL    = @vVICSBoLNumber,
          ModifiedDate = current_timestamp
      from Loads L
      where (L.LoadId = @vLoadId);

      update #LoadsToAutoShip set BolNumGenerated = 'Y' where (LoadId = @vLoadId);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_AutoGenerateBoLNum */

Go
