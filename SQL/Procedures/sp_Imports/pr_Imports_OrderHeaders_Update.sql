/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderHeaders_Update') is not null
  drop Procedure pr_Imports_OrderHeaders_Update;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderHeaders_Update; Updates the Order Headers in
    #ImportOrderHeaders with RecordAction of 'U'

  #ImportOrderHeaders: TOrderHeadersImportType
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderHeaders_Update
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin /* pr_Imports_OrderHeaders_Update */
  SET NOCOUNT ON;

  update OH1
  set OH1.PickTicket        = OH2.PickTicket,
      OH1.SalesOrder        = coalesce(nullif(OH2.SalesOrder, ''), OH2.PickTicket),
      OH1.OrderType         = OH2.OrderType,
      OH1.ReceiptNumber     = OH2.ReceiptNumber,
      OH1.OrderDate         = OH2.OrderDate,
      OH1.DesiredShipDate   = OH2.DesiredShipDate,
      OH1.CancelDate        = OH2.CancelDate,
      OH1.Priority          = OH2.Priority,
      OH1.SoldToId          = OH2.SoldToId,
      OH1.ShipToId          = OH2.ShipToId,
      OH1.ReturnAddress     = OH2.ReturnAddress,
      OH1.MarkForAddress    = OH2.MarkForAddress,
      OH1.ShipToStore       = OH2.ShipToStore,
      OH1.ShipVia           = OH2.ShipVia,
      OH1.DeliveryRequirement
                            = OH2.DeliveryRequirement,
      OH1.CarrierOptions    = OH2.CarrierOptions,
      OH1.ShipFrom          = OH2.ShipFrom,
      OH1.ShipCompletePercent
                            = coalesce(OH2.ShipCompletePercent, 0),
      OH1.CustPO            = OH2.CustPO,
      OH1.Ownership         = OH2.Ownership,
      --OH1.SourceSystem      = OH2.SourceSystem, Should not change SourceSystem
      OH1.Account           = OH2.Account,
      OH1.AccountName       = OH2.AccountName,
      OH1.HostNumLines      = OH2.HostNumLines,
      OH1.OrderCategory1    = OH2.OrderCategory1,
      OH1.OrderCategory2    = OH2.OrderCategory2,
      OH1.OrderCategory3    = OH2.OrderCategory3,
      OH1.OrderCategory4    = OH2.OrderCategory4,
      OH1.OrderCategory5    = OH2.OrderCategory5,
      OH1.Warehouse         = OH2.Warehouse,
      OH1.TotalTax          = OH2.TotalTax,
      OH1.TotalShippingCost = OH2.TotalShippingCost,
      OH1.TotalDiscount     = OH2.TotalDiscount,
      OH1.TotalSalesAmount  = OH2.TotalSalesAmount,
      OH1.FreightCharges    = OH2.FreightCharges,
      OH1.FreightTerms      = OH2.FreightTerms,
      OH1.BillToAccount     = OH2.BillToAccount,
      OH1.BillToAddress     = OH2.BillToAddress,
      OH1.PreprocessFlag    = case when (OH1.PreprocessFlag <> 'I' /* Ignore */) then 'N' /* No */else OH1.PreprocessFlag end,
      OH1.Comments          = OH2.Comments,
      OH1.WaveFlag          = case
                                when OH2.RecordAction = 'A' then OH1.WaveFlag -- No change
                                when (charindex('X', OH1.WaveFlag) = 0) /* If it already has X then ignore */
                                then coalesce(OH1.WaveFlag, '') + 'X'
                                else OH1.WaveFlag
                              end, /* Append X to indicate order has been modified and the wave has to be re-evaluated */
      OH1.UDF1              = OH2.OH_UDF1,
      OH1.UDF2              = OH2.OH_UDF2,
      OH1.UDF3              = OH2.OH_UDF3,
      OH1.UDF4              = OH2.OH_UDF4,
      OH1.UDF5              = OH2.OH_UDF5,
      OH1.UDF6              = OH2.OH_UDF6,
      OH1.UDF7              = OH2.OH_UDF7,
      OH1.UDF8              = OH2.OH_UDF8,
      OH1.UDF9              = OH2.OH_UDF9,
      OH1.UDF10             = OH2.OH_UDF10,
      OH1.UDF11             = OH2.OH_UDF11,
      OH1.UDF12             = OH2.OH_UDF12,
      OH1.UDF13             = OH2.OH_UDF13,
      OH1.UDF14             = OH2.OH_UDF14,
      OH1.UDF15             = OH2.OH_UDF15,
      OH1.UDF16             = OH2.OH_UDF16,
      OH1.UDF17             = OH2.OH_UDF17,
      OH1.UDF18             = OH2.OH_UDF18,
      OH1.UDF19             = OH2.OH_UDF19,
      OH1.UDF20             = OH2.OH_UDF20,
      OH1.UDF21             = OH2.OH_UDF21,
      OH1.UDF22             = OH2.OH_UDF22,
      OH1.UDF23             = OH2.OH_UDF23,
      OH1.UDF24             = OH2.OH_UDF24,
      OH1.UDF25             = OH2.OH_UDF25,
      OH1.UDF26             = OH2.OH_UDF26,
      OH1.UDF27             = OH2.OH_UDF27,
      OH1.UDF28             = OH2.OH_UDF28,
      OH1.UDF29             = OH2.OH_UDF29,
      OH1.UDF30             = OH2.OH_UDF30,
      OH1.ModifiedDate      = case when (coalesce(OH2.ModifiedDate, '') <> '') then OH2.ModifiedDate else current_timestamp end,
      OH1.ModifiedBy        = case when (coalesce(OH2.ModifiedBy, '') <> '') then OH2.ModifiedBy else System_User end
  output 'PickTicket', Inserted.OrderId, OH2.PickTicket, null, 'AT_OrderHeadersModified' /* Audit Activity */, OH2.RecordAction /* Action */, null /* Comment */,
          Inserted.BusinessUnit, Inserted.ModifiedBy, Inserted.OrderId, OH2.OrderId, null, null, null,
          null /* Audit Id */ into #AuditInfo
  from OrderHeaders OH1 inner join #OrderHeadersImport OH2 on (OH1.OrderId = OH2.OrderId)
  where (OH2.RecordAction in ('U' /* Update */, 'A'));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_OrderHeaders_Update */

Go
