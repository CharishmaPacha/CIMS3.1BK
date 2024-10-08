/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  PK      Added LocationBarcode (HA-1971)
  2020/09/08  RIA     Included button for stop and clean up (HA-1405)
  2020/09/03  RIA     Initial Revision(HA-1079)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'CycleCount_ScanSuggestedLoc';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Scan Suggested Location', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Directed Cycle Count</span>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" data-rfname="BatchNo" />
  <input type="hidden" data-rfname="PickZone" />
  <input type="hidden" data-rfname="IsSuggLocScanned" />
  <input type="hidden" data-rfname="LocationBarcode" />
  <div class="container">
    <div class="row">
      <div class="col-md-6 col-xs-12">
        <div class="form-group">
          <input class="amf-input-details" type="text" name="SuggestedLoc" id="SuggestedLoc" placeholder="[FIELDCAPTION_AMFScanSuggLocation_PH]"
          data-rfname="SuggestedLoc" data-displaycaption="[FIELDCAPTION_AMFSuggestedLocation]" value="[FIELDVALUE_SuggestedLocation]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_SuggestedLocation]"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="SuggestedLoc">[FIELDCAPTION_AMFSuggestedLocation]</label>
        </div>
        <div class="amf-datacard-container">
          <div class="form-group">
            <input class="amf-input-details" type="text" name="ScannedLocation" id="ScannedLocation" placeholder="[FIELDCAPTION_AMFScanSuggLocation_PH]"
            data-rfname="ScannedLocation" data-displaycaption="[FIELDCAPTION_AMFScanLocation]" value=""
            data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
            data-rfvalidationhandler="CC_DirectedCount_ValidateAndSetInputs"
            data-rftabindex="2" data-rfinputtype="SCANNER">
            <label for="SuggLocation">[FIELDCAPTION_AMFScanLocation]</label>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-4">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-form-submit"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-4">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-form-submit"
              data-rfclickhandler="CC_DirectedCount_Stop">Stop Count</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
