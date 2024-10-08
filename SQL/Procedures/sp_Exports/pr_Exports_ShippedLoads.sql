/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_ShippedLoads') is not null
  drop Procedure pr_Exports_ShippedLoads;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_ShippedLoads:

  This procedure will return the current day shipped loads
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_ShippedLoads
  (@TransType          TTypeCode   = null,
   @LoadNumber         TLoadNumber = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ResultXml          XML   output)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,

          @vRecordType      TTypeCode;

begin
  set NOCOUNT ON;

  select @ReturnCode    = 0,
         @MessageName   = null,
         @vRecordType   = 'SL' /* Shipped Loads */;

  /* Get the Shipped Load Info into XML */
  select @ResultXml = (select distinct @vRecordType as RecordType, LoadNumber, PickTicket, SalesOrder, SoldToId,
                              ShipToId, Pallet as LPN, LoadNumber as Pallet, SKU, SKU1, SKU2, SKU3, SKU4, SKU5,
                              '' as LPNId, '' as LPNDetailId, '' as Lot, UnitsShipped, UDF1,
                              UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10
                      from vwShippedLoads
                      where (LoadNumber   = coalesce(@LoadNumber, LoadNumber)) and
                            (BusinessUnit = @BusinessUnit)
                      FOR XML PATH('LoadInfo'), ROOT('ExportShippedLoads'));

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_ShippedLoads */

Go
