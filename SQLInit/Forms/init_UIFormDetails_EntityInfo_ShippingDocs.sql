/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/16  NB      changes to display caption at top and data below it in all entity info for consistency(CIMSV3-963)
  2020/06/22  NB      Initial revision(CIMSV3-963)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* ShippingDocs_EntityInfo_LPN Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ShippingDocs_EntityInfo_LPN';
/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
   <div class="col-md-12"><b>LPN: [Field_LPN]</b></div>
 </div>
 <hr>
 <div class="row">
   <div class="col-md-5">LPN Status<br><b>[Field_LPNStatusDesc]</b></div>
   <div class="col-md-3">Cases<br><b class="normal">[Field_InnerPacks]</b></div>
   <div class="col-md-4 text-right">Quantity<br><b>[Field_Quantity]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-5">Carton Type<br><b class="normal">[Field_CartonType]</b></div>
   <div class="col-md-3">Carton Weight<br><b class="normal">[Field_ActualWeight]</b></div>
   <div class="col-md-4 text-right">Carton #<br><b class="normal">[Field_PackageSeqNo]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">UCC Barcode<br><b>[Field_UCCBarcode]</b></div>
   <div class="col-md-6 text-right">Tracking No<br><b>[Field_TrackingNo]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">
     <div class="hidden"><b class="normal">Order Status</b><br>*NOMAPPING*</div>
   </div>  
   <div class="col-md-6 text-right">Sales Order<br><b class="normal">[Field_SalesOrder]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Pick Ticket<br><b>[Field_PickTicket]</b></div>
   <div class="col-md-6 text-right">Wave<br><b>[Field_WaveNo]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-5">Cust PO<br><b class="normal">[Field_CustPO]</b></div>
   <div class="col-md-4">
     <div class="hidden">Ship Via<br><b class="normal">*NOMAPPING*</b></div>
   </div>
   <div class="col-md-3 text-right">Total Weight<br><b class="normal">[Field_LPNWeight]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Sold To<br><b>[Field_SoldToName]</b></div>
   <div class="col-md-6 text-right">Ship To<br><b>[Field_ShipTo]</b></div>
 </div>',  BusinessUnit from vwBusinessUnits;

/*------------------------------------------------------------------------------*/
/* ShippingDocs_EntityInfo_Pallet Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ShippingDocs_EntityInfo_Pallet';
/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
   <div class="col-md-12"><b>Pallet: [Field_Pallet]</b></div>
 </div>
 <hr>
 <div class="row m-t-15">
   <div class="col-md-5">Pallet Type<br><b>[Field_PalletTypeDesc]</b></div>
   <div class="col-md-3">Pallet Status<br><b>[Field_PalletStatusDesc]</b></div>
   <div class="col-md-4 text-right">Wave Number<br><b>[Field_WaveNo]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Number of LPNs<br><b>[Field_NumLPNs]</b></div>
   <div class="col-md-6 text-right">Number of Units<br><b>[Field_Quantity]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Total Weight<br><b class="normal">[Field_Weight]</b></div>
   <div class="col-md-6 text-right">Volume<br><b class="normal">[Field_Volume]</b></div>
 </div>',  BusinessUnit from vwBusinessUnits;

/*------------------------------------------------------------------------------*/
/* ShippingDocs_EntityInfo_Order Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ShippingDocs_EntityInfo_Order';
/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
   <div class="col-md-12"><b>Pick Ticket: [Field_PickTicket]</b></div>
 </div>
 <hr>
 <div class="row">
   <div class="col-md-5">Order Status<br><b>[Field_OrderStatusDesc]</b></div>
   <div class="col-md-3">Sales Order<br><b class="normal">[Field_SalesOrder]</b></div>
   <div class="col-md-4 text-right">Wave<br><b>[Field_WaveNo]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-5">Cust PO<br><b class="normal">[Field_CustPO]</b></div>
   <div class="col-md-3 text-right"></div>
   <div class="col-md-4 text-right">Ship Via<br><b class="normal">[Field_ShipViaDesc]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-5"># Cartons<br><b class="normal">[Field_LPNsAssigned]</b></div>
   <div class="col-md-3 text-right"></div>
   <div class="col-md-4 text-right">Total Weight<br><b class="normal">[Field_TotalWeight]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Sold To<br><b>[Field_SoldToId]<br>[Field_CustomerName]</b></div>
   <div class="col-md-6 text-right">Ship To<br><b>[Field_ShipToName]<br>[Field_ShipToCityStateZip]</b></div>
 </div>',  BusinessUnit from vwBusinessUnits;

/*------------------------------------------------------------------------------*/
/* ShippingDocs_EntityInfo_Wave Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ShippingDocs_EntityInfo_Wave';
/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
   <div class="col-md-12"><b>Wave: [Field_WaveNo]</b></div>
 </div>
 <hr>
 <div class="row">
   <div class="col-md-4">Wave Type<br><b>[Field_WaveTypeDesc]</b></div>
   <div class="col-md-3">Wave Status<br><b class="text-nowrap">[Field_WaveStatusDesc]</b></div>
   <div class="col-md-5 text-right">Account Name<br><b>[Field_AccountName]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-4">No of Orders<br><b class="normal">[Field_NumOrders]</b></div>
   <div class="col-md-3">No of SKUs<br><b class="normal">[Field_NumSKUs]</b></div>
   <div class="col-md-2">Total Qty<br><b class="normal">[Field_NumUnits]</b></div>
   <div class="col-md-3 text-right">Total LPNs<br><b class="normal">[Field_NumLPNs]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-4">Cancel Date<br><b class="normal">[Field_CancelDate]</b></div>
   <div class="col-md-3">Ship Date<br><b class="normal">[Field_ShipDate]</b></div>
   <div class="col-md-5 text-right">Ship Via<br><b class="normal">[Field_ShipViaDesc]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Sold To<br><b>[Field_SoldToDesc]</b></div>
   <div class="col-md-6 text-right">Ship To<br><b>[Field_ShipToDescription]</b></div>
 </div>',  BusinessUnit from vwBusinessUnits;
 
/*------------------------------------------------------------------------------*/
/* ShippingDocs_EntityInfo_Load Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'ShippingDocs_EntityInfo_Load';
/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
   <div class="col-md-12"><b>Load: [Field_LoadNumber]</b></div>
 </div>
 <hr>
 <div class="row">
   <div class="col-md-5">Load Type<br><b>[Field_LoadTypeDesc]</b></div>
   <div class="col-md-3">Load Status<br><b>[Field_LoadStatusDesc]</b></div>
   <div class="col-md-4 text-right">Ship Via<br><b>[Field_ShipViaDescription]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">No of Orders<br><b class="normal">[Field_NumOrders]</b></div>
   <div class="col-md-6 text-right">No of LPNs<br><b class="normal">[Field_NumLPNs]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Total Qty<br><b class="normal">[Field_NumUnits]</b></div>
   <div class="col-md-6 text-right">Weight<br><b class="normal">[Field_Weight]</b></div>
   <div class="col-md-6 text-right">Volume<br><b class="normal">[Field_Volume]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-5">Desired Ship Date<br><b class="normal">[Field_DesiredShipDate]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Account Name<br><b>[Field_AccountName]</b></div>
   <div class="col-md-6 text-right">Ship To<br><b>[Field_ShipToDesc]</b></div>
 </div>',  BusinessUnit from vwBusinessUnits; 