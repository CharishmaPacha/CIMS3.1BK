/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Setup ShipLabels Tab (HA-2406)
  2020/06/10  MS      Setup Addresses Tab (HA-861)
  2020/05/17  MS      Setup EntityInfo for OrderHeaders (HA-568)
  2020/03/22  NB      Minor changes to Parent HTML to view details in full width (HA-202)
  2018/03/20  NB      Placeholders names corrections for Listing within EntityInfo in Parent form(CIMSV3-151)
  2018/01/29  NB      Initial revision(CIMSV3-151)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* OH_EntityInfo_HeaderForm Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'OH_EntityInfo_Parent';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="cims-table-details-header cims-sticky js-entityinfo-detail-container">
  [Detail_OH_EntityInfo_OH_EntityInfo_SummaryInfo]
 </div>
 <hr style="margin:0; padding:0;">

 <div class="hidden cims-table-details-header cims-sticky js-entityinfo-detail-container">
  [Detail_OH_EntityInfo_OH_EntityInfo_OrderHeader]
 </div>
 <hr style="margin:0; padding:0;">

 <div class="cims-entityinfo-table-details">
  <ul class="nav nav-tabs">
    <li class="active"><a data-toggle="tab" href="#divOrderDetails" class="active show">Order Details</a></li>
    <li><a data-toggle="tab" href="#divLPNs">LPNs</a></li>
    <li><a data-toggle="tab" href="#divLPNDetails">LPN Details</a></li>
    <li><a data-toggle="tab" href="#divPickTasks">Pick Tasks</a></li>
    <li><a data-toggle="tab" href="#divPickTaskDetails">Picks</a></li>
    <li><a data-toggle="tab" href="#divShipLabels">Ship Labels</a></li>
    <li><a data-toggle="tab" href="#divAddresses">Addresses</a></li>
    <li><a data-toggle="tab" href="#divNotifications">Notifications</a></li>
    <li class="hidden"><a data-toggle="tab" href="#divNotes">Notes</a></li>
    <li><a data-toggle="tab" href="#divAuditTrail">Audit Trail</a></li>
  </ul>
  <div class="tab-content">
    <div id="divOrderDetails" class="tab-pane fade in active show js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_OrderDetails]
    </div>
    <div id="divLPNs" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_LPNs]
    </div>
    <div id="divLPNDetails" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_LPNDetails]
    </div>
    <div id="divPickTasks" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_PickTasks]
    </div>
    <div id="divPickTaskDetails" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_PickTaskDetails]
    </div>
    <div id="divShipLabels" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_ShipLabels]
    </div>
    <div id="divAddresses" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_Addresses]
    </div>
    <div id="divNotifications" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_Notifications]
    </div>
    <div id="divNotes" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_Notes]
    </div>
    <div id="divAuditTrail" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_OH_EntityInfo_OH_EntityInfo_AuditTrail]
    </div>
  </div>
 </div>', BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* OH_EntityInfo_HeaderForm Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'OH_EntityInfo_HeaderForm_Generic';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',    '<h1>Generic</h1><div class="row">
    <div class="col-sm-4">
        <strong>Sold To:</strong>
        <span>[Field_CustomerName]</span>
    </div>
    <div class="col-sm-4">
        <strong>Ship To:</strong>
        <span>[Field_ShipToName]</span>
    </div>
</div>
<div class="row">
    <div class="col-sm-2">
        <strong>Num Lines:</strong>
        <span>[Field_NumLines]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num SKUs:</strong>
        <span>[Field_NumSKUs]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num LPNs:</strong>
        <span>[Field_NumLPNs]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num Units:</strong>
        <span>[Field_NumUnits]</span>
    </div>
</div>
<div class="row">
    <div class="col-sm-2">
        <strong>Units Assigned:</strong>
        <span>[Field_UnitsAssigned]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Picked:</strong>
        <span>[Field_UnitsPicked]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Packed:</strong>
        <span>[Field_UnitsPacked]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Staged:</strong>
        <span>[Field_UnitsStaged]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Loaded:</strong>
        <span>[Field_UnitsLoaded]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Shipped:</strong>
        <span>[Field_UnitsShipped]</span>
    </div>
</div>', BusinessUnit from vwBusinessUnits

select @FormName = 'OH_EntityInfo_HeaderForm_S';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',    '<h1>Packed and above</h1><div class="row">
    <div class="col-sm-4">
        <strong>Sold To:</strong>
        <span>[Field_CustomerName]</span>
    </div>
    <div class="col-sm-4">
        <strong>Ship To:</strong>
        <span>[Field_ShipToName]</span>
    </div>
</div>
<div class="row">
    <div class="col-sm-2">
        <strong>Num Lines:</strong>
        <span>[Field_NumLines]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num SKUs:</strong>
        <span>[Field_NumSKUs]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num LPNs:</strong>
        <span>[Field_NumLPNs]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num Units:</strong>
        <span>[Field_NumUnits]</span>
    </div>
</div>
<div class="row">
    <div class="col-sm-2">
        <strong>Units Assigned:</strong>
        <span>[Field_UnitsAssigned]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Picked:</strong>
        <span>[Field_UnitsPicked]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Packed:</strong>
        <span>[Field_UnitsPacked]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Staged:</strong>
        <span>[Field_UnitsStaged]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Loaded:</strong>
        <span>[Field_UnitsLoaded]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Shipped:</strong>
        <span>[Field_UnitsShipped]</span>
    </div>
</div>', BusinessUnit from vwBusinessUnits

select @FormName = 'OH_EntityInfo_HeaderForm_P';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',    '<h1>Inprogress</h1><div class="row">
    <div class="col-sm-4">
        <strong>Sold To:</strong>
        <span>[Field_CustomerName]</span>
    </div>
    <div class="col-sm-4">
        <strong>Ship To:</strong>
        <span>[Field_ShipToName]</span>
    </div>
</div>
<div class="row">
    <div class="col-sm-2">
        <strong>Num Lines:</strong>
        <span>[Field_NumLines]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num SKUs:</strong>
        <span>[Field_NumSKUs]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num LPNs:</strong>
        <span>[Field_NumLPNs]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num Units:</strong>
        <span>[Field_NumUnits]</span>
    </div>
</div>
<div class="row">
    <div class="col-sm-2">
        <strong>Units Assigned:</strong>
        <span>[Field_UnitsAssigned]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Picked:</strong>
        <span>[Field_UnitsPicked]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Packed:</strong>
        <span>[Field_UnitsPacked]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Staged:</strong>
        <span>[Field_UnitsStaged]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Loaded:</strong>
        <span>[Field_UnitsLoaded]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Shipped:</strong>
        <span>[Field_UnitsShipped]</span>
    </div>
</div>', BusinessUnit from vwBusinessUnits

select @FormName = 'OH_EntityInfo_HeaderForm_W';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',    '<h1>Waved and below</h1><div class="row">
    <div class="col-sm-4">
        <strong>Sold To:</strong>
        <span>[Field_CustomerName]</span>
    </div>
    <div class="col-sm-4">
        <strong>Ship To:</strong>
        <span>[Field_ShipToName]</span>
    </div>
</div>
<div class="row">
    <div class="col-sm-2">
        <strong>Num Lines:</strong>
        <span>[Field_NumLines]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num SKUs:</strong>
        <span>[Field_NumSKUs]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num LPNs:</strong>
        <span>[Field_NumLPNs]</span>
    </div>
    <div class="col-sm-2">
        <strong>Num Units:</strong>
        <span>[Field_NumUnits]</span>
    </div>
</div>
<div class="row">
    <div class="col-sm-2">
        <strong>Units Assigned:</strong>
        <span>[Field_UnitsAssigned]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Picked:</strong>
        <span>[Field_UnitsPicked]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Packed:</strong>
        <span>[Field_UnitsPacked]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Staged:</strong>
        <span>[Field_UnitsStaged]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Loaded:</strong>
        <span>[Field_UnitsLoaded]</span>
    </div>
    <div class="col-sm-2">
        <strong>Units Shipped:</strong>
        <span>[Field_UnitsShipped]</span>
    </div>
</div>', BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* OH_EntityInfo_SummaryForm Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'OH_EntityInfo_SummaryForm';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
    <div class="col-md-2">
        <div class="cims-list-page-header">
            <p class="cims-caption-small">PickTicket</p>
            <h3 class="navbar-brand cims-display-value-large" title="Pick Ticket">[Field_PickTicket]</h3>
        </div>
    </div>
    <div class="col-md-8 cims-list-page-header">
        <div class="row">
            <div class="col-md-3">
                <p class="cims-caption-small">Account</p>
                <h3 class="navbar-brand cims-display-value-medium" title="Account">[Field_AccountName]</h3>
            </div>
            <div class="col-md-3">
            <p class="cims-caption-small">Order Class</p>
                <h3 class="navbar-brand cims-display-value-medium" title="Order Class">[Field_OrderCategory1]</h3>
                
            </div>
            <div class="col-md-6 text-right">
                <p class="cims-caption-small">Ship To</p>
                <h3 class="navbar-brand cims-display-value-medium" title="Ship To">[Field_ShipToName]</h3>
            </div>
        </div>
    </div>
    <div class="col-md-2 text-right" >
        <div class="cims-list-page-header">
            <p class="cims-caption-small">Status</p>
            <h3 class="navbar-brand cims-display-value-medium" title="Status">[Field_OrderStatusDesc]</h3>
        </div>
    </div>
</div>', BusinessUnit from vwBusinessUnits

Go
