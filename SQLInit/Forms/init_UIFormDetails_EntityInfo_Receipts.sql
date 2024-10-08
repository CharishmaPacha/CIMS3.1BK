/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/04  SAK     Initial revision(HA-2723)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* RH_EntityInfo_Parent Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'RH_EntityInfo_Parent'; 

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);
                               
insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',    
  '<div class="cims-table-details-header cims-sticky js-entityinfo-detail-container">
    [Detail_RH_EntityInfo_RH_EntityInfo_SummaryInfo]
   </div>
   <hr style="margin:0; padding:0;">
   <div class="cims-entityinfo-table-details">
     <ul class="nav nav-tabs">
       <li class="active"><a data-toggle="tab" href="#divSummary" class="active show">Summary</a></li>
       <li><a data-toggle="tab" href="#divDetails">Receipt Details</a></li>
       <li><a data-toggle="tab" href="#divLPNs">LPNs</a></li>
       <li><a data-toggle="tab" href="#divAuditTrail">Audit Trail</a></li>
     </ul>
     <div class="tab-content">
       <div id="divSummary" class="tab-pane fade in active show js-entityinfo-detail-container">
         [Detail_RH_EntityInfo_RH_EntityInfo_Summary]
       </div>
       <div id="divDetails" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_RH_EntityInfo_RH_EntityInfo_Details]
       </div>
       <div id="divLPNs" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_RH_EntityInfo_RH_EntityInfo_LPNs]
       </div>
       <div id="divAuditTrail" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_RH_EntityInfo_RH_EntityInfo_AuditTrail]
       </div>
     </div>
   </div>', BusinessUnit from vwBusinessUnits 

/*------------------------------------------------------------------------------*/
/* RH_EntityInfo_SummaryForm Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'RH_EntityInfo_SummaryForm'; 

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',     
  '<div class="row">
    <div class="col-md-6">
      <div class="cims-list-page-header">
        <h3 class="navbar-brand" title="Receipt Number">[Field_ReceiptNumber]</h3>
        <p style="color:#888; font-size:11px">Receipt</p>
      </div>  
    </div>
    <div class="col-md-6" style="text-align:right">
      <div class="cims-list-page-header">
        <h3 class="navbar-brand" title="Status">[Field_ReceiptStatusDesc]</h3>
        <p style="color:#888; font-size:11px">Status</p>
      </div>
    </div>
  </div>', BusinessUnit from vwBusinessUnits

Go
