/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/09  OK      pr_Loads_AutoCancel: Added to cancel all the unused Loads
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_AutoCancel') is not null
  drop Procedure pr_Loads_AutoCancel;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_AutoCancel: Procedure used to automtically cancel loads which were
    created automatically but not used.
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_AutoCancel
  (@LoadTypes       TString,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vRecordId         TRecordId,

          @ttLoadsToCancel   TEntityValuesTable;

  declare @ttResultMessages  TResultMessagesTable;
  declare @ttLoadTypes Table  /* Temp table to hold LoadTypes */
          (LoadType        TTypeCode);

begin /* pr_Load_AutoCancel */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select * into #ttSelectedEntities from @ttLoadsToCancel;
  select * into #ResultMessages from @ttResultMessages;

  /* Get list of LoadTypes to cancel */
  if (@LoadTypes is not null)
    insert into @ttLoadTypes
      select Value from fn_ConvertStringToDataSet (@LoadTypes, ',');

  insert into #ttSelectedEntities (EntityId, EntityKey, RecordId)
    select LoadId, LoadNumber, LoadId
    from Loads L
      join @ttLoadTypes ttLT on L.LoadType = ttLT.LoadType
    where (NumOrders = 0) and
          (Status    = 'N') and
          (CreatedBy = coalesce(@UserId, CreatedBy));

  /* Cancel the Loads */
  exec pr_Loads_Action_Cancel null /* @xmlData */, @BusinessUnit, @UserId;

  /* Archive the Loads that were canceled */
  update LD
  set Archived = 'Y'
  from Loads LD join #ttSelectedEntities SE on LD.LoadId = SE.EntityId
  where (LD.Status = 'X');

end /* pr_Loads_AutoCancel */

Go
