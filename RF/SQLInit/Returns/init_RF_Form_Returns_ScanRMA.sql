/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/12  RIA     Clean up and corrections (OB2-1357)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/02/24  RIA     Initial Revision(CIMSV3-732)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Returns_ScanRMA';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Scan RMA', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Scan RMA</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFReturns"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" data-rfname="Operation" value="ReturnsReceiving" >
  <div class="col-md-5 col-sm-5 col-xs-12 amf-form-input-panel">
    <div class="amf-form-panel-shadow">
      <div class="row">
        <div class="col-md-12 col-xs-7 amf-form-input-responsive-width">
          <div class="form-group">
            <input class="amf-input-details" type="text" name="ScanRMA" id="ScanRMA" placeholder="[FIELDCAPTION_AMFRMAOrShippingCarton_PH]"
            data-rfname="Entity" data-displaycaption="[FIELDCAPTION_AMFRMAOrShippingCarton]" value=""
            data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
            data-rftabindex="1" data-rfinputtype="SCANNER">
            <label for="ScanRMA">[FIELDCAPTION_AMFRMAOrShippingCarton]</label>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-md-6 col-sm-6 col-xs-6">
          <div class="form-group">
            <button type="button" class="btn btn-primary amf-button-top-margin"
            data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
