/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/12  SK      pr_Exports_PrepareData: Include data for new TransType as well (HA-1896)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_PrepareData') is not null
  drop Procedure pr_Exports_PrepareData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_PrepareData : Exports table has key fields inserted at the time
    of transactions, but hosts require additional info and so this additional info
    is updated here. This facilitates easier retrieval or else lot at the cost of
    data duplication. Earlier, we had to join several tables which was a performance
    hinderance. Also, the underlying data could change over period of time, so having
    a snapshot of the info at the time of export is also helpful.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_PrepareData
  (@BatchNo    TBatch,
   @TransType  TTypeCode)
as
begin
  SET NOCOUNT ON;

  /* Update the ShipTo info and SoldTo info in Exports table */
  if (@TransType in ('Ship', 'EDI753'))
    update E
    set ShipToName         = SHTA.Name, /* ShipToAddress */
        ShipToAddressLine1 = SHTA.AddressLine1,
        ShipToAddressLine2 = SHTA.AddressLine2,
        ShipToCity         = SHTA.City,
        ShipToState        = SHTA.State,
        ShipToCountry      = SHTA.Country,
        ShipToZip          = SHTA.Zip,
        ShipToPhoneNo      = SHTA.PhoneNo,
        ShipToEmail        = SHTA.Email,
        ShipToReference1   = SHTA.Reference1,
        ShipToReference2   = SHTA.Reference2,
        /* SoldToAddress */
        SoldToName         = SOTA.Name
    from Exports E
      left outer join Contacts         SOTA  on (SOTA.ContactRefId   = E.SoldToId        ) and /* Sold To Address */
                                                (SOTA.ContactType    = 'C' /* Sold To */ )
      left outer join Contacts         SHTA  on (SHTA.ContactRefId   = E.ShipToId        ) and /* Ship To Address */
                                                (SHTA.ContactType    = 'S' /* Ship To */ )
    where (ExportBatch = @BatchNo) and (TransType in ('Ship', 'EDI753'));

  /* Get the required fields from view Shipvias to populate in Exports */
  if (@TransType in ('Ship', 'EDI753'))
    update E
    set Carrier     = SV.Carrier,
        ShipViaDesc = SV.Description,
        SCAC        = case when SV.Carrier = 'LTL' then coalesce(SV.SCAC, SV.ShipVia) else coalesce(SV.SCAC, SV.Carrier) end,
        HostShipVia = coalesce(dbo.fn_GetMappedValue('CIMS' /* Source */, E.ShipVia, E.SourceSystem /* Target */, 'ShipVia' /* Entity Type */, null /* Operation */, E.BusinessUnit), E.ShipVia)
    from Exports E
      join vwShipVias SV on (SV.ShipVia = E.ShipVia) and (SV.BusinessUnit = E.BusinessUnit)
    where (ExportBatch = @BatchNo) and (TransType in ('Ship', 'EDI753'));

end /* pr_Exports_PrepareData  */

Go
