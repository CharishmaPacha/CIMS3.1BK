/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  RIA     Added/changed fields in datatable and method name (OB2-1773)
  2021/04/15  RIA     Changes to bind SKU value (OB2-1759)
  2021/03/30  RIA     Changes to captions (OB2-1773)
  2021/02/12  RIA     Clean up and corrections (OB2-1357)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/02/24  RIA     Initial Revision(CIMSV3-732)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Returns_StartReturns';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Start Returns', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Start Returns</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFReturns"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container" data-rfshowpreprocess="Returns_Confirm_OnShow" data-rfsubmitpreprocess="Returns_PopulateEntityInput">
  <input type="hidden" data-rfname="ReturnData" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="SKU,LPN,ReturnData,ValidatedEntityType,ValidatedEntityId,ValidatedEntityKey" >
  <div class="amf-form-layout-container">
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-12 col-sm-12 col-xs-12">
            <div class="form-group">
              <input type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
              data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value="[FIELDVALUE_ValidatedSKU]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT"
              data-rfvalidationhandler="Returns_Validate_SKUOrUPC"
              data-rfsubmitform="false"
              data-rftabindex="1" data-rfinputtype="SCANNER">
              <label for="SKU">[FIELDCAPTION_SKU]</label>
            </div>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-12">
            <div class="amf-form-number-input-container">
              <label class="col-form-label">Quantity</label>
              <div class="clearfix"></div>
              <span class="amf-form-number-input-decrement">-</span>
              <input class="amf-form-number-input amf-form-number-input-width" size="5" type="text"
              inputmode="numeric" data-rfname="Quantity" data-displaycaption="[FIELDCAPTION_Quantity]" value="1"
              data-rfvalidationset="GREATEROREQUAL" data-rfvalidation-greaterorequal="1" data-rfvalidateon="SUBMIT"
              id="Quantity">
              <span class="amf-form-number-input-increment">+</span>
            </div>
          </div>
          <div class="col-md-12 col-sm-12 col-xs-12">
            <div class="form-group">
              <input type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPNPicklane_PH]"
              data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value=""
              data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Returns_Validate_Entity"
              data-rfinputtype="SCANNER">
              <label for="LPN">[FIELDCAPTION_AMFLPNOrPicklane]</label>
            </div>
          </div>
          <div class="clearfix"></div>
          <div class="col-md-12 col-sm-12 col-xs-12" data-rfvisibility="COMPAREWITH"
          data-rfvisiblevalue="[FIELDVALUE_InventoryClass]" data-rfvisiblecomparewith="InvClass1">
            <div class="form-group">
              <select class="form-control" data-rfname="InventoryClass1">[DATAOPTIONS_InventoryClass1]</select>
              <label class="col-form-label">[FIELDCAPTION_InventoryClass1]</label>
            </div>
          </div>
          <div class="col-md-12 col-sm-12 col-xs-12">
            <div class="form-group">
              <select class="form-control" data-rfdefaultindex="1"
              data-rfname="Disposition">[DATAOPTIONS_Dispositions]</select>
              <label class="col-form-label">[FIELDCAPTION_Disposition]</label>
            </div>
          </div>
          <div class="col-md-12 col-sm-12 col-xs-12">
            <div class="form-group">
              <select class="form-control" data-rfname="ReasonCode">[DATAOPTIONS_ReasonCodes]</select>
              <label class="col-form-label">[FIELDCAPTION_ReasonCode]</label>
            </div>
          </div>
          <div class="clearfix"></div>
        </div>
        <div class="row">
          <div class="col-md-4 col-sm-4 col-xs-4">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-button-top-margin js-returns-additem"
              data-rfclickhandler="Returns_AddItem">Add Item</button>
            </div>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-button-top-margin"
              data-rfclickhandler="Returns_Confirm">Complete</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-display-panel">
      <div class="amf-form-panel-shadow">
        <h3 class="amf-datacard-title">Returns Details</h3>
        <div class="clearfix"></div>
        <div class="table-responsive">
          <table data-rfrecordname="ReturnTable" class="table scroll table-striped table-bordered js-datatable-returns-returndetails">
            <thead>
              <tr>
                <th data-rffieldname="EntityKey">[FIELDCAPTION_LPN]</th>
                <th data-rffieldname="SKU">[FIELDCAPTION_SKU]</th>
                <th data-rffieldname="Quantity">[FIELDCAPTION_Quantity]</th>
                <th data-rffieldname="Reason">[FIELDCAPTION_Reason]</th>
                <th data-rffieldname="Disposition">[FIELDCAPTION_Disposition]</th>
                <th data-rffieldname="EntityId" hidden>[FIELDCAPTION_EntityId]</th>
                <th data-rffieldname="EntityType" hidden>[FIELDCAPTION_EntityType]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_ReturnDetails]
            </tbody>
          </table>
        </div>
        <div class="amf-data-footer">
          <p>Total return Quantity: <span class="amf-display-value"
          data-rfjsname="ReturnQuantity">0</span></p>
        </div>
        <div class="clearfix"></div>
      </div>
      <div class="amf-form-panel-shadow">
        <h3 class="amf-datacard-title">Order Details</h3>
        <div class="clearfix"></div>
        <div class="table-responsive">
          <table class="table scroll table-striped table-bordered js-datatable-content-details">
            <thead>
              <tr>
                <th>[FIELDCAPTION_SKU]</th>
                <th>[FIELDCAPTION_SKUDescription]</th>
                <th hidden>[FIELDCAPTION_InnerPacks]</th>
                <th>[FIELDCAPTION_AMFUnitsShipped]</th>
                <th>[FIELDCAPTION_AMFUnitsReturned]</th>
                <th>[FIELDCAPTION_AMFUnitsRemaining]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_RMADETAILS]
            </tbody>
          </table>
        </div>
        <div class="amf-data-footer">
          <p>Total Quantity: [FIELDVALUE_QtyToBeReturned]</p>
        </div>
        <div class="clearfix"></div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
