/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/29  RIA     Changed data-rfname for input (CIMSV3-622)
  2020/09/17  RIA     Clean up (CIMSV3-622)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/09/06  RIA     Initial Revision(CID-996)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Packing_ScanOrder';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Scan Order', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Packing</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPacking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-8 col-sm-8 col-xs-8">
            <div class="form-group">
              <input class="amf-input" type="text" name="Order" id="Order" placeholder="[FIELDCAPTION_AMFScanPTOrLPNOrToteOrCart_PH]"
              data-rfname="ScannedEntity" data-displaycaption="[FIELDCAPTION_Order]" value=""
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
              data-rftabindex="1" data-rfinputtype="SCANNER">
              <label for="Order">[FIELDCAPTION_Order]</label>
            </div>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4">
            <div class="form-group">
              <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;