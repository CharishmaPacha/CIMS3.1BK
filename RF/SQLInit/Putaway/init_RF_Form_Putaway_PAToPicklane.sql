/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/02/11  RIA     Changed validation set for numeric input (CIMSV3-656)
  2019/11/26  RIA     Changes to show 10 digits in LPN (CIMSV3-656)
  2019/09/18  VS      Get the PAList based on Putawaysequence (CID-1039)
  2019/08/14  RIA     Initial Revision(CID-910)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Putaway_PAToPickLane';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Putaway to Picklane', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Putaway to Picklane</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPutaway"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-operation-info-open" style="margin-right:0px;"><i class="amfi-info"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfshowpreprocess="Putaway_PAToPicklane_OnShow">
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="PALLETLPNDETAILS" />
  <div class="container">
    <div class="amf-form-operation-info">
      <a  class="amf-form-operation-info-close">&times;</a>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_Pallet]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_PalletInfo_Pallet]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_ReceiptOrder]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_PalletInfo_ReceiptOrder]</span>
          </div>
        </div>
        <div class="form-group" hidden>
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_User]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_PalletInfo_User]</span>
          </div>
        </div>
      </div>
    </div>
    <div class="amf-form-layout-container">
      <div class="row">
        <div class="col-md-6 col-xs-12">
          <div class="amf-data-layout-container amf-form-padding-responsive">
            <div class="row">
              <div class="form-group">
                <div class="col-md-7 col-xs-5 amf-data-layout-responsive" style="border-right:1px solid #ccc;">
                  <label class="col-form-label">[FIELDCAPTION_AMFPutawayFromLPN]</label>
                  <span class="amf-display-value-largebold">[FIELDVALUE_PADetails_LPNRight10]</span>
                </div>
                <div class="col-xs-4 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCAPTION_AMFPAQuantity]</label>
                  <span class="amf-display-value-largebold" style="color:#b41700">[FIELDVALUE_PADetails_Quantity]</span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="form-group">
                <div class="col-md-7 col-xs-5 amf-data-layout-responsive" style="border-right:1px solid #ccc;">
                  <span class="amf-display-value-medium" data-rfjsname="SKU" data-rfvalue="[FIELDVALUE_PADetails_SKU]">[FIELDVALUE_PADetails_SKU]</span>
                  <span class="amf-display-value-small" data-rfjsname="UPC" data-rfvalue="[FIELDVALUE_PADetails_UPC]">[FIELDVALUE_PADetails_UPC]</span>
                  <span class="amf-display-value-small">[FIELDVALUE_PADetails_SKUDescription]</span>
                </div>
                <div class="col-xs-4 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCAPTION_AMFPALocation]</label>
                  <span class="amf-display-value-largebold">[FIELDVALUE_PADetails_PrimaryLocation]</span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="form-group">
                <div class="col-xs-4 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCAPTION_SKU]<sup style="color:red">*</sup></label>
                  <input type="text" class="form-control amf-form-control"
                  data-rfname="PASKU" data-displaycaption="[FIELDCAPTION_SKU]"
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Putaway_PAToPicklane_ValidateSKU"
                  data-rftabindex="1" data-rfinputtype="SCANNER">
                </div>
                <div class="col-xs-3 amf-data-layout-responsive" style="padding:0 10px;">
                  <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
                  <span class="amf-form-number-input-decrement" style="font-size:30px">-</span>
                  <input type="text" inputmode="numeric" class="amf-form-number-input amf-form-number-input-width"
                  data-rfname="PutawayUnits" data-displaycaption="[FIELDCAPTION_Quantity]" value="[FIELDVALUE_PADetails_Quantity]"
                  data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="1,[FIELDVALUE_PADetails_Quantity]"><span class="amf-form-number-input-increment" style="font-size:30px">+</span>
                </div>
                <div class="col-md-5 col-xs-5 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCAPTION_Location]</label>
                  <input type="text" class="form-control amf-form-control"
                  data-rfname="PALocation" data-displaycaption="[FIELDCAPTION_Location]" data-rfvalidationset="NOTNULL"
                  data-rfsubmitform="true" data-rftabindex="2" data-rfinputtype="SCANNER">
                </div>
              </div>
            </div>
            <div class="row">
              <div class="amf-data-layout-btns">
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-primary" data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
                </div>
              <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                <button type="button" class="btn btn-default" data-rfclickhandler="Putaway_PAToPickLane_PausePA">Pause/Stop</button>
              </div>
              <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                <button type="button" class="btn btn-default"
                data-rfclickhandler="Putaway_PAToPickLane_SkipSKU">Skip SKU</button>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
              <div class="amf-data-timer"></div>
            </div>
          </div>
        </div>
      </div>
        <div class="col-md-6 col-xs-12">
          <div class="row">
          <div class="col-md-12">
            <h3 class="amf-datacard-title">SKUs to Putaway</h3>
          </div>
        </div>
        <div class="table-responsive">
          <table class="table scroll table-striped table-bordered js-datatable-confirmputawaylpn-palist">
            <thead>
              <tr>
                <th>[FIELDCAPTION_LPN]</th>
                <th>[FIELDCAPTION_SKU]</th>
                <th>[FIELDCAPTION_SKUDescription]</th>
                <th>[FIELDCAPTION_Quantity]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_PALLETLPNDETAILS]
            </tbody>
          </table>
        </div>
        <div class="amf-data-footer">
          <p>[FIELDVALUE_PalletPASummary]</p>
        </div>
      </div>
    </div>
  </div>
  </div>
</div>
'
from vwBusinessUnits;
