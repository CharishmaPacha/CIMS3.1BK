/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/13  TK      pr_API_6River_Outbound_GroupCancel_GetMsgData & pr_API_6River_Outbound_GroupUpdate_GetMsgData:
  2020/11/12  TK      pr_API_6River_Outbound_GroupUpdate_GetMsgData: Initial Revision (CID-1514)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Outbound_GroupUpdate_GetMsgData') is not null
  drop Procedure pr_API_6River_Outbound_GroupUpdate_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Outbound_GroupUpdate_GetMsgData generates Group update data in JSON format for the given entity
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Outbound_GroupUpdate_GetMsgData
  (@IntegrationName    TName,
   @MessageType        TName,
   @EntityType         TTypeCode,
   @EntityId           TRecordId,
   @EntityKey          TEntityKey,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @MessageData        TVarchar   output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vFieldList              TVarchar,
          @vSQLQuery               TNVarChar;
begin /* pr_API_6River_Outbound_GroupUpdate_GetMsgData */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Build Message Type */
  select top 1 @MessageType = @MessageType + '_' + BatchType
  from OrderHeaders OH
    join Waves W on (W.RecordId = OH.PickBatchId)
  where (OrderId = @EntityId);

  /* Get the Field List to generate wave data */
  exec pr_API_GetInterfaceFields @IntegrationName, @MessageType, @BusinessUnit, @vFieldList out;

  /* Build Query with task details of Orders to be exported */
  select @vSQLQuery = 'select @ResultParam =
                       (select distinct ' + @vFieldList + '
                        from vwUIPickTaskDetails
                        where OrderId = ' + cast(@EntityId as varchar) + ' and
                              UnitsToPick > 0
                        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)';

  /* Execute SQL query */
  exec sp_executesql @vSQLQuery,
                     N'@ResultParam varchar(max) output',
                     @ResultParam = @MessageData output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_6River_Outbound_GroupUpdate_GetMsgData */

Go
