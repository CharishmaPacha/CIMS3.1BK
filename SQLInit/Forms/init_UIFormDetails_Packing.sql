/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/15  OK      Added button for PACKCOMPLETEORDER (BK-658)
  2021/06/16  NB      Added Icon to PackingModes Menu Button
  2021/06/08  NB      Added PackingCartonTypes placeholder, new button for carton type option,
                      added packing status info section(CIMSV3-156)
  2021/05/05  NB      Initial revision(CIMSV3-156)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;


/*------------------------------------------------------------------------------*/
/* Packing_StandardOrder Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'Packing_StandardOrder';
/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
         (FormName,  FieldName,  UIControl, RawHtml, BusinessUnit)
  select  @FormName, @FormName, 'Html',
'<div class="col-md-12 js-Packing_StandardOrder js-packing-input-form-container" data-packingfontsize="20">
   <div class="col-md-12 pl-0 clearfix">
     <div class="col-md-4 pl-0 d-flex justify-content-start float-left">
       <b class="cims-font-bold js-packing-status-info">Start New Package</b>
     </div>
     <div class="col-md-4 d-flex justify-content-end float-right">
       <div class="btn-group cims-packing-form-toolbar">
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light js-packing-form-toolbar-btn" data-packingaction="STARTPACKAGE" data-toggle="tooltip" title="Start New Package"><i class="cims-icon-packing-start-new-package"></i></button>
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light js-packing-form-toolbar-btn" data-packingaction="CLOSEPACKAGE" data-toggle="tooltip" title="Close Package"><i class="cims-icon-packing-close-package"></i></button>
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light js-packing-form-toolbar-btn" data-packingaction="RESETPACKAGE" data-toggle="tooltip" title="Reset Package"><i class="cims-icon-packing-reset-package"></i></button>
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light js-packing-form-toolbar-btn hidden" data-packingaction="UNPACKPACKAGE" data-toggle="tooltip" title="Start Unpacking"><i class="cims-ti-export"></i></button>
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light js-packing-form-toolbar-btn" data-packingaction="STOPPACKING" data-toggle="tooltip" title="Stop Packing"><i class="cims-icon-packing-stop-packing"></i></button>
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light js-packing-form-toolbar-btn" data-packingaction="SCANSKU" data-toggle="tooltip" title="Scan SKU"><i class="cims-icon-packing-scan-sku"></i></button>
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light js-packing-form-toolbar-btn" data-packingaction="SETCARTONTYPE" data-toggle="tooltip" title="set Package Type"><i class="cims-icon-packing-update-weight"></i></button>
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light js-packing-form-toolbar-btn" data-packingaction="PACKCOMPLETEORDER" data-toggle="tooltip" title="Pack Complete Order"><i class="cims-icon-packing-packcompleteorder"></i></button>
       </div>
       <div class="dropdown js-change-packing-mode-options-container">
         <button type="button" class="dropdown-toggle btn btn-primary cims-packing-mode-dropdown-btn js-packing-mode-btn" data-toggle="dropdown"><i class="cims-icon-packing-packingmodeoptions"></i></button>
         <div class="dropdown-menu dropdown-menu-right">
           [PACKINGMODEOPTIONS]
         </div>
       </div>
     </div>
   </div>
   <div class="col-md-12">
     <div class="js-packing-input-container" data-packinginputname="PACKINGCOMMAND">
       <div class="form-group form-inline">
         <label class="ml-3 js-packing-input-control-label">Command</label>
         <input type="text" class="form-control cims-packing-input-control ml-2 js-packing-input-control" data-packingvaluename="PACKINGCOMMAND" data-toggle="tooltip" title="Packing Input" value="">
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light ml-3 js-packing-input-control-btn"><i class="cims-ti-check"></i></button>
        </div>
     </div>
   </div>
   <div class="col-md-12">
     <div class="js-packing-input-container clearfix" data-packinginputname="PACKINGSKUQTY">
       <div class="form-group form-inline float-left">
         <label class="ml-3 js-packing-input-control-label">SKU</label>
         <input type="text" class="form-control cims-packing-input-control ml-2 js-packing-input-control" data-packingvaluename="PACKINGSKU" data-toggle="tooltip" title="Packing Input" value="">
         <label class="ml-3 js-packing-input-control-label js-packing-quantity-input">Quantity</label>
         <input type="number" class="form-control cims-packing-input-control ml-2 js-packing-input-control js-packing-quantity-input" data-packingvaluename="PACKEDQTY" data-toggle="tooltip" title="Packing Input" value="">
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light ml-3 js-packing-input-control-btn"><i class="cims-ti-check"></i></button>
       </div>
       <img class="js-packing-skuimage float-right pl-1 mr-4 hidden" alt="" height="100" width="100">
     </div>
   </div>
   <div class="col-md-12">
     <div class="js-packing-input-container" data-packinginputname="PACKAGEWEIGHT">
       <div class="form-group form-inline">
         <label class="ml-3 js-packing-input-control-label">Package Weight</label>
         <input type="number" step="0.01" class="form-control cims-packing-input-control ml-2 js-packing-input-control" data-packingvaluename="PACKAGEWEIGHT" data-toggle="tooltip" title="Packing Input" value="">
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light ml-3 js-packing-input-control-btn"><i class="cims-ti-check"></i></button>
       </div>
     </div>
   </div>
   <div class="col-md-12">
     <div class="js-packing-input-container" data-packinginputname="PACKAGECARTONTYPE">
       <div class="form-group form-inline">
         <label class="ml-3 js-packing-input-control-label">Package Type</label>
         <select class=" form-control cims-packing-input-control js-packing-input-control ml-2" data-packingvaluename="PACKAGECARTONTYPE" data-toggle="tooltip" title="Packing Input" value="">
           [PACKINGCARTONTYPES]
         </select>
         <button type="button" class="btn btn-primary cims-waves-effect cims-waves-light ml-3 js-packing-input-control-btn"><i class="cims-ti-check"></i></button>
       </div>
     </div>
   </div>
 </div>',  BusinessUnit from vwBusinessUnits;

Go
