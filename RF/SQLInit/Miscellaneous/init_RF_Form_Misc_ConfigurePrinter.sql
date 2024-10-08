/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/03  RIA    Changes to fetch printers dynamically (HA-2113)
  2020/10/25  RIA    Alignment changes (CIMSV3-1168)
  2020/06/02  SPP/SV If no printers in DB, add empty to printer list (CIMS-3107)
  2020/05/28  RT     Changes to use Printers instead of Devices (HA-683)
  2020/05/01  SAK    Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/04/07  RT     Initial Revision
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Misc_ConfigurePrinter';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Configure Printer', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Configure Printer</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFMiscellaneous"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <div class="col-md-6 col-md-6 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-8 col-sm-8 col-xs-6">
            <div class="form-group">
              <select class="form-control" data-rfdefaultvalue = "" data-rfvalidationset="NOTNULL"
              data-displaycaption="[FIELDCAPTION_Printer]" data-rfname="SelectedPrinter">[DBDATASET_vwPrinters_PrinterName_PrinterDescription]</select>
              <label class="col-form-label">[FIELDCAPTION_Printer]</label>
            </div>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-6">
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
