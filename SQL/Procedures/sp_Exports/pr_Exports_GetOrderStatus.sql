/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/09  VS      pr_Exports_GetOrderStatus: Enhance pr_Exports_GetOrderStatus to handle OPENXML (S2GCA-140)
  2017/02/19  AY      pr_Exports_GetOrderStatus: Allow cancelled Order to be updated
  2016/09/27  AY      pr_Exports_GetOrderStatus: Excluded 'NQ' to not consider for UDF10 (HPI-GoLive)
  2016/09/15  AY      pr_Exports_GetOrderStatus: Added debug info (HPI-GoLive)
  2016/09/09  AY      pr_Exports_GetOrderStatus: Do not allow changes to Engraving orders once printed.
  2016/08/23  AY      pr_Exports_GetOrderStatus: Enh. to return Wave Status as well.
  2016/08/04  AY      pr_Exports_GetOrderStatus: Report different status to Host for Shipped/Cancelled orders.
  2016/08/01  AY      pr_Exports_GetOrderStatus: If Order is waved and wave is released it should not allow update
  2016/06/20  AY      pr_Exports_GetOrderStatus: Cannot use vwOrderHeader as it is excludes Downloaded Orders
  2016/05/11  OK      pr_Exports_GetOrderStatus: Added the new procedure and its wrapper procedure for HPI (HPI-108)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_GetOrderStatus') is not null
  drop Procedure pr_Exports_GetOrderStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_GetOrderStatus:
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_GetOrderStatus
  (@xmlData    xml = null,
   @xmlResult  xml = null output)
as
  /* Local variables for output params */
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription;

  declare @vxmlData         TXML,
          @vxmLResult       TXML,
          @vPickTicket      TPickTicket,
          @vReturnCode      TDescription,
          @vXmlDocHandle    Int;

  declare @ttInputOrders table (Action       TAction,
                                SalesOrder   TSalesOrder,
                                PickTicket   TPickTicket,
                                Ownership    TOwnership,
                                BusinessUnit TBusinessUnit);

  declare @ttResults table (SalesOrder   TSalesOrder,
                            PickTicket   TPickTicket,
                            Status       TDescription,
                            WaveStatus   TDescription,
                            ReturnCode   TInteger);
begin
begin try
  set NOCOUNT ON;

  select @ReturnCode    = 0,
         @MessageName   = null,
         @xmlResult     = null;

  /* If no input, then exit */
  if (@xmlData is null)
    return;

  exec sp_xml_preparedocument @vXmlDocHandle output, @xmlData;

  /* Insert all the Order info into temp table*/
  insert into @ttInputOrders (Action, SalesOrder, PickTicket, Ownership, BusinessUnit)
    select * from
    OPENXML(@vXmlDocHandle, '//msg/msgBody/Record', 2)
    With (Action       TAction,
          SalesOrder   TSalesOrder,
          PickTicket   TPickTicket,
          Ownership    TOwnership,
          BusinessUnit TBusinessUnit);

  /* Populate the result temp table */
  insert into @ttResults (SalesOrder, PickTicket, Status, WaveStatus, ReturnCode)
    select ttIO.SalesOrder,
           ttIO.PickTicket,
           coalesce(OS.StatusDescription, OH.Status),
           coalesce(WS.StatusDescription, WS.Status),
           case when (OH.OrderId is null) then - 1 /* Does not exist */
                --when (OH.PickTicket <> ttIO.PickTicket /* Incase invalid PickTicket */)) then -1
                when OH.Status in ('X' /* Cancelled */) then 0  /* Available to update */
                when OH.Status in ('O','N' /* Downloaded, New */) then 0  /* Available to update */
                /* If Order is waved, then it can only be updated if the Wave is not yet released */
                when OH.Status = 'W' /* Waved */ and PB.Status = 'N' /* New */ then 0 /* Available to update */
                else 1 /* Available, but cannot update */
           end
    from @ttInputOrders ttIO
         left outer join OrderHeaders OH on (OH.PickTicket   = ttIO.PickTicket  ) and
                                            (OH.BusinessUnit = ttIO.BusinessUnit)
         left outer join Statuses     OS on (OS.StatusCode   = OH.Status        ) and
                                            (OS.Entity       = 'Order'          ) and
                                            (OS.BusinessUnit = OH.BusinessUnit  )
         left outer join PickBatches  PB on (OH.PickBatchNo  = PB.BatchNo       ) and
                                            (OH.BusinessUnit = PB.BusinessUnit  )
         left outer join Statuses     WS on (WS.StatusCode   = PB.Status        ) and
                                            (WS.Entity       = 'PickBatch'      );

  /* Build and return the XML */
  set @XmlResult = (select 'SalesOrder'              as RecordType,
                           coalesce(PickTicket,  '') as KeyData,
                           coalesce(Status,      '') +
                           coalesce(', Wave Status: ' + WaveStatus, '')
                                                     as Status,
                           coalesce(ReturnCode,  '') as ReturnCode
                    from @ttResults
                    FOR XML RAW('Results'), ELEMENTS);

  /*  Append msg node*/
  select @XmlResult = '<msg>' + convert(varchar(max), @XmlResult) + '</msg>';

  select @vXMLData   = convert(varchar(max), @xmlData),
         @vXMLResult = convert(varchar(max), @XMLResult);

  select @vPickTicket = PickTicket,
         @vReturnCode = ReturnCode
  from @ttResults;

 -- exec pr_ActivityLog_AddOrUpdate 'OrderHeader', null, @vPickTicket /* Entity */, 'GetOrderStatus' /* Operation */,
 --                                 @vReturnCode /* Message */, @vxmlData /* xmldata */, @vxmlResult /* xmlresult */, Default /* DeviceId */,
 --                                 'CIMSAgent'/* UserId */;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

end try
begin catch
  /* Catch the errors into output XML */
  select @XmlResult  = (select Error_Message() as Error for xml path(''), root('Errors')),
         @ReturnCode = -1; /* Error */

end catch;
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_GetOrderStatus */

Go
