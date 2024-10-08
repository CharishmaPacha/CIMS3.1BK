/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Setup ShipLabels Tab (HA-2406)
  2021/03/23  TK      Added Wave Summary tab (HA-2381)
  2020/05/18  MS      Initial revision(HA-569)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;

/*------------------------------------------------------------------------------*/
/* Wave_EntityInfo_HeaderForm Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Wave_EntityInfo_Parent';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="cims-table-details-header cims-sticky js-entityinfo-detail-container">
  [Detail_Wave_EntityInfo_Wave_EntityInfo_SummaryInfo]
 </div>
 <hr style="margin:0; padding:0;">

 <div class="cims-entityinfo-table-details">
  <ul class="nav nav-tabs">
    <li class="active"><a data-toggle="tab" href="#divWaveSummary" class="active show">Summary</a></li>
    <li><a data-toggle="tab" href="#divOrders">Orders</a></li>
    <li><a data-toggle="tab" href="#divOrderDetails">Order Details</a></li>
    <li class="hidden"><a data-toggle="tab" href="#divPallets">Pallets</a></li>
    <li><a data-toggle="tab" href="#divLPNs">LPNs</a></li>
    <li><a data-toggle="tab" href="#divPickTasks">Pick Tasks</a></li>
    <li><a data-toggle="tab" href="#divPickTaskDetails">Picks</a></li>
    <li><a data-toggle="tab" href="#divShipLabels">Ship Labels</a></li>
    <li><a data-toggle="tab" href="#divNotifications">Notifications</a></li>
    <li><a data-toggle="tab" href="#divAuditTrail">Audit Trail</a></li>
  </ul>
  <div class="tab-content">
    <div id="divWaveSummary" class="tab-pane fade in active show js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_WaveSummary]
    </div>
    <div id="divOrders" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_Orders]
    </div>
    <div id="divOrderDetails" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_OrderDetails]
    </div>
    <div id="divPallets" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_Pallets]
    </div>
    <div id="divLPNs" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_LPNs]
    </div>
    <div id="divPickTasks" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_PickTasks]
    </div>
    <div id="divPickTaskDetails" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_PickTaskDetails]
    </div>
    <div id="divShipLabels" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_ShipLabels]
    </div>
    <div id="divNotifications" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_Notifications]
    </div>
    <div id="divAuditTrail" class="tab-pane fade in js-entityinfo-detail-container">
       [Detail_Wave_EntityInfo_Wave_EntityInfo_AuditTrail]
    </div>
  </div>
 </div>', BusinessUnit from vwBusinessUnits


/*------------------------------------------------------------------------------*/
/* Wave_EntityInfo_SummaryForm Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Wave_EntityInfo_SummaryForm';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="row">
  <div class="col-md-6">
   <div class="cims-list-page-header">
    <h3 class="navbar-brand" title="Wave No">[Field_WaveNo]</h3>
    <p style="color:#888; font-size:11px">[Field_WaveTypeDesc] Wave</p>
   </div>
  </div>
  <div class="col-md-6" style="text-align:right">
   <div class="cims-list-page-header">
    <h3 class="navbar-brand" title="Status">[Field_WaveStatusDesc]</h3>
    <p style="color:#888; font-size:11px">Status</p>
   </div>
  </div>
 </div>', BusinessUnit from vwBusinessUnits

Go
