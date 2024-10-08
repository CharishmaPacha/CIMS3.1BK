/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/12/24  RIA     Made changes to show similar form as of unit picking (CID-1214)
  2019/12/13  RIA     Made changes to show the required info (CID-1214)
  2019/01/08  NB      changes for addressing renaming of tables for AMF and naming conventions (AMF-26)
  2018/11/06  NB      Initial Revision(CIMSV3-331)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'BatchPicking_ConfirmLPNPick';
delete from AMF_Forms where FormName = @vFormName; 

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Confirm LPN Pick', 'STD', BusinessUnit,
'
<div class="amf-form-header-container-tablet">
  <div class="container">
    <div class="amf-form-heading-tablet">
      <a class="amf-form-heading-logo-tablet" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name-tablet" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Confirm LPN Pick</span>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-menu-open"><i class="amfi-menu"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-operation-info-open"><i class="amfi-info"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfsubmitpreprocess="Picking_ConfirmUnitPick_ProcessInputs" data-rfshowpreprocess="Picking_ConfirmUnitPick_OnShow">
  <div class="container">
    <input type="hidden" data-rfname="Operation"value="CustomerOrderPicking" />
    <input type="hidden" data-rfname="ShortPick" value="N" />
    <div class="amf-form-menu">
      <a class="amf-form-menu-close">&times;</a>
      <button type="button" class="btn btn-info" data-rfclickhandler="Picking_ConfirmUnitPick_ShortPick">Short Pick</button>
    </div>
    <div class="amf-form-operation-info">
      <a class="amf-form-operation-info-close">&times;</a>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_WaveNo]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOBatchNo]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_AMFPalletOrCart]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOPickToPallet]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_TaskId]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOTaskId]</span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_PickTicket]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOPickTicket]</span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_NumOrders]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOTaskNumOrders]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_User]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOUserNameDisplay]</span>
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
                <div class="col-md-8 col-xs-8 amf-data-layout-responsive" style="border-right:1px solid #ccc;">
                  <label class="col-form-label">[FIELDCAPTION_AMFPickFrom]</label>
                  <span class="amf-display-value-largebold">[FIELDVALUE_BATCHPICKINFOPickFromDisplay]</span>
                  <span class="amf-display-value-small">Zone [FIELDVALUE_BATCHPICKINFOPickZoneDesc]</span>
                  <span class="amf-display-value-medium" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_BATCHPICKINFOLocationType]"
                  data-rfvisiblecomparewith="R,B" style="color:#b41700">[FIELDVALUE_BATCHPICKINFOLPN]</span>
                </div>
                <div class="col-md-4 col-xs-4 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCAPTION_AMFToPick]</label>
                  <span class="amf-display-value-extralargebold">[FIELDVALUE_BATCHPICKINFOTotalUnitsToPick]</span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="form-group">
                <div class="col-xs-8 amf-data-layout-responsive" style="border-right:1px solid #ccc;">
                  <span class="amf-display-value-medium">[FIELDVALUE_BATCHPICKINFODisplaySKU]</span>
                  <span class="amf-display-value-small">[FIELDVALUE_BATCHPICKINFOUPC]</span>
                  <span class="amf-display-value-small">[FIELDVALUE_BATCHPICKINFODisplaySKUDesc]</span>
                </div>
                <div class="col-xs-4 amf-data-layout-responsive" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_BATCHPICKINFOPickToLPN]">
                  <label class="col-form-label">[FIELDVALUE_BATCHPICKINFOScanPickToCaption]</label>
                  <span class="amf-display-value-largebold">[FIELDVALUE_BATCHPICKINFOPickToLPN]</span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="form-group">
                <div class="col-xs-4 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDVALUE_BATCHPICKINFOPickEntityCaption]<sup style="color:red">*</sup></label>
                  <input type="text" class="form-control amf-form-control" data-rfname="PickedEntity"
                  data-displaycaption="[FIELDVALUE_BATCHPICKINFOPickEntityCaption]"
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Picking_ConfirmUnitPick_ValidatePickedEntity"
                  data-rftabindex="1" data-rfinputtype="SCANNER">
                </div>
                <div class="col-md-4 col-xs-4 amf-data-layout-responsive" style="padding:0 10px;"
                data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_OPTIONSEnableScanSKU]" data-rfvisiblecomparewith="Y">
                  <label class="col-form-label">Scan SKU</label>
                  <input type="text" class="form-control amf-form-control" data-rfname="SKUPicked" data-displaycaption="[FIELDVALUE_BATCHPICKINFOPickEntityCaption]" value=""
                  data-rfvalidationset="NOTNULL" data-rfenabled="COMPAREWITH" data-rfenabledvalue="[FIELDVALUE_OPTIONSEnableScanSKU]"
                  data-rfenabledcomparewith="Y" data-rfsubmitform="true"
                  data-rfinputtype="SCANNER" data-rftabindex="3"/>
                </div>
                <div class="col-md-4 col-xs-4 amf-data-layout-responsive" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_BATCHPICKINFOScanPickToCaption]">
                  <label class="col-form-label">[FIELDVALUE_BATCHPICKINFOScanPickToCaption]</label>
                  <input type="text" class="form-control amf-form-control" data-rfname="PickedTo"
                  data-displaycaption="[FIELDVALUE_BATCHPICKINFOScanPickToCaption]" value="[FIELDVALUE_DefaultPickToLPN]"
                  data-rfvalidationset="NOTNULL" data-rfenabled="COMPAREWITH" data-rfenabledvalue="[FIELDVALUE_OPTIONSEnablePickToLPN]"
                  data-rfenabledcomparewith="Y" data-rfsubmitform="true" data-rftabindex="4" data-rfinputtype="SCANNER"/>
                </div>
              </div>
            </div>
            <div class="row" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_OPTIONSIsCoORequired]" data-rfvisiblecomparewith="Y">
              <div class="form-group">
                <div class="col-xs-5 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCaption_AMFCoO]<sup style="color:red">*</sup></label>
                  <input type="text" data-rfname="CoO" data-displaycaption="CoO" value="" data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rftabindex="2"  class="form-control amf-form-control" data-rfinputtype="SCANNER"/>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="amf-data-layout-btns">
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-default" data-rfclickhandler="Picking_ConfirmUnitPick_SkipPick">Skip Pick</button>
                </div>
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-default" data-rfclickhandler="Picking_ConfirmUnitPick_PausePicking">Pause/Stop</button>
                </div>
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-primary" data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="col-md-6 col-xs-12">
          <div class="row">
            <div class="col-md-12">
              <h3 class="amf-datacard-title">Pick List for Task [FIELDVALUE_BATCHPICKINFOTaskId] ([FIELDVALUE_BATCHPICKINFOPickToPallet])</h3>
            </div>
          </div>
          <div class="table-responsive">
            <table class="table scroll table-striped table-bordered js-datatable-confirmunitpick-picklist">
              <thead>
                <tr>
                  <th>[FIELDCAPTION_LPN/Location]</th>
                  <th hidden>[FIELDCAPTION_PickZone]</th>
                  <th>[FIELDCAPTION_SKU]</th>
                  <th>[FIELDCAPTION_SKUDescription]</th>
                  <th hidden>[FIELDCAPTION_NumPicks]</th>
                  <th hidden>[FIELDCAPTION_TotaLIPs]</th>
                  <th hidden>[FIELDCAPTION_TotalQty]</th>
                  <th hidden>[FIELDCAPTION_IPsToPick]</th>
                  <th>[FIELDCAPTION_Quantity]</th>
                </tr>
              </thead>
              <tbody>
                [DATATABLE_PICKLIST]
              </tbody>
            </table>
          </div>
          <div class="amf-data-footer">
            <p>[FIELDVALUE_BATCHPICKINFOPickListSummary]</p>
          </div>
          <div class="row">
            <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
              <div class="js-cimsrfc-confirmunitpick-picking-timer amf-data-timer"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
