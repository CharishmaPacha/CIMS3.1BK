/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_AutoCloseReceivers') is not null
  drop Procedure pr_Receivers_AutoCloseReceivers;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_AutoCloseReceivers:
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_AutoCloseReceivers
  (@BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReceiverNo     TReceiverNumber,
          @vRecordId       TRecordId,
          @vXMLData        XML,
          @vXMLHeaders     XML,
          @vReturnCode     TInteger;

  /* Declaring the temp table to hold the Receivers */
  declare @ttReceivers     TEntityKeysTable;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @vReturnCode = 0;

  /* select all receivers which are in open status */
  insert into @ttReceivers (EntityId, EntityKey)
    select ReceiverId, ReceiverNumber
    from Receivers R
    where (R.Status       = 'O' /* Open */) and
          (R.BusinessUnit = @BusinessUnit);

  /* Build the list of Receivers to close as XML */
  set @vXMLData = (select EntityKey as ReceiverNo
                   From @ttReceivers
                   for XML RAW(''), TYPE, ELEMENTS XSINIL, ROOT('Data'));

  /* Build XML Header with Entity and Action */
  set @vXMLHeaders = dbo.fn_XMLNode('Entity', 'Receiver') +
                     dbo.fn_XMLNode('Action', 'Close');

  select @vXMLData = dbo.fn_XMLNode('Root', convert(varchar(max), @vXMLHeaders) + convert(varchar(max), @vXMLData));

  /* Call the procedure to Validate Receivers and Close receivers */
  exec pr_Receivers_Close @vXMLData , @BusinessUnit, @UserId;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @vReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_AutoCloseReceivers */

Go
