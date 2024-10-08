/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/08/14  RIA     Initial Revision(CID-910)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Putaway_PAToPL_ScanPalletOrCart';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'PAToPL - Scan Pallet/Cart', 'STD', BusinessUnit, 
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Putaway To Picklane</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPutaway"><span class="pull-right"><i class="amfi-back-left"></i></span></a>                
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y" />
  <input type="hidden" data-rfname="Operation" value="~Operation~" />
  <div class="container">
    <div class="row">
      <div class="col-md-4 col-xs-7 amf-form-input-responsive-width">
        <div class="form-group"> 
          <input class="amf-input-details" type="text" name="ScanPalletOrCart" id="ScanPalletOrCart" placeholder="[FIELDCAPTION_AMFPalletOrCart_PH]"
          data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]" value=""
          data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="Pallet">[FIELDCAPTION_AMFPalletOrCart]</label>
        </div>
      </div>
      <div class="col-md-2 col-xs-5 amf-form-input-responsive-width">
        <div class="form-group">
          <button type="submit" class="btn btn-primary amf-button-top-margin">Submit</button>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
