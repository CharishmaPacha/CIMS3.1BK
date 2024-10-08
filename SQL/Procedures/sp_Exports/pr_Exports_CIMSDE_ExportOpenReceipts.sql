/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/03  SV      pr_Exports_CIMSDE_ExportOpenOrders, pr_Exports_CIMSDE_ExportOpenReceipts, pr_Exports_OnhandInventory:
  2018/03/21  SV      pr_Exports_CIMSDE_ExportOpenOrders, pr_Exports_CIMSDE_ExportOpenReceipts:
                      pr_Exports_CIMSDE_ExportOpenReceipts, pr_Exports_CIMSDE_ExportShippedLoads (CIMSDE-35)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CIMSDE_ExportOpenReceipts') is not null
  drop Procedure pr_Exports_CIMSDE_ExportOpenReceipts;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CIMSDE_ExportOpenReceipts:

  This procedure will return the Open Receipts
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CIMSDE_ExportOpenReceipts
  (@SourceSystem   TName         = null,
   @BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = null)
as
  declare @vReturnCode       TInteger,
          @vRecordType       TTypeCode,
          @vOpenReceiptsXML  xml,

          @vMessage          TNVarchar,
          @vSourceReference  TDescription,
          @vResultXML        TXML;
begin
begin try
  set NOCOUNT ON;

  /* initialize */
  select @vRecordType = 'OR' /* Open Receipts */;

  /* Build xml here with the all open receipts in CIMS  */
  select @vOpenReceiptsXML = (select distinct @vRecordType as RecordType, ReceiptNumber, ReceiptType,
                                              VendorId, Vessel, Warehouse, Ownership, ContainerNo,
                                              RH_UDF1, RH_UDF2, RH_UDF3, RH_UDF4, RH_UDF5, HostReceiptLine, CustPO, SKU, SKU1, SKU2,
                                              SKU3, SKU4, SKU5, CoO, UnitCost, QtyOrdered, QtyIntransit, QtyReceived,
                                              QtyToReceive, RD_UDF1, RD_UDF2, RD_UDF3, RD_UDF4, RD_UDF5,
                                              RD_UDF6, RD_UDF7, RD_UDF8, RD_UDF9, RD_UDF10,
                                              vwORE_UDF1, vwORE_UDF2, vwORE_UDF3, vwORE_UDF4, vwORE_UDF5,
                                              vwORE_UDF6, vwORE_UDF7, vwORE_UDF8, vwORE_UDF9, vwORE_UDF10,
                                              SourceSystem, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy
                              from vwOpenReceipts
                              where (BusinessUnit = @BusinessUnit) and
                                    (coalesce(SourceSystem, 'HOST') = coalesce(@SourceSystem, 'HOST'))
                              FOR XML PATH('ReceiptInfo'), ROOT('ExportOpenReceipts'));

  /* convert xml data to varchar */
  select @vResultXML = convert(varchar(max), @vOpenReceiptsXML);

  /* Push the list of Open Receipts into CIMSDE database */
  exec CIMSDE_pr_PushExportOpenReceiptsFromCIMS @vResultXML, @UserId, @BusinessUnit;

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
end /* pr_Exports_CIMSDE_ExportOpenReceipts */

Go
