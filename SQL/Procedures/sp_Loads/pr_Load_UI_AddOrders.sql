/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_Loads_AutoBuild, pr_Load_UI_AddOrders: Pass the Operation parm to pr_Load_AddOrders
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_UI_AddOrders') is not null
  drop Procedure pr_Load_UI_AddOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_UI_AddOrders: Adds the given Orders to the Loads by
       calling pr_Load_UI_AddOrders proc for each order
------------------------------------------------------------------------------*/
Create Procedure pr_Load_UI_AddOrders
  (@LoadNumber    TLoadNumber,
   @xmlOrders     TXML,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @LoadRecount   TFlag = 'N',
   -------------------------------------------
   @TotalOrders   TCount       = null output,
   @AddedOrders   TCount       = null output,
   @Message       TDescription = null output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @vOrders           XML,
          @ttOrders          TEntityKeysTable;
begin  /* pr_Load_UI_AddOrders */
  select @AddedOrders = 0,
         @ReturnCode  = 0,
         @MessageName = null,
         @Message     = null;

  /* When we have TableVar as input param , It is raising error when we trying to call
    the procedure from UI. So we just overiding the proc by passing different DataType
    Error : Error 1 DBML1005: Mapping between DbType 'Structured' and Type 'System.Object'
    in Parameter 'TableOrders' of Function 'dbo.pr_Load_AddOrders' is not supported.    0 0
  */

  if (coalesce(@xmlOrders, '') <> '')
    begin
      select @vOrders = convert(xml, @xmlOrders)

      insert into @ttOrders(EntityId)
        select Record.Col.value('(OrderId/text())[1]', 'TRecordId')
        from @vOrders.nodes('/Orders/OrderHeader') as Record(Col)

      /* Call the add orders procedure with tablevar type input */
      exec pr_Load_AddOrders @LoadNumber,
                             @ttOrders,
                             @BusinessUnit,
                             @UserId,
                             @LoadRecount,
                             'UI_Loads_AddOrders',
                             @TotalOrders  output,
                             @AddedOrders  output,
                             @Message      output;
    end

ErrorHandler:
  exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_UI_AddOrders */

Go
