/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/14  RIA     Changed the visibility validation for outstandingpicks (BK-587)
  2020/09/04  TK      Changes to display orders violating ship complete rules (HA-1175)
  2020/05/30  RIA     Form clean up (HA-649)
  2020/05/26  AY      Split DropPallet/Drop Cart forms (HA-649)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/07/23  AY      Changed to hide outstanding picks message if task is completed
  2019/07/04  AY      Fixed Outstanding picks - showing duplicate totes (CID-616)
  2019/06/04  RIA     Changes to show Incomplete orders / picks (CID-517)
  2019/02/21  NB      1280x800 version of ValidatePallet (CIMSV3-366)
  2019/01/08  NB      changes for addressing renaming of tables for AMF and naming conventions (AMF-26)
  2018/11/23  NB      Initial Revision(CIMSV3-331)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'DropPickingCart_Confirm';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Drop Cart', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Drop Cart</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_DROPPALLETRESPONSEPallet]"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <div class="container">
    <input  type="hidden" data-rfname="Operation"value="DropPallet" />
    <div class="row">
      <div class="col-md-4 col-xs-5 amf-form-input-responsive-width">
        <div class="form-group">
          <input type="text" name="Pallet" placeholder="[FIELDCAPTION_AMFPalletOrCart_PH]"
          data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT"
          data-rfvalidationhandler="Picking_DropPallet_ValidatePallet"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_DROPPALLETRESPONSEPallet]"
          value="[FIELDVALUE_DROPPALLETRESPONSEPallet]" data-rftabindex="1"/>
          <label for="Pallet">[FIELDCAPTION_AMFPalletOrCart]</label>
        </div>
      </div>
      <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
        <div class="form-group">
          <input type="text" name="DroppedLocation" placeholder="[FIELDCAPTION_AMFDropLocation_PH]" data-rfname="DroppedLocation" data-displaycaption="[FIELDCAPTION_Location]"  data-rfvalidationset="NOTNULL" data-rftabindex="2" data-rfsubmitform="true"/>
          <label for="DroppedLocation">[FIELDCAPTION_Location]</label>
        </div>
      </div>
      <div class="col-md-2 col-xs-3 amf-form-input-responsive-width">
        <div class="form-group">
          <button type="submit" class="btn btn-primary amf-button-top-margin">Submit</button>
        </div>
      </div>
    </div>
    <div class="amf-datacard-container" style="background:none;" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_DROPPALLETRESPONSEPallet]">
      <div class="row">
        <div class="col-md-12 col-xs-12" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_ShowOutstandingPicks]" data-rfvisiblecomparewith="Y">
          <h3 class="amf-data-title" style="color:red">Incomplete Orders on Cart</h3>
        </div>
        <div class="col-md-12 col-xs-12" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_TaskInfo_TaskStatus]" data-rfvisiblecomparewith="C">
          <h3 class="amf-data-title" style="color:green">All Picks completed for Task</h3>
        </div>
      </div>
      <div class="row">
        <div class="col-md-5 col-xs-12" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_ShowOutstandingPicks]" data-rfvisiblecomparewith="Y">
          <div class="table-responsive">
            <table class="table scroll table-striped table-bordered">
              <thead>
                <tr>
                  <th>[FIELDCAPTION_PickTicket]</th>
                  <th>[FIELDCAPTION_Position]</th>
                  <th>[FIELDCAPTION_Status]</th>
                  <th>[FIELDCAPTION_NumUnits]</th>
                </tr>
              </thead>
              <tbody>
                [DATATABLE_OUTSTANDINGPICKS]
              </tbody>
            </table>
          </div>
          <div class="datatable-disqualifiedorders">
            <div class="amf-datacard-container">
              <div class="row">
                <div class="col-md-12 col-xs-12" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_HasDisqualifiedOrders]" data-rfvisiblecomparewith="Y">
                  <h3 class="amf-datacard-title" style="color:red">Orders Violating Ship Complete Rules</h3>
                </div>
              </div>
              <div class="row">
                <div class="col-md-12" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_HasDisqualifiedOrders]" data-rfvisiblecomparewith="Y">
                  <div class="table-responsive">
                    <table class="table scroll table-striped table-bordered">
                      <thead>
                        <tr>
                          <th>[FIELDCAPTION_PickTicket]</th>
                          <th>[FIELDCAPTION_Position]</th>
                          <th>[FIELDCAPTION_NumUnits]</th>
                          <th>[FIELDCAPTION_UnitsAssigned]</th>
                          <th>[FIELDCAPTION_SCPercent]</th>
                        </tr>
                      </thead>
                      <tbody>
                        [DATATABLE_DISQUALIFIEDORDERS]
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="col-md-7 col-xs-12">
          <div class="amf-datacard" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_DROPPALLETRESPONSEPallet]">
            <div class="col-md-6  col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Wave]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_WaveTypeDesc] [FIELDVALUE_TaskInfo_WaveNo]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_TaskId]</label>
              <span class="amf-display-value">[FIELDVALUE_DROPPALLETRESPONSETaskId]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFDropZone]</label>
              <span class="amf-display-value" style="color:#b41700">[FIELDVALUE_DROPPALLETRESPONSESuggestedDropZone]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_AMFDropLocation]</label>
              <span class="amf-display-value" style="color:#b41700">[FIELDVALUE_DROPPALLETRESPONSESuggestedDropLocation]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumOrders]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_NumOrders]</span>
            </div>
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFNumCartonsOnCart]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_NumCartonsOnCart]</span>
            </div>
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_AMFUnitsPicked]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_UnitsPicked] of [FIELDVALUE_TaskInfo_TotalUnits]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_TaskStatus]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_TaskStatusDesc]</span>
            </div>
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_AMFPicksCompleted]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_PicksCompleted] of [FIELDVALUE_TaskInfo_NumPicks]</span>
            </div>
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_PercentComplete]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_PercentComplete]%</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFNumCartonsUsed]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_NumCartonsUsed]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_AMFTaskAssignedTo]</label>
              <span class="amf-display-value">[FIELDVALUE_TaskInfo_AssignedToName]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
