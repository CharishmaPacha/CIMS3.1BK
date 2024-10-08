/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/20  RV      pr_Printing_GetSPLNotifications: Initial version
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_GetSPLNotifications') is not null
  drop Procedure pr_Printing_GetSPLNotifications;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_GetSPLNotifications: This procedures evaluates the Print List
    for SPL documents and checks for the carrier notification when we have an
    error generating carrier label. It returns the data in either #ResultMessages
    or returns as @ResultXML if input param BuildMessages = Yes
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_GetSPLNotifications
  (@BuildMessages  TFlags = 'Yes',
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @ResultXML      TXML = null output)
as
  declare @ttResultMessages       TResultMessagesTable,
          @ttResultData           TNameValuePairs,

          @vReturnCode            TInteger,
          @vMessageName           TMessageName;
begin
  select @vReturnCode   = 0,
         @vMessageName  = null;

  /* Create temp tables, if not already there */
  if (object_id('tempdb..#ResultMessages') is null) select * into #ResultMessages from @ttResultMessages;
  if (object_id('tempdb..#ResultData') is null)     select * into #ResultData from @ttResultData;

  /* Get the error nofifications for the small package labels to show to the end users */
  update PL
  set PL.Action        = 'I' /* Ignore */,
      PL.Notifications = SL.Notifications
  output 'E', inserted.Description + ' : ' + inserted.Notifications
  into #ResultMessages(MessageType, MessageText)
  from #PrintList PL
    join ShipLabels SL on (PL.EntityId = SL.EntityId)
  where (PL.DocumentType  = 'SPL') and (coalesce(PrintDataBase64, '') = '') and
        (SL.ProcessStatus = 'LGE') and (SL.Status = 'A');

  if (@BuildMessages = 'Yes')
    exec pr_Entities_BuildMessageResults null /* Entity */, null /* Action */, @ResultXML output;
end /* pr_Printing_GetSPLNotifications */

Go
