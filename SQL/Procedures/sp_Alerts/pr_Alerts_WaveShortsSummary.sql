/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_WaveShortsSummary') is not null
  drop Procedure pr_Alerts_WaveShortsSummary;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_WaveShortsSummary:
    This proc will email shorts if there are any in the pickbatch.
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_WaveShortsSummary
  (@PickBatchNo   TPickBatchNo,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vXML               TVarchar,
          @vAlertCategory     TCategory;


  declare @ttPickBatchSummary table (Line           TDetailLine,
                                     BatchNo        TPickBatchNo,
                                     HostOrderLine  THostOrderLine,
                                     OrderDetailId  TRecordId,
                                     CustSKU        TCustSKU,
                                     CustPO         TCustPO,
                                     ShipToStore    TShipToStore,
                                     SKUId          TRecordId,
                                     SKU            TSKU,
                                     SKU1           TSKU,
                                     SKU2           TSKU,
                                     SKU3           TSKU,
                                     SKU4           TSKU,
                                     SKU5           TSKU,
                                     UPC            TUPC,
                                     Description    TDescription,
                                     UnitsPerCarton TQuantity,
                                     UnitsPerInnerPack TQuantity,
                                     UnitsOrdered   TQuantity,
                                     UnitsAuthorizedToShip TQuantity,
                                     UnitsAssigned  TQuantity,
                                     UnitsNeeded    TQuantity,
                                     UnitsAvailable TQuantity,
                                     UnitsShort     TQuantity,
                                     UnitsPicked    TQuantity,
                                     UnitsPacked    TQuantity,
                                     UnitsLabeled   TQuantity,
                                     UnitsShipped   TQuantity,
                                     LPNOrdered     TQuantity,
                                     LPNsToShip     TQuantity,
                                     LPNsAssigned   TQuantity,
                                     LPNsNeeded     TQuantity,
                                     LPNsAvailable  TQuantity,
                                     LPNsShort      TQuantity,
                                     LPNsPicked     TQuantity,
                                     LPNsPacked     TQuantity,
                                     LPNsLabeled    TQuantity,
                                     LPNsShipped    TQuantity,
                                     UDF1           TUDF,
                                     UDF2           TUDF,
                                     UDF3           TUDF,
                                     UDF4           TUDF,
                                     UDF5           TUDF)

begin
  /* Initialize */
  select @vAlertCategory = Object_Name(@@ProcId) -- pr_ will be trimmed by pr_Email_SendDBAlert,

  /* Get the Pickbatch Summary into temp table */
  insert into @ttPickBatchSummary
    exec pr_PickBatch_BatchSummary @PickBatchNo

  /* build the xml query */
  select SKU, UPC, UnitsOrdered, UnitsAuthorizedToShip, UnitsAssigned, UnitsNeeded,
         UnitsAvailable, UnitsShort, UnitsPicked, UnitsShipped
  into #WaveShortSummary
  from @ttPickBatchSummary
  where (UnitsShort > 0);

  /* Email the results */
  if (exists (select * from #WaveShortSummary))
    exec pr_Email_SendQueryResults @vAlertCategory, '#WaveShortSummary', null /* order by */, @BusinessUnit;
end /* pr_Alerts_WaveShortsSummary */

Go
