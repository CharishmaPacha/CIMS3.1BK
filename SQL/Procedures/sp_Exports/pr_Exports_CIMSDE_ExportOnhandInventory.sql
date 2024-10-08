/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_Exports_CIMSDE_ExportOnhandInventory:Added Ownership and Warehouse as parameters as we do have
  pr_Exports_CIMSDE_ExportData, pr_Exports_CIMSDE_ExportOnhandInventory, pr_Exports_CIMSDE_ExportOpenOrders, pr_Exports_CIMSDE_ExportOpenOrders
  2018/01/31  SV      pr_Exports_CIMSDE_ExportInventory: Renamed to pr_Exports_CIMSDE_ExportOnhandInventory (S2G-188)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CIMSDE_ExportOnhandInventory') is not null
  drop Procedure pr_Exports_CIMSDE_ExportOnhandInventory;
Go
/*------------------------------------------------------------------------------
  pr_Exports_CIMSDE_ExportOnhandInventory:  This procedure will get called from job to
   export the available Inv from CIMS database to CIMSDE database.

   pr_Exports_OnhandInventory : Captures the available Inv from CIMS will return the
                                result in xml.

   CIMSDE_pr_PushExportInvFromCIMS: This procedure will take the input as xml and
     will send/insert all data to CIMSDE inventory table.
 ------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CIMSDE_ExportOnhandInventory
  (@Warehouse      TWarehouse    = null,
   @Ownership      TOwnership    = null,
   @SourceSystem   TName         = null,
   @BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = null)
as
  declare @vParentLogId     TRecordId,
          @vxmlInventory    xml,
          @vxmlResult       xml,
          @ReturnCode       TInteger,

          @vMessage         TNVarchar,
          @vSourceReference TDescription,
          @vResultXML       TXML;;
begin /* pr_Exports_CIMSDE_ExportOnhandInventory */
begin try
  SET NOCOUNT ON;

  /* This procedure will return the all available inventory with in CIMS as xml */
  exec pr_Exports_OnhandInventory @Warehouse = @Warehouse, @Ownership = @Ownership, @SourceSystem = @SourceSystem,
                                  @BusinessUnit = @BusinessUnit, @XmlResult = @vxmlResult output;

  /* convert xml data to varchar */
  select @vResultXML = convert(varchar(max), @vxmlResult);

  /* Push the data into CIMSDE database */
  exec CIMSDE_pr_PushExportInvFromCIMS @vResultXML, @UserId, @BusinessUnit;

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
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_CIMSDE_ExportOnhandInventory */

Go
