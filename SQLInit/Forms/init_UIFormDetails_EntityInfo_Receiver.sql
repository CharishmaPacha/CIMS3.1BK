/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

   2020/05/09  NB      HTML and CSS changes(HA-311)
   2020/04/19  MS      Initial revision(HA-202)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* RCV_EntityInfo_Parent Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'RCV_EntityInfo_Parent'; 

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);
                               
insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',    
  '<div class="cims-table-details-header cims-sticky js-entityinfo-detail-container">
    [Detail_RCV_EntityInfo_RCV_EntityInfo_SummaryInfo]
   </div>
   <hr style="margin:0; padding:0;">
   <div class="cims-entityinfo-table-details">
     <ul class="nav nav-tabs">
       <li class="active"><a data-toggle="tab" href="#divSummary" class="active show">Summary</a></li>
       <li><a data-toggle="tab" href="#divLPNs">LPNs</a></li>
       <li><a data-toggle="tab" href="#divAuditTrail">Audit Trail</a></li>
     </ul>
     <div class="tab-content">
       <div id="divSummary" class="tab-pane fade in active show js-entityinfo-detail-container">
         [Detail_RCV_EntityInfo_RCV_EntityInfo_Summary]
       </div>
       <div id="divLPNs" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_RCV_EntityInfo_RCV_EntityInfo_LPNs]
       </div>
       <div id="divAuditTrail" class="tab-pane fade in js-entityinfo-detail-container">
         [Detail_RCV_EntityInfo_RCV_EntityInfo_AuditTrail]
       </div>
     </div>
   </div>', BusinessUnit from vwBusinessUnits 

/*------------------------------------------------------------------------------*/
/* RCV_EntityInfo_SummaryForm Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'RCV_EntityInfo_SummaryForm'; 

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',     
  '<div class="row">
    <div class="col-md-6">
      <div class="cims-list-page-header">
        <h3 class="navbar-brand" title="Receiver">[Field_ReceiverNumber]</h3>
        <p style="color:#888; font-size:11px">Receiver</p>
      </div>  
    </div>
    <div class="col-md-6" style="text-align:right">
      <div class="cims-list-page-header">
        <h3 class="navbar-brand" title="Status">[Field_ReceiverStatusDesc]</h3>
        <p style="color:#888; font-size:11px">Status</p>
      </div>
    </div>
  </div>', BusinessUnit from vwBusinessUnits

Go
