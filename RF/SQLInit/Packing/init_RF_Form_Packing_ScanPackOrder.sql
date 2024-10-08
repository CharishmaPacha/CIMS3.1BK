/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  RIA     Added filter and Notes (OB2-1882)
  2020/10/12  RIA     Added SKU and changed data-rffieldname for DisplaySKU/SKU (CIMSV3-622)
  2020/10/06  RIA     Changed caption and included SKU1, SKU5 (CIMSV3-622)
  2020/09/30  RIA     Clean up (CIMSV3-622)
  2020/09/29  RIA     Changes to field value name and div partitions (CIMSV3-622)
  2020/09/17  RIA     Form Clean up and changes (CIMSV3-622)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/09/06  RIA     Initial Revision(CIMSV3-622)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Packing_ScanPackOrder';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Scan Pack Order', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Order Scan Packing</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPacking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-operation-info-open"><i class="amfi-info"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-operation-info">
    <a  class="amf-form-operation-info-close">&times;</a>
    <div class="row">
      <div class="form-group">
        <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
          <label>[FIELDCAPTION_Order]</label>
        </div>
        <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
          <span>[FIELDVALUE_PackInfo_SalesOrder]</span>
        </div>
      </div>
      <div class="form-group">
        <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
          <label>[FIELDCAPTION_PickTicket]</label>
        </div>
        <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
          <span>[FIELDVALUE_PackInfo_PickTicket]</span>
        </div>
      </div>
      <div class="form-group">
        <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
          <label>[FIELDCAPTION_Customer]</label>
        </div>
        <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
          <span>[FIELDVALUE_PackInfo_CustomerName]</span>
        </div>
      </div>
      <div class="form-group">
        <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
          <label>[FIELDCAPTION_ShipTo]</label>
        </div>
        <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
          <span>[FIELDVALUE_PackInfo_ShipToId]</span>
          <span>[FIELDVALUE_PackInfo_ShipToName]</span>
          <span>[FIELDVALUE_PackInfo_ShipToCSZ]</span>
        </div>
      </div>
      <div class="form-group">
        <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
          <label>[FIELDCAPTION_ShipVia]</label>
        </div>
        <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
          <span>[FIELDVALUE_PackInfo_ShipVia]</span>
        </div>
      </div>
      <div class="form-group">
        <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
          <label>[FIELDCAPTION_CustPO]</label>
        </div>
        <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
          <span>[FIELDVALUE_PackInfo_CustPO]</span>
        </div>
      </div>
    </div>
  </div>
  <div class="amf-form-layout-container" data-rfsubmitpreprocess="Packing_PopulateEntityInput">
    <input type="hidden" data-rfname="PackingCarton">
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
    data-rfmodelvalueprefix="PACKDETAILS,NOTES">
    <input type="hidden" data-rfname="PackedInfo">
    <div class="col-md-6 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-4 col-sm-6 col-xs-12">
            <div class="form-group">
              <input class="amf-input" type="text" name="PickTicket" id="PickTicket" placeholder="[FIELDCAPTION_AMFScanPTOrLPNOrToteOrCart_PH]"
              data-rfname="PickTicket" data-displaycaption="[FIELDCAPTION_PickTicket]" value="[FIELDVALUE_PackInfo_PickTicket]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
              data-rfsubmitform="true" data-rftabindex="1"
              data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_OrderId]"
              data-rfinputtype="SCANNER">
              <label for="PickTicket">[FIELDCAPTION_PickTicket]</label>
            </div>
          </div>
          <div class="col-md-8 col-sm-6 col-xs-12">
            <div class="amf-datacard-container">
              <div class="form-group">
                <input class="amf-input" type="text" name="Customer" id="Customer" placeholder=""
                data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_OrderId]"
                value="[FIELDVALUE_PackInfo_CustomerName]">
                <label for="Customer">Customer</label>
              </div>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-sm-6 col-xs-12">
            <div class="amf-datacard amf-form-number-input-control-bg-none">
              <label class="col-form-label">Quantity</label>
              <div class="clearfix"></div>
              <div class="amf-form-number-input-container">
                <span class="amf-form-number-input-decrement">-</span>
                <input class="amf-form-number-input amf-form-number-input-width" size="4" type="text" inputmode="numeric"
                data-rfname="Quantity" data-displaycaption="[FIELDCAPTION_Quantity]" value="1"
                data-rfvalidationset="GREATEROREQUAL" data-rfvalidation-greaterorequal="1" data-rfsubmitform="false">
                <span class="amf-form-number-input-increment">+</span>
              </div>
            </div>
          </div>
          <div class="col-md-8 col-sm-6 col-xs-12 amf-mt-10">
            <div class="form-group">
              <input class="amf-input" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKU_PH]" value=""
              data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" data-rfvalidateon="FOCUSOUT"
              data-rfvalidationhandler="Packing_OnSKUEnter" data-rfsubmitform="false" data-rftabindex="2">
              <label for="SKU">[FIELDCAPTION_SKU]</label>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-12 col-sm-12 col-xs-12">
            <div class="amf-datacard-container">
              <div class="amf-datacard js-packing-skuinfo hidden">
                <div class="col-md-9 col-sm-9 col-xs-12 amf-border-right">
                  <span class="amf-display-value-medium" data-rfjsname="SKU"></span>
                  <span class="amf-display-value-small" data-rfjsname="SKUDescription"></span>
                  <span class="amf-display-value-small" data-rfjsname="UPC"></span>
                  <div class="clearfix amf-hr"></div>
                  <div class="row">
                    <div class="col-md-4 col-sm-4 col-xs-4 amf-border-separate">
                      <label class="col-form-label">[FIELDCAPTION_SKU2]</label>
                      <span class="amf-display-value" data-rfjsname="sku2"></span>
                    </div>
                    <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
                      <label class="col-form-label">[FIELDCAPTION_SKU3]</label>
                      <span class="amf-display-value" data-rfjsname="sku3"></span>
                    </div>
                    <div class="col-md-5 col-sm-5 col-xs-5">
                      <label class="col-form-label">[FIELDCAPTION_SKU4]</label>
                      <span class="amf-display-value" data-rfjsname="sku4"></span>
                    </div>
                  </div>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-4 amf-data-layout-responsive hidden">
                  <label class="col-form-label"></label>
                  <image src="[SESSIONKEY_SKUIMAGEPATH][FIELDVALUE_SKUImageURL]" alt="image" class="img-responsive">
                </div>
              </div>
            </div>
            <div class="amf-mb-10"></div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-sm-6 col-xs-4">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth js-packing-confirmsku"
            data-rfclickhandler="Packing_ScanPackItem">Pack Item</button>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-4">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="Packing_ConfirmPackOrder">Close Carton</button>
          </div>
        </div>
      </div>
      <div class="amf-form-panel-shadow">
        <div class="table-responsive" style="height:210px; margin-bottom:15px;">
          <table class="table scroll table-striped table-bordered">
            <thead>
              <tr>
                <th>[FIELDCAPTION_Notes]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_NOTES]
            </tbody>
          </table>
        </div>
        <div class="clearfix"></div>
      </div>
    </div>
    <div class="col-md-6 col-sm-12 col-xs-12 amf-form-display-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-8 col-sm-8 col-xs-8">
            <div class="amf-mb-10"></div>
            <h3 class="amf-datacard-title">Items Remaining To Pack <span class="amf-text-important" data-rfjsname="RemainingUnitsToPack">12</span></h3>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4 pull-right">
            <div class="form-group">
              <input class="amf-input" type="text" name="FilterValue" id="FilterValue"
              placeholder="[FIELDCAPTION_Filter]" data-rfname="FilterValue"
              data-displaycaption="[FIELDCAPTION_Filter]" value="">
            </div>
          </div>
        </div>
        <div class="table-responsive">
          <table id="packingtbl" data-rfrecordname="CartonDetails" class="table scroll table-striped table-bordered js-datatable-packing-packlist">
            <thead>
              <tr>
                <th data-rffieldname="DisplaySKU">[FIELDCAPTION_SKU]</th>
                <th data-rffieldname="SKUDescription">[FIELDCAPTION_SKUDescription]</th>
                <th hidden data-rffieldname="SKU2Description">[FIELDCAPTION_SKU2Description]</th>
                <th data-rffieldname="LPN">[FIELDCAPTION_LPN]</th>
                <th data-rffieldname="UnitsToPack">[FIELDCAPTION_UnitsToPack]</th>
                <th data-rffieldname="UnitsPacked">[FIELDCAPTION_UnitsPacked]</th>
                <th hidden data-rffieldname="UnitWeight">[FIELDCAPTION_UnitWeight]</th>
                <th hidden data-rffieldname="UPC">[FIELDCAPTION_UPC]</th>
                <th hidden data-rffieldname="SKUBarcode">[FIELDCAPTION_SKUBarcode]</th>
                <th hidden data-rffieldname="AlternateSKU">[FIELDCAPTION_AlternateSKU]</th>
                <th hidden data-rffieldname="SKU1">[FIELDCAPTION_SKU1]</th>
                <th hidden data-rffieldname="SKU2">[FIELDCAPTION_SKU2]</th>
                <th hidden data-rffieldname="SKU3">[FIELDCAPTION_SKU3]</th>
                <th hidden data-rffieldname="SKU4">[FIELDCAPTION_SKU4]</th>
                <th hidden data-rffieldname="SKU5">[FIELDCAPTION_SKU5]</th>
                <th hidden data-rffieldname="SKUId">[FIELDCAPTION_SKUId]</th>
                <th hidden data-rffieldname="SKU">[FIELDCAPTION_SKU]</th>
                <th hidden data-rffieldname="OrderId">[FIELDCAPTION_OrderId]</th>
                <th hidden data-rffieldname="OrderDetailId">[FIELDCAPTION_OrderDetailId]</th>
                <th hidden data-rffieldname="LPNId">[FIELDCAPTION_LPNId]</th>
                <th hidden data-rffieldname="LPNDetailId">[FIELDCAPTION_LPNDetailId]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_PACKDETAILS]
            </tbody>
          </table>
        </div>
        <div class="amf-data-footer">
          <p>Total Units to pack: [FIELDVALUE_UnitsToPack]</p>
        </div>
        <div class="clearfix"></div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;