/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/08  SV      Added pr_Exports_CIMSDE_ExportInventory, pr_Exports_CIMSDE_ExportOpenOrders
                        pr_Exports_CIMSDE_ExportOpenReceipts, pr_Exports_CIMSDE_ExportShippedLoads (CIMSDE-35)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CIMSDE_ExportShippedLoads') is not null
  drop Procedure pr_Exports_CIMSDE_ExportShippedLoads;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CIMSDE_ExportShippedLoads:

  This procedure will return the Shipped Loads.
  We can't export ShippedLoads with a SourceSystem. This is because, a load can
    hold Orders from different SourceSystems.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CIMSDE_ExportShippedLoads
  (@BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = null)
as
  declare @vReturnCode       TInteger,
          @vRecordType       TTypeCode,
          @vShippedLoadsXML  xml,

          @vMessage          TNVarchar,
          @vSourceReference  TDescription,
          @vResultXML        TXML;
begin
begin try
  set NOCOUNT ON;

  /* Initialize */
  select @vRecordType = 'SL' /* Shipped Loads */;

  /* Fetch the Loads shipped today into XML */
  select @vShippedLoadsXML = (select distinct @vRecordType as RecordType, LoadNumber, PickTicket, SalesOrder, SoldToId,
                                              ShipToId, LPN, Pallet, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
                                              '' as LPNId, '' as LPNDetailId, '' as Lot, UnitsShipped, UDF1,
                                              UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10,
                                              BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy
                              from vwShippedLoads
                              where (BusinessUnit = @BusinessUnit)
                              FOR XML PATH('LoadInfo'), ROOT('ExportShippedLoads'));

  /* convert xml data to varchar */
  select @vResultXML = convert(varchar(max), @vShippedLoadsXML);

  /* Push the list of Loads Shipped today into CIMSDE database */
  exec CIMSDE_pr_PushExportShippedLoadsFromCIMS @vResultXML, @UserId, @BusinessUnit;

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
end /* pr_Exports_CIMSDE_ExportShippedLoads */

Go
