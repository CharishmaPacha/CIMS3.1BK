/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/09  RV      Added Packing_EntityInfo_BulkOrderPacking (FBV3-421)
  2021/08/10  OK      Corrected the Packed LPNs mapping (BK-428, CIMSV3-1596)
  2021/04/30  NB      Initial revision(CIMSV3-156)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;


/*------------------------------------------------------------------------------*/
/* Packing_EntityInfo_Pallet Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Packing_EntityInfo_Pallet';
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
/* Packing_EntityInfo_Order Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Packing_EntityInfo_StandardOrderPacking';
/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
  <div class="col-md-3">Pick Ticket<br/> <b class="cims-display-value-large cims-font-bold cims-text-special-blue"><a href="#" class="js-detaillink" data-referencefieldname="OrderId" data-referencefieldvalue="[Field_OrderId]" data-referencefieldkeyvalue="[Field_PickTicket]" data-referencecontext="[URL_Home_EntityInfo]" data-referencecategory="OH_EntityInfo" data-uicontrol="DetailLink" data-destinationcontextname="" data-destinationlayoutname="" data-destinationselectionname="" data-destinationfilter="">[Field_PickTicket]</a></b></div>
  <div class="col-md-4">Ship To<br/> <b class="cims-display-value-large cims-font-bold cims-text-special-blue">[Field_ShipToName]</b></div>
  <div class="col-md-5 text-right">Ship To City<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue">[Field_ShipToCityStateZip]</b></div>
 </div>
 <hr>
 <div>
   <div class="row">
     <div class="col-md-12">
       <div id="accordion" role="tablist" aria-multiselectable="true">
         <div role="tab" id="Packing_EntityInfo_Order_More_Details">
           <div class="row">
             <div class="col-md-7">
               ShipVia<br><b class="cims-display-value-large cims-font-bold cims-text-special-maroon">[Field_ShipViaDesc]</b>
             </div>
             <div class="col-md-1 text-center"># Scanned<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue js-current-package-units-scanned">0</b></div>
             <div class="col-md-1 text-center"># Remaining<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue js-current-remainingunitstopack">[Field_UnitsToPack]</b></div>
             <div class="col-md-1 text-center">Total Units<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue">[Field_NumUnits]</b></div>
             <div class="col-md-1 text-center hidden">Package #<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue js-current-package-number" data-fieldvalue="[Field_LPNsPacked]">-</b></div>
             <div class="col-md-1 text-center">Ctns Packed<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue"><a href="#" class="js-listlink" data-sourcefieldname="LPNsPacked" data-referencefieldname="OrderId" data-referencefieldvalue="[Field_OrderId]" data-referencecontext="[URL_Home_List]" data-referencecategory="" data-uicontrol="ListLink" data-destinationcontextname="List.LPNs" data-destinationlayoutname="Standard" data-destinationselectionname="" data-destinationfilter="LPNType = ''S''|Shipping Cartons">[Field_LPNsPacked]</a></b></div>
             <div class="col-md-1 text-center">
               <a role="button" data-toggle="collapse" data-parent="#accordion" href="#collapseOne" aria-expanded="true" aria-controls="collapseOne" title="More Details">
                 <b class="cims-display-value-large"><i class="ti-arrow-circle-down down"></i></b>
               </a>
             </div>            
           </div>
         </div>
         <div id="collapseOne" class="panel-collapse collapse in" role="tabpanel" aria-labelledby="Packing_EntityInfo_Order_More_Details">
           <div class="panel-body">
             <div class="row m-t-15">
               <div class="col-md-2">Order Status<br><b class="cims-display-value-small cims-font-normal cims-text-special-blue">[Field_OrderStatusDesc]</b></div>
               <div class="col-md-2">Sales Order<br><b class="cims-display-value-small cims-font-normal cims-text-special-blue">[Field_SalesOrder]</b></div>
               <div class="col-md-2">Wave<br><b class="cims-display-value-small cims-font-normal cims-text-special-blue">[Field_WaveNo]</b></div>
               <div class="col-md-2">Cust PO<br><b class="cims-display-value-small cims-font-normal cims-text-special-blue">[Field_CustPO]</b></div>                                                
               <div class="col-md-2">Picked<br><b class="cims-display-value-large cims-font-bold cims-text-special-maroon"> [Field_LPNsPicked]</b> Carton(s), <b class="cims-display-value-large cims-font-bold cims-text-special-maroon"> [Field_UnitsPicked]</b> Unit(s)</div>
               <div class="col-md-2">Packed<br><b class="cims-display-value-large cims-font-bold cims-text-special-maroon"> [Field_LPNsPacked]</b> LPN(s) and <b class="cims-display-value-large cims-font-bold cims-text-special-maroon"> [Field_UnitsPacked]</b> Unit(s)</div>
             </div>
           </div>
         </div>         
       </div>
     </div>
   </div>
 </div>',  BusinessUnit from vwBusinessUnits;

 /*------------------------------------------------------------------------------*/
/* Packing_EntityInfo_BulkOrderPacking Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Packing_EntityInfo_BulkOrderPacking';
/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
   <div class="col-md-3">Pick Ticket<br/> <b class="cims-display-value-large cims-font-bold cims-text-special-blue"><a href="#" class="js-detaillink" data-referencefieldname="OrderId" data-referencefieldvalue="[Field_OrderId]" data-referencefieldkeyvalue="[Field_PickTicket]" data-referencecontext="[URL_Home_EntityInfo]" data-referencecategory="OH_EntityInfo" data-uicontrol="DetailLink" data-destinationcontextname="" data-destinationlayoutname="" data-destinationselectionname="" data-destinationfilter="">[Field_PickTicket]</a></b></div>
   <div class="col-md-4">Ship To<br/> <b class="cims-display-value-large cims-font-bold cims-text-special-blue">[Field_ShipToName]</b></div>
   <div class="col-md-5 text-right">Ship To Address<br/><b class="cims-display-value-small cims-font-bold cims-text-special-blue">[Field_ShipToAddressLine1]</b><br/><b class="cims-display-value-small cims-font-bold cims-text-special-blue">[Field_ShipToCityStateZip]</b></div>
 </div>
 <hr>
 <div>
   <div class="row">
     <div class="col-md-12">
       <div id="accordion" role="tablist" aria-multiselectable="true">
         <div role="tab" id="Packing_EntityInfo_Order_More_Details">
           <div class="row">
             <div class="col-md-7">
               ShipVia<br><b class="cims-display-value-large cims-font-bold cims-text-special-maroon">[Field_ShipViaDesc]</b>
             </div>
             <div class="col-md-1 text-center"># Scanned<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue js-current-package-units-scanned">0</b></div>
             <div class="col-md-1 text-center"># Remaining<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue js-current-remainingunitstopack">[Field_UnitsToPack]</b></div>
             <div class="col-md-1 text-center">Total Units<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue">[Field_NumUnits]</b></div>
             <div class="col-md-1 text-center hidden">Package #<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue js-current-package-number" data-fieldvalue="[Field_LPNsPacked]">-</b></div>
             <div class="col-md-1 text-center">Ctns Packed<br/><b class="cims-display-value-large cims-font-bold cims-text-special-blue"><a href="#" class="js-listlink" data-sourcefieldname="LPNsPacked" data-referencefieldname="OrderId" data-referencefieldvalue="[Field_OrderId]" data-referencecontext="[URL_Home_List]" data-referencecategory="" data-uicontrol="ListLink" data-destinationcontextname="List.LPNs" data-destinationlayoutname="Standard" data-destinationselectionname="" data-destinationfilter="LPNType = ''S''|Shipping Cartons">[Field_LPNsPacked]</a></b></div>
             <div class="col-md-1 text-center">
               <a role="button" data-toggle="collapse" data-parent="#accordion" href="#collapseOne" aria-expanded="true" aria-controls="collapseOne" title="More Details">
                 <b class="cims-display-value-large"><i class="ti-arrow-circle-down down"></i></b>
               </a>
             </div>
           </div>
         </div>
         <div id="collapseOne" class="panel-collapse collapse in" role="tabpanel" aria-labelledby="Packing_EntityInfo_Order_More_Details">
           <div class="panel-body">
             <div class="row m-t-15">
               <div class="col-md-2">Order Status<br><b class="cims-display-value-small cims-font-normal cims-text-special-blue">[Field_OrderStatusDesc]</b></div>
               <div class="col-md-2">Sales Order<br><b class="cims-display-value-small cims-font-normal cims-text-special-blue">[Field_SalesOrder]</b></div>
               <div class="col-md-2">Wave<br><b class="cims-display-value-small cims-font-normal cims-text-special-blue">[Field_WaveNo]</b></div>
               <div class="col-md-2">Cust PO<br><b class="cims-display-value-small cims-font-normal cims-text-special-blue">[Field_CustPO]</b></div>
               <div class="col-md-2">Picked<br><b class="cims-display-value-large cims-font-bold cims-text-special-maroon"> [Field_LPNsPicked]</b> Carton(s), <b class="cims-display-value-large cims-font-bold cims-text-special-maroon"> [Field_UnitsPicked]</b> Unit(s)</div>
               <div class="col-md-2">Packed<br><b class="cims-display-value-large cims-font-bold cims-text-special-maroon"> [Field_LPNsPacked]</b> LPN(s) and <b class="cims-display-value-large cims-font-bold cims-text-special-maroon"> [Field_UnitsPacked]</b> Unit(s)</div>
             </div>
           </div>
         </div>
       </div>
     </div>
   </div>
 </div>',  BusinessUnit from vwBusinessUnits;
/*------------------------------------------------------------------------------*/
/* Packing_EntityInfo_Wave Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Packing_EntityInfo_Wave';
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
   <div class="col-md-5">Wave Type<br><b>[Field_WaveTypeDesc]</b></div>
   <div class="col-md-3">Wave Status<br><b>[Field_WaveStatusDesc]</b></div>
   <div class="col-md-4 text-right">Account Name<br><b>[Field_AccountName]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">No of Orders<br><b class="normal">[Field_NumOrders]</b></div>
   <div class="col-md-6 text-right">No of SKUs<br><b class="normal">[Field_NumSKUs]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Total Qty<br><b class="normal">[Field_NumUnits]</b></div>
   <div class="col-md-6 text-right">Total LPNs<br><b class="normal">[Field_NumLPNs]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-5">Cancel Date<br><b class="normal">[Field_CancelDate]</b></div>
   <div class="col-md-3">Ship Date<br><b class="normal">[Field_ShipDate]</b></div>
   <div class="col-md-4 text-right">Ship Via<br><b class="normal">[Field_ShipViaDesc]</b></div>
 </div>
 <div class="row m-t-15">
   <div class="col-md-6">Sold To<br><b>[Field_SoldToDesc]</b></div>
   <div class="col-md-6 text-right">Ship To<br><b>[Field_ShipToDescription]</b></div>
 </div>',  BusinessUnit from vwBusinessUnits;

Go
