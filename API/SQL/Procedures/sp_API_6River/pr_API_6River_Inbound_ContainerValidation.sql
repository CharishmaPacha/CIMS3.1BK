/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Inbound_ContainerValidation') is not null
  drop Procedure pr_API_6River_Inbound_ContainerValidation;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Inbound_ContainerValidation: Validates the Tote or Ship Carton
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Inbound_ContainerValidation
  (@TrasactionRecordId   TRecordId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_6River_Inbound_ContainerValidation */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  return;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_6River_Inbound_ContainerValidation */

Go
