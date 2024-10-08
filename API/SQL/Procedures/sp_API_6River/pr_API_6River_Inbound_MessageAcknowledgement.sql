/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/21  TK      pr_API_6River_Inbound_MessageAcknowledgement: Initial Revision (CID-1630)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Inbound_MessageAcknowledgement') is not null
  drop Procedure pr_API_6River_Inbound_MessageAcknowledgement;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Inbound_MessageAcknowledgement
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Inbound_MessageAcknowledgement
  (@TrasactionRecordId   TRecordId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_6River_Inbound_MessageAcknowledgement */
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
end /* pr_API_6River_Inbound_MessageAcknowledgement */

Go
