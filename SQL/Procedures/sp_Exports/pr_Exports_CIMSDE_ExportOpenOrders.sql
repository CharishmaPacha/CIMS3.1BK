/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/03  SV      pr_Exports_CIMSDE_ExportOpenOrders, pr_Exports_CIMSDE_ExportOpenReceipts, pr_Exports_OnhandInventory:
                      pr_Exports_CIMSDE_ExportData, pr_Exports_CIMSDE_ExportOnhandInventory, pr_Exports_CIMSDE_ExportOpenOrders, pr_Exports_CIMSDE_ExportOpenOrders
  2018/03/21  SV      pr_Exports_CIMSDE_ExportOpenOrders, pr_Exports_CIMSDE_ExportOpenReceipts:
  2017/12/08  SV      Added pr_Exports_CIMSDE_ExportInventory, pr_Exports_CIMSDE_ExportOpenOrders
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CIMSDE_ExportOpenOrders') is not null
  drop Procedure pr_Exports_CIMSDE_ExportOpenOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CIMSDE_ExportOpenOrders: Procedure will push Open Orders
    to CIMSDE.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CIMSDE_ExportOpenOrders
  (@SourceSystem   TName         = null,
   @BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = null)
as
  declare @vReturnCode      TInteger,
          @vRecordType      TTypeCode,
          @vOpenOrdersXML   xml,

          @vMessage         TNVarchar,
          @vSourceReference TDescription,
          @vResultXML       TXML;
begin
begin try
  set NOCOUNT ON;

  /* Initialize */
  select @vRecordType = 'OO' /* Open Orders */;

  /* Build xml here witn the open orders in CIMS  */
  select @vOpenOrdersXML = (select distinct @vRecordType as RecordType, PickTicket, SalesOrder, OrderTypeDescription as OrderType,
                                            StatusDescription as Status, CancelDate, DesiredShipDate, SoldToId, ShipToId, ShipFrom, ShipVia,
                                            CustPO, Ownership, Warehouse, Account, HostOrderLine, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
                                            Lot, UnitsOrdered, UnitsAuthorizedToShip, UnitsReserved, UnitsNeeded, UnitsShipped,
                                            UnitsRemainToShip, OH_UDF1, OH_UDF2, OH_UDF3, OH_UDF4, OH_UDF5, OH_UDF6, OH_UDF7, OH_UDF8, OH_UDF9,
                                            OH_UDF10, OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
                                            vwOOE_UDF1, vwOOE_UDF2, vwOOE_UDF3, vwOOE_UDF4, vwOOE_UDF5, vwOOE_UDF6, vwOOE_UDF7, vwOOE_UDF8, vwOOE_UDF9, vwOOE_UDF10,
                                            SourceSystem, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy
                            from vwOpenOrders
                            where (BusinessUnit = @BusinessUnit) and
                                  (coalesce(SourceSystem, 'HOST') = coalesce(@SourceSystem, 'HOST'))
                            FOR XML PATH('OrderInfo'), ROOT('ExportOpenOrders'));

  /* convert xml data to varchar */
  select @vResultXML = convert(varchar(max), @vOpenOrdersXML);

  /* Push the list of Open Orders into CIMSDE database */
  exec CIMSDE_pr_PushExportOpenOrdersFromCIMS @vResultXML, @UserId, @BusinessUnit;

end try
begin catch
  /* log into Interface table with the failure message for tracking/Research */
  select @vMessage         = Error_Message(),
         @vSourceReference = Object_Name(@@ProcId);

  /* Save the exceptions to InterfaceLog tables so that users can be alerted of the failure */
  exec pr_InterfaceLog_SaveExceptions 'CIMS' /* Source System */, 'CIMSDE' /* Target System */,
                                      @vSourceReference, 'Export' /* Transfer Type */,
                                      'End' /* Process Type */, 'DB' /* RecordTypes */,
                                      @BusinessUnit, @vMessage;

  /* raise an exception if there is any */
  exec pr_ReRaiseError;

end catch;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_CIMSDE_ExportOpenOrders */

Go
