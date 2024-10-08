/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/21  OK      Added Notifications (CIMSV3-1232)
  2020/06/09  MS      Added OrderHeaders, LPNs, Pallets Tabs (HA-858)
  2020/06/08  RT      Intial Revision
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Load_EntityInfo_Parent Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Load_EntityInfo_Parent';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
  '<div class="cims-table-details-header cims-sticky js-entityinfo-detail-container">
    [Detail_Load_EntityInfo_Load_EntityInfo_SummaryInfo]
   </div>
   <hr style="margin:0; padding:0;">
   <div class="cims-entityinfo-table-details">
     <ul class="nav nav-tabs">
       <li><a data-toggle="tab" href="#divOrders">Orders</a></li>
       <li><a data-toggle="tab" href="#divPallets">Pallets</a></li>
       <li><a data-toggle="tab" href="#divLPNs">LPNs</a></li>
       <li><a data-toggle="tab" href="#divBoLs">BoLs</a></li>
       <li><a data-toggle="tab" href="#divBoLOrderDetails">BoL Order Details</a></li>
       <li><a data-toggle="tab" href="#divBoLCarrierDetails">BoL Carrier Details</a></li>
       <li><a data-toggle="tab" href="#divNotifications">Notifications</a></li>
       <li><a data-toggle="tab" href="#divAuditTrail">Audit Trail</a></li>
     </ul>
     <div class="tab-content">
       <div id="divOrders" class="tab-pane fade in active show js-entityinfo-detail-container">
         [Detail_Load_EntityInfo_Load_EntityInfo_Orders]
       </div>
       <div id="divPallets" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_Load_EntityInfo_Load_EntityInfo_Pallets]
       </div>
       <div id="divLPNs" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_Load_EntityInfo_Load_EntityInfo_LPNs]
       </div>
       <div id="divBoLs" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_Load_EntityInfo_Load_EntityInfo_BoLs]
       </div>
       <div id="divBoLOrderDetails" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_Load_EntityInfo_Load_EntityInfo_BoLOrderDetails]
       </div>
       <div id="divBoLCarrierDetails" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_Load_EntityInfo_Load_EntityInfo_BoLCarrierDetails]
       </div>
       <div id="divNotifications" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_Load_EntityInfo_Load_EntityInfo_Notifications]
       </div>
       <div id="divAuditTrail" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_Load_EntityInfo_Load_EntityInfo_AuditTrail]
       </div>
     </div>
   </div>', BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Load_EntityInfo_SummaryForm Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Load_EntityInfo_SummaryForm';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
  '<div class="row">
    <div class="col-md-6">
      <div class="cims-list-page-header">
        <h3 class="navbar-brand" title="LoadNumber">[Field_LoadNumber]</h3>
        <p style="color:#888; font-size:11px">Load</p>
      </div>
    </div>
    <div class="col-md-6" style="text-align:right">
      <div class="cims-list-page-header">
        <h3 class="navbar-brand" title="Status">[Field_LoadStatusDesc]</h3>
        <p style="color:#888; font-size:11px">Status</p>
      </div>
    </div>
  </div>', BusinessUnit from vwBusinessUnits

Go
