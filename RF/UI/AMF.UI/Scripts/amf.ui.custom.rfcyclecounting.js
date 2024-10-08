//-----------------------------------------------------------------------------
$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

    // evt has multiple objects that could be used post the click on the element class
    $(document).on("click", ".js-datatable-cyclecount-confirmlpns tbody tr", function(evt)
      {
        // step 1: define the entity column name for the table on the form
        entitycolname = "LPN";
        // step 2: get the column index of that entity name on the form table
        // any object return found by column name would be indexed at 0
        var colidx = $($(document).find("[data-rffieldname='"+entitycolname+"']")[0]).index();
        // step 3: get the value of the entity name of that column for the row that is clicked
        // currentTarget is the row that has been clicked which is of length 1
        // any clicked row value would always be indexed at 0 and the column index is dynamic
        var entityvalueclicked = $($($(evt.currentTarget)[0]).find("td")[colidx]).text();
        // Form specific method to carry out more operations
        CC_ConfirmResvLocLPN_OnLPNClick(entityvalueclicked);
      });
});

//-----------------------------------------------------------------------------
//custom handler to execute stop Cycle Counting
function CC_ConfirmCount_Stop(evt)
{
    ConfirmYesNo("Are you sure you want to stop counting?",
        function ()
        {
            // when the user clicks yes button, save as STOP button
            $("#RFSkipInputValidation").val(true);
            $("[data-rfname='RFFormAction']").val("STOP");
            $("form").submit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//-----------------------------------------------------------------------------
// QIP (Quantity Input Panel) is a generic module to let user to enter IPs/Qty
// and it is modularized to ensure there is consistency across all pages.
// QIP is used for Picklane CC, but the behaviour needs to be different in this
// context - hence on show of the form, setup the QIP attributes and initial values.
function CC_ConfirmPicklane_OnShow()
{
  // Initialize variables
  var tableelement    = ".js-datatable-cyclecount-confirmskus";
  var ccdata          = $("[data-rfname='m_CCData']").val();
  var ccdatalist      = {};
  var ccdatalistlen   = 0;
  var inputdata       = {};
  var values          = {};
  var lastskuscanned  = $("[data-rfname='m_SKU']").val();
  //var inputqtyprompt  = $("[data-rfname='m_InputQtyPrompt']").val();
  var currentsku      = "";
  var promptsku       = "";
  var storagetype     = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var inventoryuom;
  var selector        = "";

  // Continue to tabulate these SKUs only if the above nodal data exists
  if ((ccdata != undefined) && (ccdata != ""))
  {
    ccdatalist    = JSON.parse(ccdata);
    ccdatalistlen = $(ccdatalist["CCData"]["CCTable"]).length;

    // If the object has only 1 array, convert that into json object array
    // Reason: the CC_JsonArrayFilter would need json object array within json object
    if (ccdatalistlen == 1)
    {
      var ccdatalistarray = [];
      ccdatalistarray.push(ccdatalist.CCData.CCTable);
      ccdatalist.CCData.CCTable = ccdatalistarray;
    }

    // loop through the SKU list and insert each SKU into the table
    for (len = 0; len < ccdatalistlen; len++)
    {
      currentsku = ccdatalist["CCData"]["CCTable"][len]["SKU"];

      // For cases where user needs to confirm the quantity we will not tabulate just as yet
      // In this case, the last SKU scanned was unknown and hence after validating it
      // we initiate the QIP panel for user to confirm the quantity
      if (currentsku == lastskuscanned)
      {
        promptsku = currentsku;
      }
      else
      {
        CC_Picklane_TableInsertUpdate(currentsku,
                                      ccdatalist["CCData"]["CCTable"][len]["SKUDescription"],
                                      ccdatalist["CCData"]["CCTable"][len]["NewUnits"],
                                      FORMCONTENT_UPDATETYPE_ADDUPDATE,
                                      FORMCONTENT_UPDATEMODE_BEFORE)
      }
    } // end of for loop

    // Setup QIP for the unknown SKU scanned
    // Focus will be set on QIP automatically
    if (promptsku != "")
    {
      $("[data-rfname='SKU']").val(promptsku);

      // Hide the input for UnitsPerIP
      QuantityInputPanel_HideInputs('N');

      // Clear the inputs and show the inputs
      QuantityInputPanel_ClearForm();

      // Initialize values for fields in the quantity input panel
      QuantityInputPanel_InitializeForSKU(inventoryuom, "", storagetype, 1, 1, null);

      $("[data-rfname='NewUnits1']").focus();

    }
    else
    // when there is no previous SKU, then show focus on SKU
    {
      $("[data-rfname='SKU']").focus();
    }
  } // end of if block
  else
  {
    $("[data-rfname='SKU']").focus();
  }

  // We need additional attributes for standard QIP panel, called the function to
  // add them, which is handled here
  // Any changes to js method names, need here as well
  selector = "[data-rfname='NewUnits1']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfvalidationhandler":"CC_Picklane_TabulateSKU","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector,values)

  // Generally validation handler settings are defined after form is rendered. In
  // this case as we added validation handler in form show, call the function to
  // define the settings
  VerifyFormForValidationSettings();

  // QIP by default has minimum value of 1 for Cases/Units, however in cc we need
  // to allow the user to confirm 0 qty and hence min values are changed to zero.
  QuantityInputPanel_InitializeMin(0);

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // CC_ConfirmPicklane_OnShow

//-----------------------------------------------------------------------------
// the list of SKUs being cycle counted in a picklane are maintained as a html
// table. This table is initialized with the SKUs in the Location first time
// and for dynamic picklanes, if a user scans an unknown SKU, it would be validated
// and added to the html table
function CC_Picklane_TableInsertUpdate(sku, skudesc, quantity, updatetype, updatemode)
{
  // form related
  var tableelement      = ".js-datatable-cyclecount-confirmskus";
  // Json objects
  var locskusjson       = {};
  var inputdata         = {};
  var coldetailstosum   = {};

  // Table body
  inputdata["EntityName"]   = "SKU";
  inputdata["ControlValue"] = [
                                {"SKU":sku,
                                 "SKUDescription":skudesc,
                                 "NewUnits":quantity}
                              ];
  inputdata["UpdateType"]   = updatetype;
  inputdata["UpdateMode"]   = updatemode;

  // Tabulate SKUs that are scanned
  ChangeFormContent(tableelement, inputdata);

  // Update Footer
  // Given values are the column index, & name to sum. Also respective footer attribute to update
  var coldetailstosum = {"COLS": [{"COLIDX":0, "FOOTERNAME":"NumSKUs", "TYPE":"COUNT", "ATTRIBUTE":".js-footer-cyclecount-NumSKUs"},
                                  {"COLIDX":2, "FOOTERNAME":"NumUnits", "TYPE":"SUM", "ATTRIBUTE":".js-footer-cyclecount-NumUnits"}]}

  CC_UpdateTableFooter(tableelement, inputdata, coldetailstosum);

} // CC_Picklane_TableInsertUpdate

//-----------------------------------------------------------------------------
// This method is used to confirm with user on stop of cycle count and if user
// acknowledges to stop assigns value to RFFormAction, skip input validations
// and submits
function CC_DirectedCount_Stop()
{
  ConfirmYesNo("Are you sure you want to stop counting?",
    function ()
    {
      // when the user clicks yes, assign the below value to RFFormAction
      $("[data-rfname='RFFormAction']").val("StopDirectedCount");
      SkipInputValidationsAndSubmit();
    },
    function ()
    {
      // do nothing, when the user clicks no
    });
} // CC_DirectedCount_Stop

//-----------------------------------------------------------------------------
// This method is used to validate whether user scanned suggested location or not
// and set the values to few fields as they are needed for further steps
function CC_DirectedCount_ValidateAndSetInputs()
{
  // Fetch the input values
  var suggestedlocation = $("[data-rfname='SuggestedLoc']").val();
  var scannedlocation   = $("[data-rfname='ScannedLocation']").val();
  var locationbarcode   = $("[data-rfname='m_LocationBarcode']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if ((suggestedlocation.toUpperCase() != scannedlocation.toUpperCase()) &&
      (locationbarcode.toUpperCase() != scannedlocation.toUpperCase()))
    message.Message.DisplayText = "Please scan suggested location to proceed further";

  if (message.Message.DisplayText == null)
    {
      $("[data-rfname='BatchNo']").val($("[data-rfname='m_BatchNo']").val());
      $("[data-rfname='PickZone']").val($("[data-rfname='m_PickZone']").val());
      $("[data-rfname='IsSuggLocScanned']").val('Y');
      return null; // caller expects null when there are no validation messages
    }
  else
    return message;
} // CC_DirectedCount_ValidateAndSetInputs

//-----------------------------------------------------------------------------
// When user scans a SKU to CC, validate and setup to enter the count of the SKU
// inventoryuom - when it comes to picklanes, SKU.InventoryUoM is not applicable,
//                the UoM is determined by the storage type of the Picklane
// locSKUsjson  - the list of SKUs known to be in the Location already
function CC_Picklane_OnSKUEnter(evt)
{
  // Clear the invalid-entity attribute as we will be validating it now
  $("[data-rfname='SKU']").removeAttr("invalid-entity");

  var scannedentity     = $("[data-rfname='SKU']").val();
  var numskusinlocation = $("[data-rfname='m_LocationInfo_NumSKUs']").val();
  var storagetype       = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var locsubtype        = $("[data-rfname='m_LocationInfo_LocationSubType']").val();
  var locskusjson       = {};
  var flagskuinlocation = 0; // boolean value: true if sku exists in location prior to CC, false if not
  var flagskuscanned    = 0; // boolean value: true if scanned, false if not scanned
  var inventoryuom;
  var addnewsku; // This is a control var, based on this we allow adding new SKU

  // If user did not scan or enter anything then do nothing
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
    return;
  }

  // Hide all the inputs
  QuantityInputPanel_HideInputs('N');

  // For dynamic Picklane we will have empty locations, so to avoid json.parse errors for
  // empty values, skipping the below steps.
  if (numskusinlocation > 0)
  {
    locskusjson = JSON.parse($("[data-rfname='m_LOCSKUs']").val());

    // The LOCSKUs data set will be considered as array if it has multiple SKUs, else
    //  will be considered as a single object. As the below filter is expecting an array,
    //  coverting this into array, only when we get single SKU. Any changes to the
    //  data set node name, needs changes here as well
    if ($(locskusjson["LOCSKUs"]["LOCSKU"]).length == 1)
    {
      var locskusarr = [];
      locskusarr.push(locskusjson.LOCSKUs.LOCSKU);
      locskusjson.LOCSKUs.LOCSKU = locskusarr;
    }

    // Set the flag if the sku exists in the location already
    flagskuinlocation = Boolean(locskusjson["LOCSKUs"]["LOCSKU"].filter(CC_JsonArrayFilter("SKU"), scannedentity).length > 0);
  }

  // Set the flag to true if the sku was already scanned earlier
  flagskuscanned = CC_CheckTableEntry('.js-datatable-cyclecount-confirmskus', scannedentity);

  // If SKU is already associated with the Location, proceed further. else raise an error
  if ((flagskuinlocation) || (flagskuscanned))
  {
    // Clear the inputs and show the inputs
    QuantityInputPanel_ClearForm();

    // Initialize values for fields in the quantity input panel
    QuantityInputPanel_InitializeForSKU(inventoryuom, "", storagetype, 1, 1, null);
  }
  else
  if ((!flagskuinlocation) && (locsubtype == 'D'))
  {
  // An unknown SKU was scanned, validate it
  $("[data-rfname='RFFormAction']").val("CCLocationUnknownSKU");
    CC_UnknownEntity_Validate();
  }
  else
  if ((!flagskuinlocation) && (locsubtype == 'S'))
  {
    // Currently validating if SKU is not associated with the location
    DisplayErrorMessage("SKU is invalid or Location is not setup for this SKU and cannot be added");
    $("[data-rfname='SKU']").val("");
    $("[data-rfname='SKU']").focus();

    // We need to add attribute to prevent validating again in Tabulate_SKU. Without this, if
    // if user keyed in a invalid SKU and clicked on confirm SKU we would validate it again in Tabulate SKU
    var selector = "[data-rfname='SKU']";
    var values   = {"invalid-entity":"Y"};
    QuantityInputPanel_AddAttributes(selector,values)
  }

  // do not process any further
  evt.stopPropagation();
  evt.preventDefault();
  return;
} // CC_Picklane_OnSKUEnter

//-----------------------------------------------------------------------------
// confirm the picklane cycle count. if user tries to confirm CC without scanning
// any SKUs, then confirm if the Location is empty
function CC_Picklane_ConfirmCount(evt)
{
  // Get the table rows
  var tablerows = $('.js-datatable-cyclecount-confirmskus').find("tbody tr");

  // If table has scanned entities, then proceed with CC Complete
  if ((tablerows.length > 0))
  {
    $("[data-rfname='RFFormAction']").val("CompleteCC");
    SkipInputValidationsAndSubmit();
  }
  else
  // if user has not scanned any SKUs and confirms the CC, then verify once again
  // if the location is empty, if not, let user continue
  if ((tablerows.length <= 0))
  {
    ConfirmYesNo("Is the Location Empty?",
      function ()
      {
        SkipInputValidationsAndSubmit();
      },
      function ()
      {
        // do nothing, when the user clicks no
      });
  }
} // CC_Picklane_ConfirmCount

//-----------------------------------------------------------------------------
// Custom handler to tabulate SKUs scanned. When user scans the SKUs and confirms
// the quantity of that SKU, need to add to the datatable. If the SKU was already
// scanned earlier then we add the scanned qty to the prior quantity
// Currently we are not allowing scanning of SKUs that are not already setup in
// the Location - so that scenario is not handleds
function CC_Picklane_TabulateSKU(evt)
{
  // If the SKU has already been valdiated adn determined that it is invalid
  // then we just need to return withot doing anything
  var invalidentity = $("[data-rfname='SKU']").attr("invalid-entity");

  // If we have value for the above attribute we will not proceed further
  if (invalidentity == 'Y')
    return;

  // get the user scanned/entered values
  var scannedsku     = $("[data-rfname='SKU']").val();
  var scannedskuqty  = $("[data-rfname='NewUnits1']").val();
  var ccdata         = $("[data-rfname='m_CCData']").val();
  // initialize the values that would not be input by user - will be set from JSON object later
  var scannedskudesc = "";
  var scannedskuip   = 0;
  var scannedskuuom  = "";

  // Return warning if no SKU is scanned
  if ((scannedsku == null) || (scannedsku == undefined) || (scannedsku == ""))
  {
    DisplayErrorMessage("Please scan a SKU to proceed further");
    $("[data-rfname='SKU']").focus();
    return;
  }

  // Validate the Unit entered, if not valid, then return
  if (!QuantityInputPanel_ValidateInput("#Units1", scannedskuqty))
  {
    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  var flagskuscanned      = 0; // boolean value: true if scanned, false if not scanned
  var flagskuinlocation   = 0; // boolean value: true if exists, false if not exists
  var numskusinlocation   = $("[data-rfname='m_LocationInfo_NumSKUs']").val();
  // Json object
  var inputdata           = {};

  // Check if hte scanned SKU exists in the Location already or not. For dynamic Picklane we
  // may have empty locations i.e there aren't any existing SKUs in the location so to avoid
  // json.parse erros - skipping the below steps.
  if (numskusinlocation > 0)
  {
    var locskusjson         = JSON.parse($("[data-rfname='m_LOCSKUs']").val());

    // The LOCSKUs data set will be considered as array if it has multiple SKUs, else
    //  will be considered as a single object. As the below filter is expecting an array,
    //  coverting this into array, only when we get single SKU. Any changes to the
    //  data set node name, needs changes here as well
    if ($(locskusjson["LOCSKUs"]["LOCSKU"]).length == 1)
    {
      var locskusarr = [];
      locskusarr.push(locskusjson.LOCSKUs.LOCSKU);
      locskusjson.LOCSKUs.LOCSKU = locskusarr;
    }

    // Set the flag if the sku exists in the location at all
    flagskuinlocation = Boolean(locskusjson["LOCSKUs"]["LOCSKU"].filter(CC_JsonArrayFilter("SKU"), scannedsku).length > 0);
  }

  // Set the flag to true if the sku was already scanned earlier
  flagskuscanned    = CC_CheckTableEntry('.js-datatable-cyclecount-confirmskus', scannedsku);

  // When the SKU already is in the Location, then get those details
  // and add to the data table. If the SKU was already scanned, then we
  // add scanned qty to the prior quantity
  if (flagskuinlocation)
  {
    scannedsku     = locskusjson["LOCSKUs"]["LOCSKU"].filter(CC_JsonArrayFilter("SKU"), scannedsku)[0]["SKU"];
    scannedskudesc = locskusjson["LOCSKUs"]["LOCSKU"].filter(CC_JsonArrayFilter("SKU"), scannedsku)[0]["SKUDescription"];
    scannedskuip   = "0";
  }
  else
  // if (flagskuscanned)
  {
    var ccdatajson        = {};
    ccdatajson = JSON.parse(ccdata);

    // If the object has only 1 array, convert that into json object array
    // Reason: the CC_JsonArrayFilter would need json object array within json object
    if ($(ccdatajson["CCData"]["CCTable"]).length == 1)
    {
      var ccdatalistarray = [];
      ccdatalistarray.push(ccdatajson.CCData.CCTable);
      ccdatajson.CCData.CCTable = ccdatalistarray;
    }

    // fetch the values
    scannedsku     = ccdatajson["CCData"]["CCTable"].filter(CC_JsonArrayFilter("SKU"), scannedsku)[0]["SKU"];
    scannedskudesc = ccdatajson["CCData"]["CCTable"].filter(CC_JsonArrayFilter("SKU"), scannedsku)[0]["SKUDesc"];
    scannedskuip   = "0";

  }

  // if the sku was already scanned then add the newly entered values to the
  // existing line else consider it as new scan
  if (flagskuscanned)
  {
    inputdata["UpdateType"] = FORMCONTENT_UPDATETYPE_ADDUPDATE;

    // Update SKUUoM as EA
    scannedskuuom = 'EA';

    // fetch the row and col indexes to fetch the values and make necessary updates
    var skurowindex   = CC_GetTableRowIndex($("[data-rfrecordname='CCTable']"), scannedsku);
    var newunitsindex = $("[data-rffieldname='NewUnits']").index();

    var skucurrqty    = $($($("[data-rfrecordname='CCTable']").find('tr')[skurowindex + 1]).find('td')[newunitsindex]).text();
    var newqty        = (parseInt(skucurrqty) + parseInt(scannedskuqty));
  }
  else // New scan: Adds a new row in the data table
  {
    inputdata["UpdateType"] = FORMCONTENT_UPDATETYPE_ADD;
    inputdata["UpdateMode"] = FORMCONTENT_UPDATEMODE_BEFORE;
    // there is no new qty in this case and scanned quantity is used below
  }

  // else part not handled now i.e. if user scans a SKU that is not in the location

  // Process
  // Add the values to the table
  inputdata["EntityName"]   = "SKU";
  inputdata["ControlValue"] = [
                                {"SKU":scannedsku,
                                 "SKUDescription":scannedskudesc,
                                 "NewUnits":newqty ?? scannedskuqty}
                              ];

  // Tabulate SKU that is scanned
  ChangeFormContent('.js-datatable-cyclecount-confirmskus', inputdata);

  // If the sku scanned is not associated with loc, make DB call to validate from back end and send the new result
  //if (!flagskuinlocation)
  //{
    // We need to populate the incorrect data on the table
    // Since xml data gets populated before DB call to validate
  //  CC_UnknownEntity_Validate();
  //}

  // Update Footer
  // Given values are the column index, & name to sum. Also respective footer attribute to update
  var coldetailstosum = {"COLS": [{"COLIDX":0, "FOOTERNAME":"NumSKUs", "TYPE":"COUNT", "ATTRIBUTE":".js-footer-cyclecount-NumSKUs"},
                                  {"COLIDX":2, "FOOTERNAME":"NumUnits", "TYPE":"SUM", "ATTRIBUTE":".js-footer-cyclecount-NumUnits"}]}
  CC_UpdateTableFooter('.js-datatable-cyclecount-confirmskus', inputdata, coldetailstosum);

  // Clear the QIP and hide the panel
  QuantityInputPanel_ClearForm();
  QuantityInputPanel_HideInputs();

  // Reset the SKU and get ready for the next SKU
  $("[data-rfname='SKU']").val("");
  $("[data-rfname='SKU']").focus();
} // CC_Picklane_TabulateSKU

//-----------------------------------------------------------------------------
function CC_ReserveLoc_CreateInvLPN(evt)
{
  // do the part which needs to invoke the Create InvLPN to a new window

  // save current work flow details and set work flow information for the new one
  var currentform = $("#CurrentFormName").val();
  var currentworkflowname = $("#CurrentWorkFlowName").val();
  var currentformsequence = $("#CurrentFormSequence").val();
  var currentparentmenu = $("#CurrentParentMenu").val();

  // update the work flow information for the new one to the form vars
  $("#CurrentFormName").val("Inventory_CreateInvLPN");
  $("#CurrentWorkFlowName").val("Inventory_CreateInvLPN");
  $("#CurrentFormSequence").val("1");
  $("#CurrentParentMenu").val("rfinventorymanagement");

  // process the input passed to this method
  var inputdata = {};
  inputdata["WorkFlowSkipped"] = "Y ";
  //inputdata["InventoryClass1"] = invclass1;
  var currentActionInput = {};
  currentActionInput.Data = inputdata;
  // set form target to a new window
  var newwindowname = "CreateInvLPN";
  var newwindow = window.open("", newwindowname); // creates a new tab with blank page
  $("form").attr("target", newwindowname);

  // prevent the input validation
  $("#RFSkipInputValidation").val(true);
  // prevent the input data collection, and assign the input value
  $("#RFSkipInputCollection").val(true);

  // save input value list into hidden input controls
  $("#RFFormInputData").val(JSON.stringify(currentActionInput));

  // submit form to deliver the user input, and perform action
  $("form").submit();
  // reset form target back to earlier, from new window
  $("form").removeAttr("target"); // clear target attribute, for further calls

  // restore current work flow information from which this method is
  // invoked
  $("#CurrentFormName").val(currentform);
  $("#CurrentWorkFlowName").val(currentworkflowname);
  $("#CurrentFormSequence").val(currentformsequence);
  $("#CurrentParentMenu").val(currentparentmenu);

  // reset the flags for input collection and validation
  ResetInputCollectionFlag();
  ResetInputValidationFlag();

  // hide busy indicator
  $(".amf-application-busy").addClass('hidden');
  document.body.style.cursor = "default"; // sets the cursor to default icon
} // CC_ReserveLoc_CreateInvLPN

//-----------------------------------------------------------------------------
// Custon handler to show QIP panel of the LPN clicked from the Tabular panel
// By default we try to fetch the QIP values that was scanned already
function CC_ConfirmResvLocLPN_AlreadyScanned(pallet, lpn)
{
  // data model inputs given from DB
  var storagetype       = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var resultarray       = CC_GetLocationLPNs(lpn);
  var clickedlpndetails = resultarray[2];
  var selecteduom       = CC_ConfirmResvLocLPN_GetLPNUoM(lpn);
  var inventoryuom      = "";
  // can extract only if LPN exists on location
  if (clickedlpndetails.length > 0)
  {
    inventoryuom = clickedlpndetails[0]["UoM"];
  }
  // fetch LPN quantities
  var [unitsperip, lpninnerpacks, lpnunits] = CC_ConfirmResvLocLPN_GetLPNQuantities(lpn);

  // Setup form input values
  if ((pallet != undefined) && (pallet != ""))
  {
    $("[data-rfname='Pallet']").val(pallet);
  }

  $("[data-rfname='LPN']").val(lpn);

  // Setup QIP panel
  QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperip, lpninnerpacks, lpnunits);
} // CC_ConfirmResvLocLPN_AlreadyScanned

//-----------------------------------------------------------------------------
// During Cycle count, user has the option to select (click) LPN and
// change the quantity of the LPN. This function is invoked when user selects
// an LPN from the list of scanned LPNs and sets up the QIP for user to edit
// the Cases or Quantity in the LPN based upon the UoM
function CC_ConfirmResvLocLPN_OnLPNClick(entityvalue)
{
  // return if the entity passed is not valid
  if ((entityvalue == undefined) || (entityvalue == ""))
    return;

  // method to setup entity and QIP values
  CC_ConfirmResvLocLPN_AlreadyScanned("", entityvalue);
} // CC_ConfirmResvLocLPN_OnLPNClick

// Function that evaluates scanned LPN and returns its sku details
// If LPN was scanned once, fetch the values from the table panel
// If LPN is on location, then the data is fetched from the data set of the location
// If LPN was not on location, then the data is fetched from the data table set returned after validation
function CC_ConfirmResvLocLPN_GetLPNSKUInfo(lpn)
{
  // data set from location
  var resultarray       = CC_GetLocationLPNs(lpn);
  var loclpnsjson       = resultarray[0];
  var flaglpninlocation = resultarray[1];
  var scannedlpndetails = resultarray[2];
  // data set from data table
  var ccdata            = $("[data-rfname='m_CCData']").val();
  var ccdatajson        = {};
  // Validate if LPN was already scanned or not
  var flaglpnscanned    = CC_CheckTableEntry('.js-datatable-cyclecount-confirmlpns', lpn);
  // outputs
  var sku               = "";
  var skudesc           = "";
  var displaysku        = "";

  // if lpn is already scanned
  if (flaglpnscanned)
  {
    var rindex         = CC_GetTableRowIndex($("[data-rfrecordname='CCTable']"), lpn);
    var skuidx         = $("[data-rffieldname='SKU']").index();
    var skudescidx     = $("[data-rffieldname='SKUDesc']").index();

    sku                = $($($("[data-rfrecordname='CCTable']").find('tr')[rindex + 1]).find('td')[skuidx]).text();
    skudesc            = $($($("[data-rfrecordname='CCTable']").find('tr')[rindex + 1]).find('td')[skudescidx]).text();
  }
  // if lpn exists on location and is not tabulated yet
  else
  if (flaglpninlocation)
  {
    sku         = scannedlpndetails[0]["SKU"];
    skudesc     = scannedlpndetails[0]["SKUDesc"];
    displaysku  = scannedlpndetails[0]["DisplaySKU"];
  }
  // if lpn does not exist on location and is not tabulated
  // assumption: lpn has been validated and so the return data table data set should have this info
  else
  {
    if ((ccdata != undefined) && (ccdata != ""))
    {
      ccdatajson = JSON.parse(ccdata);

      // If the object has only 1 array, convert that into json object array
      // Reason: the CC_JsonArrayFilter would need json object array within json object
      if ($(ccdatajson["CCData"]["CCTable"]).length == 1)
      {
        var ccdatalistarray = [];
        ccdatalistarray.push(ccdatajson.CCData.CCTable);
        ccdatajson.CCData.CCTable = ccdatalistarray;
      }

      // fetch the values
      sku     = ccdatajson["CCData"]["CCTable"].filter(CC_JsonArrayFilter("LPN"), lpn)[0]["SKU"];
      skudesc = ccdatajson["CCData"]["CCTable"].filter(CC_JsonArrayFilter("LPN"), lpn)[0]["SKUDesc"];
    }
  }

  return [sku, skudesc, displaysku];
} // CC_ConfirmResvLocLPN_GetLPNSKUInfo

// Function that retrusn the lpn's UoM based on the logic
// This is selectedUoM different than the SKU/Inventory UoM
// This value is used to evaluate QIP form inputs
function CC_ConfirmResvLocLPN_GetLPNUoM(lpn)
{
  var resultarray       = CC_GetLocationLPNs(lpn);
  var flaglpninlocation = resultarray[1];
  var scannedlpndetails = resultarray[2];
  var innerpacks        = "";
  var lpnuom            = "";

  // LPN can or cannot be on location
  // the following data value exists only for lpn that exists on location
  if (scannedlpndetails.length > 0)
  {
    innerpacks = scannedlpndetails[0]["InnerPacks"];
  }

  // evaluate LPN UoM
  if ((innerpacks == 0) || (innerpacks == undefined) || (innerpacks == ""))
  {
    lpnuom = "EA";
  }
  else
  {
    lpnuom = "CS";
  }

  return lpnuom;
} // CC_ConfirmResvLocLPN_GetLPNUoM

// Function to decide and fetch LPN quantities
// If the LPN is already scanned, and QIP values are empty then return the data table values
// If the LPN is already scanned, and QIP values exist then return QIP values
// If the LPN is scanned for the first time, return data model values taken from DB
function CC_ConfirmResvLocLPN_GetLPNQuantities(lpn)
{
  // additional data model
  var inputqtyprompt    = $("[data-rfname='m_InputQtyPrompt']").val();
  var defaultqty        = $("[data-rfname='m_DefaultQuantity']").val();
  // lpn details
  var resultarray       = CC_GetLocationLPNs(lpn);
  var flaglpninlocation = resultarray[1];
  var loclpndetails     = resultarray[2];
  var inventoryuom      = "EA"; // default
  // If LPN exists on location, fetch the UoM value from data model returned from DB
  if (loclpndetails.length > 0)
  {
    inventoryuom        = loclpndetails[0]["UoM"];
  }
  var flaglpnscanned    = CC_CheckTableEntry('.js-datatable-cyclecount-confirmlpns', lpn);
  // fetch QIP values
  var newinnerpacks     = $("[data-rfname='NewInnerPacks']").val();
  var newunits          = $("[data-rfname='NewUnits']").val();
  var newunitsperip1    = $("[data-rfname='NewUnitsPerInnerPack1']").val();
  var newunits1         = $("[data-rfname='NewUnits1']").val();
  // output variables
  var unitsperip        = 1; //default
  var innerpacks        = ""; //default
  var units             = ""; //default

  // LPN is already scanned
  if (flaglpnscanned)
  {
    // eiher innerpack panel or eaches panel is updated with user values
    if (((newunits != undefined) && (newunits != "")) || ((newunits1 != undefined) && (newunits1 != "")))
    {
      if (inventoryuom == "CS")
      {
        innerpacks = newinnerpacks;
        units      = newunits;

        if (innerpacks > 0)
        {
          unitsperip = (units / innerpacks);
        }
      }
      else // EA
      {
        unitsperip = newunitsperip1;
        units      = newunits1;

        if (unitsperip > 1)
        {
          innerpacks = (units / unitsperip);
        }
        else
        {
          innerpacks = "0";
        }
      }
    }
    // QIP panel is blank, fetch data table values
    else
    {
      var rindex         = CC_GetTableRowIndex($("[data-rfrecordname='CCTable']"), lpn);
      var newipindex     = $("[data-rffieldname='NewInnerPacks']").index();
      var newunitsindex  = $("[data-rffieldname='NewUnits']").index();
      innerpacks         = $($($("[data-rfrecordname='CCTable']").find('tr')[rindex + 1]).find('td')[newipindex]).text();
      units              = $($($("[data-rfrecordname='CCTable']").find('tr')[rindex + 1]).find('td')[newunitsindex]).text();

      if (innerpacks > 0)
      {
        unitsperip = (units / innerpacks);
      }
    }
  }
  // LPN is scanned for the first time
  else
  {
    // eiher innerpack panel or eaches panel is updated with user values
    if (((newunits != undefined) && (newunits != "")) || ((newunits1 != undefined) && (newunits1 != "")))
    {
      if (inventoryuom == "CS")
      {
        innerpacks = newinnerpacks;
        units      = newunits;

        if (innerpacks > 0)
        {
          unitsperip = (units / innerpacks);
        }
      }
      else // EA
      {
        unitsperip = newunitsperip1;
        units      = newunits1;

        if (unitsperip > 1)
        {
          innerpacks = (units / unitsperip);
        }
        else
        {
          innerpacks = "0";
        }
      }
    }
    else
    // Force user to confirm and blind CC - where quantity fields are left empty for user to input and confirm
    if ((defaultqty != "LPN") && (inputqtyprompt == "Y" /* yes */) &&
       (((newunits == undefined) || (newunits == "")) && ((newunits1 == undefined) || (newunits1 == ""))))
    {
      innerpacks = "0";
      units      = "";
    }
    else
    // default CC - use LPN existing values
    if (flaglpninlocation)
    {
      unitsperip = loclpndetails[0]["UnitsPerInnerPack"];
      innerpacks = loclpndetails[0]["InnerPacks"];
      units      = loclpndetails[0]["Quantity"];
    }
    // New LPN scanned on the location. No details
    // Future: These LPN details would be sent too
    else
    {
      innerpacks = "0";
      units      = "";
    }
  }

  // Default value for units per innerpack should be 1
  if (unitsperip == 0)
    unitsperip = 1;

  return [unitsperip, innerpacks, units];
} // CC_ConfirmResvLocLPN_GetLPNQuantities

//-----------------------------------------------------------------------------
// This function gets called for form rendering for LPN & Pallet CC alike
// Custom handler that gets called before the form for Reserve Location LPN CC
// is shown. This is to basically populate the data to be shown on the Data Table
function CC_ConfirmResvLocLPN_OnShow()
{
  // Initialize variables
  var tableelement    = ".js-datatable-cyclecount-confirmlpns";
  var ccdata          = $("[data-rfname='m_CCData']").val();
  var ccdatalist      = {};
  var ccdatalistlen   = 0;
  var inputdata       = {};
  var values          = {};
  var lastpalletvalue = $("[data-rfname='m_Pallet']").val();
  var lastlpnscanned  = $("[data-rfname='m_LPN']").val();
  var inputqtyprompt  = $("[data-rfname='m_InputQtyPrompt']").val();
  var currentlpn      = "";
  var promptforlpn    = "";
  var selector        = "";

  // Continue to tabulate these LPNs only if the above nodal data exists
  if ((ccdata != undefined) && (ccdata != ""))
  {
    ccdatalist    = JSON.parse($("[data-rfname='m_CCData']").val());
    ccdatalistlen = $(ccdatalist["CCData"]["CCTable"]).length;

    // If the object has only 1 array, convert that into json object array
    // Reason: the CC_JsonArrayFilter would need json object array within json object
    if (ccdatalistlen == 1)
    {
      var ccdatalistarray = [];
      ccdatalistarray.push(ccdatalist.CCData.CCTable);
      ccdatalist.CCData.CCTable = ccdatalistarray;
    }

    // loop through the LPN list
    for (outlp = 0; outlp < ccdatalistlen; outlp++)
    {
      currentlpn = ccdatalist["CCData"]["CCTable"][outlp]["LPN"];

      // For cases where user needs to confirm the quantity we will not tabulate just as yet
      // In this case, the last LPN scanned was unknown and hence after validating it
      // we initiate the QIP panel for user to confirm the quantity
      if ((inputqtyprompt == "Y") && (currentlpn == lastlpnscanned))
      {
        promptforlpn = currentlpn;
      }
      else
      {
        CC_ConfirmResvLocLPN_TableInsertUpdate(ccdatalist["CCData"]["CCTable"][outlp]["Pallet"],
                                               currentlpn,
                                               ccdatalist["CCData"]["CCTable"][outlp]["SKU"],
                                               ccdatalist["CCData"]["CCTable"][outlp]["SKUDesc"],
                                               ccdatalist["CCData"]["CCTable"][outlp]["NewInnerPacks"],
                                               ccdatalist["CCData"]["CCTable"][outlp]["NewUnits"],
                                               FORMCONTENT_UPDATETYPE_ADDUPDATE,
                                               FORMCONTENT_UPDATEMODE_BEFORE)
      }
    } // end of for loop

    // Setup QIP for the unknown lpn scanned
    // Focus will be set on QIP automatically
    if (promptforlpn != "")
    {
      $("[data-rfname='LPN']").val(promptforlpn);
      CC_ConfirmResvLocLPN_PromptQuantity(promptforlpn);
    }
    // Set focus on LPN if QIP is not going to be set
    else
    {
      $("[data-rfname='LPN']").focus();
    }
  } // end of if block
  else
  {
    $("[data-rfname='LPN']").focus();
  }

  // We need additional attributes for standard QIP panel, called the function to add them
  selector = "[data-rfname='NewUnits1']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfvalidationhandler":"CC_ConfirmResvLocLPN_Tabulate","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector, values);

  selector = "[data-rfname='NewInnerPacks']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfvalidationhandler":"CC_ConfirmResvLocLPN_Tabulate","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector, values);

  // Generally validation handler settings are defined after form is rendered. In
  // this case as we added validation handler in form show, call the function to
  // define the settings
  VerifyFormForValidationSettings();

  SetFocusFlagValue(true);
} // CC_ConfirmResvLocLPN_OnShow

//-----------------------------------------------------------------------------
// Custom handler to setup the QIP and SKU panel once the LPN Is scanned
// This is to force user to confirm the quantity of the LPN scanned
function CC_ConfirmResvLocLPN_PromptQuantity(pallet, lpn)
{
  // data model inputs given from DB
  var storagetype       = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var resultarray       = CC_GetLocationLPNs(lpn);
  var flaglpninlocation = resultarray[1];
  var scannedlpndetails = resultarray[2];
  // other inventory attributes
  var selecteduom       = CC_ConfirmResvLocLPN_GetLPNUoM(lpn);
  var inventoryuom      = "";
  // can extract only if LPN exists on location
  if (scannedlpndetails.length > 0)
  {
    inventoryuom = scannedlpndetails[0]["UoM"];
  }
  // fetch LPN quantities
  var [unitsperip, lpninnerpacks, lpnunits] = CC_ConfirmResvLocLPN_GetLPNQuantities(lpn);

  // PROCESS
  // -----------------------------------------------------------------
  // Setup QIP
  QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperip, lpninnerpacks, lpnunits);
  // Setup SIP
  CC_ConfirmResvLocLPN_UpdateSKUPanel(lpn);
} // CC_ConfirmResvLocLPN_PromptQuantity

//-----------------------------------------------------------------------------
// Custom handler to change input controls from eaches to cases
function CC_ConfirmResvLocLPN_SelectCases_OnChange()
{
  // fetch the required values
  var selecteduom           = 'CS';
  var lpn                   = $("[data-rfname='LPN']").val();
  var storagetype           = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var resultarray           = CC_GetLocationLPNs(lpn);
  var lpndetails            = resultarray[2];
  var inventoryuom          = "";
  var lpninnerpacks         = 0;
  var lpnunits              = 0;
  var lpnunitsperinnerpack  = 0; //default
  var rindex                = CC_GetTableRowIndex($("[data-rfrecordname='CCTable']"), lpn);
  var newipindex            = $("[data-rffieldname='NewInnerPacks']").index();
  var newunitsindex         = $("[data-rffieldname='NewUnits']").index();

  // get values from data data table if lpn is already scanned
  if ((rindex != -1) && (rindex != undefined) && (newipindex != -1) && (newipindex != undefined) && (newunitsindex != -1) && (newunitsindex != undefined))
  {
    lpninnerpacks = $($($("[data-rfrecordname='CCTable']").find('tr')[rindex + 1]).find('td')[newipindex]).text();
    lpnunits      = $($($("[data-rfrecordname='CCTable']").find('tr')[rindex + 1]).find('td')[newunitsindex]).text();

    // calculate the values from the table since user may have changed it during the scan
    if (lpninnerpacks > 0)
    {
      lpnunitsperinnerpack = (lpnunits / lpninnerpacks);
    }
  }
  // fetch the values of the given LPN
  else
  if ($(lpndetails).length > 0)
  {
    inventoryuom         = lpndetails[0]["UoM"];
    lpninnerpacks        = lpndetails[0]["InnerPacks"];
    lpnunits             = lpndetails[0]["Quantity"];
    lpnunitsperinnerpack = lpndetails[0]["UnitsPerInnerPack"];
  }

  // default unitsperinnerpack value in case of a bad value
  if ((lpnunitsperinnerpack == undefined) || (lpnunitsperinnerpack == 0))
  {
    lpnunitsperinnerpack = 0; //default
  }

  QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, lpninnerpacks, lpnunitsperinnerpack);
} // CC_ConfirmResvLocLPN_SelectCases_OnChange

//-----------------------------------------------------------------------------
// Custom handler to change input controls from cases to eaches
function CC_ConfirmResvLocLPN_SelectEaches_OnChange()
{
  // fetch the required values
  var selecteduom           = 'EA';
  var lpn                   = $("[data-rfname='LPN']").val();
  var storagetype           = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var resultarray           = CC_GetLocationLPNs(lpn);
  var lpndetails            = resultarray[2];
  var inventoryuom          = "";
  var lpninnerpacks         = 0;
  var lpnunits              = 0;
  var lpnunitsperinnerpack  = 0; //default
  var rindex                = CC_GetTableRowIndex($("[data-rfrecordname='CCTable']"), lpn);
  var newipindex            = $("[data-rffieldname='NewInnerPacks']").index();
  var newunitsindex         = $("[data-rffieldname='NewUnits']").index();

  // get values from data data table if lpn is already scanned
  if ((rindex != -1) && (rindex != undefined) && (newipindex != -1) && (newipindex != undefined) && (newunitsindex != -1) && (newunitsindex != undefined))
  {
    lpninnerpacks = $($($("[data-rfrecordname='CCTable']").find('tr')[rindex + 1]).find('td')[newipindex]).text();
    lpnunits      = $($($("[data-rfrecordname='CCTable']").find('tr')[rindex + 1]).find('td')[newunitsindex]).text();

    // calculate the values from the table since user may have changed it during the scan
    if (lpninnerpacks > 0)
    {
      lpnunitsperinnerpack = (lpnunits / lpninnerpacks);
    }
  }
  // fetch the values of the given LPN
  else
  if ($(lpndetails).length > 0)
  {
    inventoryuom         = lpndetails[0]["UoM"];
    lpninnerpacks        = lpndetails[0]["InnerPacks"];
    lpnunits             = lpndetails[0]["Quantity"];
    lpnunitsperinnerpack = lpndetails[0]["UnitsPerInnerPack"];
  }

  // default unitsperinnerpack value in case of a bad value
  if ((lpnunitsperinnerpack == undefined) || (lpnunitsperinnerpack == 0))
  {
    lpnunitsperinnerpack = 0; //default
  }

  QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, lpnunitsperinnerpack, lpnunits);
} // CC_ConfirmResvLocLPN_SelectEaches_OnChange

//-----------------------------------------------------------------------------
// Custom handler to submit form for Reserve Location LPN Count
function CC_ConfirmResvLocLPN_Submit(evt)
{
  // variables
  var tablerowcount = 0;
  var completecc    = 1; // default

  // get the number of scans done for this location
  tablerowcount = $(".js-datatable-cyclecount-confirmlpns").find("tbody tr").length;

  // there are no LPNs scanned, please get users confirmation on counting Location as empty
  if (tablerowcount == 0)
  {
    ConfirmYesNo("No LPNs scanned! Is Location Empty?",
        function ()
        {
          // complete cc, when the user clicks yes
          CC_Submit_Request(evt);
        },
        function ()
        {
          // return back with message, when the user clicks no
          // location is not empty and so force user to scan LPNs and then proceed to complete cc
          DisplayWarningMessage("Please scan LPNs to proceed");
          $("[data-rfname='LPN']").focus();
          return;
        });
  }
  // proceed to complete counting
  else
  {
    CC_Submit_Request(evt);
  }
} // CC_ConfirmResvLocLPN_Submit

//-----------------------------------------------------------------------------
// Custom handler to tabulate LPNs scanned
// This method gets called when LPN is confirmed
//  i.e., after clicking on ConfirmLPN button or press enter after each LPN scan
// This is the common method across LPN and Pallet CC screens
function CC_ConfirmResvLocLPN_Tabulate(evt)
{
  // event values
  var userevent          = $(evt.relatedTarget).text();
  // form inputs
  var scannedpallet      = $("[data-rfname='Pallet']").val().trim();
  var scannedlpn         = $("[data-rfname='LPN']").val().trim();
  // form element identifier
  var tableelement       = ".js-datatable-cyclecount-confirmlpns";
  // data model inputs given from DB
  var locstoragetype     = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var inputqtyprompt     = $("[data-rfname='m_InputQtyPrompt']").val();
  // flags
  var flagpallet         = false;   // boolean value: true if scanned, false if not scanned
  var flaglpnscanned     = false;   // boolean value: true if scanned, false if not scanned
  var flaglpninlocation  = false;   // boolean value: true if exists, false if not exists
  var flagqipvalues      = false;   // boolean value: true if given, false if not given
  var resetform          = true;    // boolean value: true to reset form, false to exist the form
  var context            = "";      // value that would choose the workflow
  // array input or outputs
  var resultarray        = [];
  var scannedlpndetails  = [];
  // Json objects
  var loclpnsjson        = {};
  var inputdata          = {};
  var coldetailstosum    = {};
  // inputs
  var qipunits           = 0;
  var qipunits1          = 0;
  var newinnerpacks      = 0;
  var newquantity        = 0;
  var newunitsperip      = 0;
  var sku                = "";
  var skudesc            = "";
  var displaysku         = "";

  // Validate LPN Scan
  // Return if no LPN is scanned
  // userevent is null when focus out and not null when confirm LPN is clicked
  if (( userevent == "Confirm LPN") && ((scannedlpn == undefined) || (scannedlpn == "")))
  {
    DisplayWarningMessage("No LPN scanned to confirm");
    $("[data-rfname='LPN']").focus();
    return;
  }
  else
  if ((scannedlpn == undefined) || (scannedlpn == ""))
  {
    return;
  } // end

  // Validate Pallet Scan
  // Set flag to determine whether this is LPN or Pallet Cycle counting
  // Pallet would be scanned only for Pallet cycle counting or pallet type storage location
  if (((scannedpallet != undefined) && (scannedpallet != "")) ||
      (((locstoragetype == 'LA' /* LPNs & Pallets */) || (locstoragetype == 'A' /* Pallets */)) &&
      (scannedpallet == "") && (scannedlpn != "")))
    flagpallet = 1;

  // Validate if LPN was already scanned or not
  flaglpnscanned = CC_CheckTableEntry('.js-datatable-cyclecount-confirmlpns', scannedlpn);

  // Fetch json object array of scanned LPN on the location
  // Flag whether lpn exists on location, & details on scanned lpn
  resultarray       = CC_GetLocationLPNs(scannedlpn);
  loclpnsjson       = resultarray[0];
  flaglpninlocation = resultarray[1];
  scannedlpndetails = resultarray[2];

  // Fetch QIP values
  // Note QIP is always hidden and so either these values exist or they do not
  // These values drive a particular screen workflow as seen later
  var qipunits  = $("[data-rfname='NewUnits']").val();  // for UoM in cases
  var qipunits1 = $("[data-rfname='NewUnits1']").val(); // for UoM in eaches
  // Evaluate the flag if any of the QIP values exist on the form
  if (((qipunits != undefined) && (qipunits != "")) || ((qipunits1 != undefined) && (qipunits1 != "")))
  {
    flagqipvalues = true;
  }

  // CONTEXT evaluation
  // This would select the course of action on the rf screen
  // -------------------------------------------------------------------------
  // If the LPN is not on location and needs to be validated first
  if ((!flagqipvalues) && (!flaglpninlocation) && (!flaglpnscanned))
  {
    context = "unknown";
  }
  // If LPN is already scanned and need to setup QIP panel
  else
  if ((!flagqipvalues) && (flaglpnscanned))
  {
    context = "alreadyscanned";
  }
  // If LPN scanned needs QIP panel to be setup to force to confirm quantity either default or blind
  // Also need to setup QIP and SIP panel
  else
  if ((!flagqipvalues) && (flaglpninlocation) && (inputqtyprompt == "Y"))
  {
    context = "prompt"
  }
  // Insert or update the data table as the user has confirmed the LPN
  else
  {
    context = "tabulate";
  } // END CONTEXT

  // PROCESS
  // -------------------------------------------------------------------------
  // Place DB call to validate the unknown LPN scanned for the location
  if (context == "unknown")
  {
    $("[data-rfname='RFFormAction']").val("CCLocationUnknownLPN");
    // submit the form that would make DB call to validation unknown entity
    CC_UnknownEntity_Validate();
  }
  // This is when user has clicked on the data table to edit LPN quantity
  else
  if (context == "alreadyscanned")
  {
    CC_ConfirmResvLocLPN_AlreadyScanned(scannedpallet, scannedlpn);
  }
  else
  if (context == "prompt")
  {
    CC_ConfirmResvLocLPN_PromptQuantity(scannedpallet, scannedlpn);
    resetform = false;
  }
  // Insert or update the data table panel
  // context == "tabulate"
  else
  {
    // This function assesses the quantities of the LPN scanned to be inserted or updated to the data table
    [newunitsperip, newinnerpacks, newunits] = CC_ConfirmResvLocLPN_GetLPNQuantities(scannedlpn);

    // Validate the Units value, if not valid, then return by throwing an error message
    if (!QuantityInputPanel_ValidateInput("#Units1", newunits))
    {
      // do not process any further
      evt.stopPropagation();
      evt.preventDefault();
      return;
    }

    // This function returns SKU info of the LPN in question
    [sku, skudesc, displaysku] = CC_ConfirmResvLocLPN_GetLPNSKUInfo(scannedlpn);

    // Tabulate LPN details on Location to the data table
    CC_ConfirmResvLocLPN_TableInsertUpdate(scannedpallet,                       // scanned pallet
                                           scannedlpn,                          // scanned lpn
                                           sku,                                 // lpn sku
                                           skudesc,                             // lpn sku description
                                           newinnerpacks,                       // lpn sku innerpacks
                                           newunits,                            // lpn sku quantity
                                           FORMCONTENT_UPDATETYPE_ADDUPDATE,    // update type
                                           FORMCONTENT_UPDATEMODE_BEFORE);      // update mode
  } // END PROCESS

  // RESET FORM Block
  if (resetform)
  {
    QuantityInputPanel_ClearForm();
    QuantityInputPanel_HideInputs();

    // TEMP: Only pallet CC forms for now have SIP panels
    if (scannedpallet)
    {
      CC_ConfirmResvLocLPN_UpdateSKUPanel(""); // disable the form
    }

    // Re focus on LPN clearing the form value
    $("[data-rfname='LPN']").val("");
    $("[data-rfname='LPN']").focus();
  }
} // CC_ConfirmResvLocLPN_Tabulate

//-----------------------------------------------------------------------------
// The list of LPNs scanned during the cycle count is maintained as a datatable.
// This proc is used for maintaining that table i.e. to add LPNs or update their
// info in the confirmlpns table.
// When the LPN is scanned, qty confirmed by the user, we would need to add the
// LPN to the table along with the respective info. In the event the LPN already
// exists in the table, the info would have to be updated.
function CC_ConfirmResvLocLPN_TableInsertUpdate(pallet, lpn, lpnsku, lpnskudesc, lpnip, lpnqty, updatetype, updatemode)
{
  // form related
  var tableelement      = ".js-datatable-cyclecount-confirmlpns";
  var formtype          = "";
  // Json objects
  var loclpnsjson       = {};
  var inputdata         = {};
  var coldetailstosum   = {};
  // Evaluate the form type
  if ($(tableelement).find("[data-rffieldname='Pallet']").length > 0)
  {
    formtype = "pallet";
  }
  else
  {
    formtype = "lpn";
  }


  // Pallet CC
  if (formtype == "pallet")
  {
    // Table body
    inputdata["EntityName"]   = "LPN";
    inputdata["ControlValue"] = [
                                  {"Pallet":pallet,
                                   "LPN":lpn,
                                   "SKU":lpnsku,
                                   "SKUDesc":lpnskudesc,
                                   "NewInnerPacks":lpnip,
                                   "NewUnits":lpnqty}
                                ];
    inputdata["UpdateType"]   = updatetype;
    inputdata["UpdateMode"]   = updatemode;

    // Table footer
    // Given values are the column index, & name to sum. Also respective footer attribute to update
    coldetailstosum = {"COLS": [{"COLIDX":0, "FOOTERNAME":"NumPallets", "TYPE":"UNIQCNT", "ATTRIBUTE":".js-footer-cyclecount-NumPallets"},
                                {"COLIDX":1, "FOOTERNAME":"NumLPNs", "TYPE":"COUNT", "ATTRIBUTE":".js-footer-cyclecount-NumLPNs"},
                                {"COLIDX":5, "FOOTERNAME":"NumUnits", "TYPE":"SUM", "ATTRIBUTE":".js-footer-cyclecount-NumUnits"}]}
   }
  else
  // LPN CC
  {
    // Table body
    inputdata["EntityName"]   = "LPN";
    inputdata["ControlValue"] = [
                                  {"LPN":lpn,
                                   "SKU":lpnsku,
                                   "SKUDesc":lpnskudesc,
                                   "NewInnerPacks":lpnip,
                                   "NewUnits":lpnqty}
                                ];
    inputdata["UpdateType"]   = updatetype;
    inputdata["UpdateMode"]   = updatemode;
    // Given values are the column index, & name to sum. Also respective footer attribute to update
    coldetailstosum = {"COLS": [{"COLIDX":0, "FOOTERNAME":"NumLPNs", "TYPE":"COUNT", "ATTRIBUTE":".js-footer-cyclecount-NumLPNs"},
                                {"COLIDX":3, "FOOTERNAME":"NumCases", "TYPE":"SUM", "ATTRIBUTE":".js-footer-cyclecount-NumCases"},
                                {"COLIDX":4, "FOOTERNAME":"NumUnits", "TYPE":"SUM", "ATTRIBUTE":".js-footer-cyclecount-NumUnits"}]}
  }

  // Tabulate LPNs that are scanned
  ChangeFormContent(tableelement, inputdata);

  // Summarize info from the table rows into the footer. coldetailstosum setup
  // above determines which columns of the table have to be summarized and shown
  // in the footer
  CC_UpdateTableFooter(tableelement, inputdata, coldetailstosum);
} // CC_ConfirmResvLocLPN_TableInsertUpdate

//-----------------------------------------------------------------------------
// This function is used to update the SKU Info panel on the form
// SKU details are fetched from the given lpn from the data set returned from DB
// These sku details are passed as json object to initialize the SKU panel
function CC_ConfirmResvLocLPN_UpdateSKUPanel(lpn)
{
  // json object
  var skuinput       = {};
  // data elements
  var lpnsku         = "";
  var lpnskudesc     = "";
  var lpndisplaysku  = "";

  // Initiate SIP panel with values
  if ((lpn != undefined) && (lpn != ""))
  {
    // This function returns SKU info of the LPN in question
    [lpnsku, lpnskudesc, lpndisplaysku] = CC_ConfirmResvLocLPN_GetLPNSKUInfo(lpn);
    // Setup the input data for SIP form
    skuinput["SKU"]            = lpnsku;
    skuinput["DISPLAYSKUDESC"] = lpnskudesc;
    skuinput["DISPLAYSKU"]     = lpndisplaysku;
  }

  // render SKU form as below
  SKUInfoPanel_Initialize('.amf-datacard-LPNCC-SIP', skuinput);
} // CC_ConfirmResvLocLPN_UpdateSKUPanel

//-----------------------------------------------------------------------------
// Custom handler that gets called before the form for Reserve Location Pallet CC
// is shown. This is to basically populate the data to be shown on the Data Table
function CC_ConfirmResvLocPallet_OnShow()
{
  // Initialize variables
  var ccdata            = $("[data-rfname='m_CCData']").val();
  var ccdatalist        = {};
  var ccdatalistlen     = 0;
  var inputdata         = {};
  var tableelement      = ".js-datatable-cyclecount-confirmlpns";
  var lastpalletscanned = $("[data-rfname='m_Pallet']").val();
  var lastlpnscanned    = $("[data-rfname='m_LPN']").val();
  var inputqtyprompt    = $("[data-rfname='m_InputQtyPrompt']").val();
  var currentlpn        = "";
  var promptforlpn      = "";
  var formfocus         = true;

  // Continue to tabulate these LPNs only if the above nodal data exists
  if ((ccdata != undefined) && (ccdata != ""))
  {
    ccdatalist    = JSON.parse($("[data-rfname='m_CCData']").val());
    ccdatalistlen = $(ccdatalist["CCData"]["CCTable"]).length;

    // If the object has only 1 array, convert that into json object array
    // Reason: the CC_JsonArrayFilter would need json object array within json object
    if (ccdatalistlen == 1)
    {
      var ccdatalistarray = [];
      ccdatalistarray.push(ccdatalist.CCData.CCTable);
      ccdatalist.CCData.CCTable = ccdatalistarray;
    }

    // loop through the list
    for (outlp = 0; outlp < ccdatalistlen; outlp++)
    {
      currentlpn = ccdatalist["CCData"]["CCTable"][outlp]["LPN"];

      // For cases where user needs to confirm the quantity we will not tabulate just as yet
      // In this case, the last LPN scanned was unknown and hence after validating it
      // we initiate the QIP panel for user to confirm the quantity
      if ((inputqtyprompt == "Y") && (currentlpn == lastlpnscanned))
      {
        promptforlpn = currentlpn;
      }
      else
      {
        CC_ConfirmResvLocLPN_TableInsertUpdate(ccdatalist["CCData"]["CCTable"][outlp]["Pallet"],
                                               currentlpn,
                                               ccdatalist["CCData"]["CCTable"][outlp]["SKU"],
                                               ccdatalist["CCData"]["CCTable"][outlp]["SKUDesc"],
                                               ccdatalist["CCData"]["CCTable"][outlp]["NewInnerPacks"],
                                               ccdatalist["CCData"]["CCTable"][outlp]["NewUnits"],
                                               FORMCONTENT_UPDATETYPE_ADDUPDATE,
                                               FORMCONTENT_UPDATEMODE_BEFORE)
      }
    } // end of for loop

    // Setup QIP for the unknown lpn scanned
    // Focus will be set on QIP automatically
    if (promptforlpn != "")
    {
      formfocus = false; // this will enable QIP by default
      $("[data-rfname='LPN']").val(promptforlpn);
      CC_ConfirmResvLocLPN_PromptQuantity(promptforlpn);
    }
  } // end of if block

  // Set form values and focus as necessary
  if (formfocus)
  {
    // Setting values and modifying data-rftabindex as form focus is based on that
    if ((lastpalletscanned != undefined) && (lastpalletscanned != ""))
    {
      $("[data-rfname='Pallet']").val(lastpalletscanned);
      $("[data-rfname='LPN']").focus();
    }
    else
    {
      $("[data-rfname='Pallet']").focus();
    }
  }

  // We need additional attributes for standard QIP panel, called the function to add them
  selector = "[data-rfname='NewUnits1']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfvalidationhandler":"CC_ConfirmResvLocLPN_Tabulate","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector, values);

  selector = "[data-rfname='NewInnerPacks']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfvalidationhandler":"CC_ConfirmResvLocLPN_Tabulate","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector, values);

  // Generally validation handler settings are defined after form is rendered. In
  // this case as we added validation handler in form show, call the function to
  // define the settings
  VerifyFormForValidationSettings();

  SetFocusFlagValue(true);
} // CC_ConfirmResvLocPallet_OnShow

//-----------------------------------------------------------------------------
// If the scanned Pallet is not one that is already in the Location, then
// validate it
function CC_ConfirmResvLocPallet_Validate(evt)
{
    // Variables
    var scannedpallet       = $("[data-rfname='Pallet']").val();
    var numpalletsinloc     = $("[data-rfname='m_LocationInfo_NumPallets']").val();
    var numlpnsinloc        = $("[data-rfname='m_LocationInfo_NumLPNs']").val();
    var locstoragetype      = $("[data-rfname='m_LocationInfo_StorageType']").val();
    var flagpalletinloc     = 0;  // boolean value: true/1 if exists, false/0 if not exists
    var resultarray         = []; // array

    // If no pallet is scanned, proceed to scan LPN only for the given location
    if (((scannedpallet == undefined) || (scannedpallet == "")) && (locstoragetype == "A" /* Pallet */) &&
        ($(evt.relatedTarget).text() != "Confirm LPN"))
    {
      ConfirmYesNo("No Pallet scanned! Is Location Empty?",
        function ()
          {
            // complete cc, when the user clicks yes
            CC_Submit_Request(evt);
          },
          function ()
          {
            // return back with message, when the user clicks no
            // location is not empty and so force user to scan Pallet and then proceed to complete CC
            DisplayWarningMessage("Pallet is required for Pallet Storage type Location");
            $("[data-rfname='Location']").focus();
            return;
          });
    }
    else
    if ((scannedpallet == undefined) || (scannedpallet == ""))
    {
      $("[data-rfname='LPN']").focus();
      return;
    }
    else
    {
      // Pallets data exists only if Location is non-empty
      if (numpalletsinloc > 0)
      {
        resultarray     = CC_GetLocationPallets(scannedpallet);
        flagpalletinloc = resultarray[1];
      }

      // If the pallet does not exist in location or if being scanned into empty location
      // Validate pallet first
      if (!flagpalletinloc)
      {
        $("[data-rfname='RFFormAction']").val("CCLocationUnknownPallet");

        CC_UnknownEntity_Validate();
      }

      $("[data-rfname='LPN']").focus();
    }
} //CC_ConfirmResvLocPallet_Validate

//-----------------------------------------------------------------------------
// helper function
// function assists in searching for table cell value
// Returns a boolean value true/false
function CC_CheckTableEntry(controlselector, searchvalue)
{
    return Boolean($($(controlselector).find("tr td").filter(function()
                                                      {
                                                        return ($(this).text() === searchvalue);
                                                      })).length > 0);
} // CC_CheckTableEntry

//-----------------------------------------------------------------------------
// helper function
// function to get the lpns in the location
// output would be an array that consists of
// a. loclpnjson      - json object of lpns in location
// b. lpninlocation   - flag to indicate whether scanned lpn exists in location or not
// c. lpndetailsarray - details of the scanned lpn
function CC_GetLocationLPNs(scannedlpn)
{
  var loclpnsjson       = {};
  var flaglpninlocation = 0;
  var lpndetailsarray   = [];
  var outputarray       = [];
  var numlpnsinlocation = $("[data-rfname='m_LocationInfo_NumLPNs']").val();

  // if location is not empty
  if (numlpnsinlocation != 0)
  {
    loclpnsjson = JSON.parse($("[data-rfname='m_LOCLPNS']").val());

    // The inner value of the json object should be an array of json objects
    if ($(loclpnsjson["LOCLPNS"]["LOCLPN"]).length == 1)
    {
      var loclpnsarray = [];
      loclpnsarray.push(loclpnsjson.LOCLPNS.LOCLPN);
      loclpnsjson.LOCLPNS.LOCLPN = loclpnsarray;
    }

    // check if the lpn exists in location
    flaglpninlocation = Boolean(loclpnsjson["LOCLPNS"]["LOCLPN"].filter(CC_JsonArrayFilter("LPN"), scannedlpn).length > 0);

    // lpn details array of the scanned lpn if it exists on the location
    if (flaglpninlocation)
      lpndetailsarray = loclpnsjson["LOCLPNS"]["LOCLPN"].filter(CC_JsonArrayFilter("LPN"), scannedlpn);
  }

  // save the output values into an array
  outputarray.push(loclpnsjson);
  outputarray.push(flaglpninlocation);
  outputarray.push(lpndetailsarray);

  return outputarray;
} // CC_GetLocationLPNs

//-----------------------------------------------------------------------------
// helper function
// function to get the pallets in the location
// output would be an array that consists of
// a. locpalletjson    - json object of pallets in location
// b. palletinlocation - flag to indicate whether scanned lpn exists on location or not
function CC_GetLocationPallets(scannedpallet)
{
  var numpalletsinlocation  = $("[data-rfname='m_LocationInfo_NumPallets']").val();
  var locpalletsjson        = {};
  var flagpalletinlocation  = 0;
  var outputarray           = [];

  // if location is not empty
  if (numpalletsinlocation != 0)
  {
    locpalletsjson = JSON.parse($("[data-rfname='m_LOCLPNS']").val());

    // The inner value of the json object should be an array of json objects
    if ($(locpalletsjson["LOCLPNS"]["LOCLPN"]).length == 1)
    {
      var locarray = [];
      locarray.push(locpalletsjson.LOCLPNS.LOCLPN);
      locpalletsjson.LOCLPNS.LOCLPN = locarray;
    }

    // check if the lpn exists on location
    flagpalletinlocation = Boolean(locpalletsjson["LOCLPNS"]["LOCLPN"].filter(CC_JsonArrayFilter("Pallet"), scannedpallet).length > 0);
  }

  // save the output values into an array
  outputarray.push(locpalletsjson);
  outputarray.push(flagpalletinlocation);

  return outputarray;
} // CC_GetLocationPallets

//-----------------------------------------------------------------------------
// helper function
// function assists in getting the table row index and returns the row index
// control selector here is of table element / table body element
function CC_GetTableRowIndex(controlselector, searchvalue)
{
  // returns the integer value of the row index with match
  return $(controlselector).find("tr td").filter(function(){return ($(this).text() === searchvalue)}).parent().index();

} // CC_GetTableRowIndex

//-----------------------------------------------------------------------------
// helper function
// function assists in filtering a json object to fetch value for a matching given property name
function CC_JsonArrayFilter(propertyName)
{
    return function (searchObject) {
        // verify if the field name of the current searchObject is same as the one required
        // toUpperCase is for ensuring the field name is searched without case-sensitivity
        return (searchObject[propertyName] == this.toString());
    }
} // CC_JsonArrayFilter

//-----------------------------------------------------------------------------
// Custom handler to populate the list of Entities to be sent as inputXML
// Output json object from this function
// {"CCData": {"CCTable": [ {"LPN":"abc", "SKU":"123"}, {"LPN":"xyz", "SKU":"456"} ] } }
function CC_PopulateEntityInput()
{
  // Define an empty array to store json objects
  var jsonarray  = [];

  // Find table header columns
  var tableheaders = $("[data-rfrecordname='CCTable']").find("thead tr th");

  // TODO Code is not readable. could be made simpler with some changes
  // TODO let us leave it at that for now here. we can revisit, if need be.
  // Loop through the body elements and store each row as json object into the array declared above
  var tablerows = $("[data-rfrecordname='CCTable']").find("tbody tr").each(function(index)
    {
      tablecells = $(this).find("td");
      jsonarray[index] = {};
      tablecells.each(function(cellindex)
        {
          jsonarray[index][$(tableheaders[cellindex]).attr("data-rffieldname")] = $(this).text();
        });
    });

  // Store this array into a json object saved into the hidden form element to be pushed into the InputXML later
  var jsonresult = {};
  jsonresult["CCTable"] = jsonarray;

  $("[data-rfname='CCData']").val(JSON.stringify(jsonresult));
} // CC_PopulateEntityInput

//-----------------------------------------------------------------------------
// Custom handler to submit request mid way to validate inputs
function CC_UnknownEntity_Validate()
{
   $("#RFSkipInputValidation").val(true);
   $('form').submit();
} // CC_UnknownEntity_Validate

//-----------------------------------------------------------------------------
// Custom handler to calculate the footer
// controlselector: attribute to identify table
// inputdata: json object with array of json objects of new rows to be inserted
// coldetailstosum: json object with array of json objects with details of column summation
function CC_UpdateTableFooter(controlselector, inputdata, coldetailstosum)
{
  // fetch all values
  var tableheaders  = $($((controlselector)).get(0)).find("thead tr th");
  var tablebody     = $($((controlselector)).get(0)).find("tbody");
  var tablerows     = $($((controlselector)).get(0)).find("tbody tr");

  // Continue only if the table body has any rows to sum
  if ((tablerows.length > 0))
  {
    // variables
    var noofrows     = tablerows.length; // get the row count on the table
    var colidx       = 0;
    var rowidx       = 0;
    var colaggrtype  = "";
    var attribute    = "";
    var footintvalue = 0;
    var footstrvalue = "";

    // loop through the list of columns for evaluating footer values
    // another way to look at this is the number of columns to be considered
    for (i = 0; i < coldetailstosum['COLS'].length; i++)
    {
      // fetch values
      colidx        = coldetailstosum['COLS'][i]['COLIDX'];
      rowidx        = 0;
      colaggrtype   = coldetailstosum['COLS'][i]['TYPE'];
      attribute     = coldetailstosum['COLS'][i]['ATTRIBUTE'];
      footintvalue  = 0;
      footstrvalue  = "";

      // Compute aggregated footer value of the column as required
      if (colaggrtype == "SUM")
      {
        $(tablerows).each(function(index, tr)
          {
            footintvalue = footintvalue + (parseInt($($($(tablerows)[index]).find("td")[colidx]).text()) || 0);
          });
      }
      else
      if (colaggrtype == "COUNT")
        footintvalue = noofrows;
      else
      if (colaggrtype == "UNIQCNT")
      {
        var match_colarray = [];

        $(tablerows).each(function(index, tr)
          {
            // Get the value of the row and of the given column index
            footstrvalue = $($($(tablerows)[index]).find("td")[colidx]).text();

            // If value is non empty proceed to count as below
            if ((footstrvalue != "") && (footstrvalue != undefined))
            {
              // If value has occurred only once (not found in the array), add to array and increment the count
              if (match_colarray.indexOf(footstrvalue) == -1)
              {
                footintvalue += 1; // increment the footer count
                match_colarray.push(footstrvalue); // add to the array list
              }
            } // end of value check
          }); // end of loop function
      }

      // reset the footer value with the updates value
      $(attribute).text(footintvalue);
    } // end of loop
  } // end of table row check
} // CC_UpdateFooter

//-----------------------------------------------------------------------------
// Custom handler to submit request
function CC_Submit_Request(evt)
{
   $("#RFSkipInputValidation").val(true);
   $("[data-rfname='RFFormAction']").val("CompleteCC");
   $('form').submit();
} // CC_Submit_Request