$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

  $(document).on("click", ".js-datatable-content-details tbody tr", function(evt) {
    var row           = $(this).closest("tr");
    var clickedentity = row.find("td:eq(7)").text();

    // get NumSKUs and NumLines values to continue further for multi lines/skus
    var numskus = $("[data-rfname='m_LocationInfo_NumSKUs']").val();
    var numlines = $("[data-rfname='m_LPNInfo_NumLines']").val();

    // call the initialize method to assign values to QIP when we have more
    // than a line in the datatable
    if((numskus > 1) || (numlines > 1))
    {
      Inventory_InitializeQIPFromDTSKUDetails(clickedentity, row);
    }
  });

  // In Add(Update) Inventory screen, user is required to select the SKU+Inventory class
  // to edit the appropriate line.
  $(document).on("click", ".js-datatable-loc-details tbody tr", function(evt) {
    var tablerow      = $(this).closest("tr");
    //var clickedentity = tablerow.find("td:eq(12)").text();

    Inventory_MP_AddInv_UpdateValues(tablerow);
  });

  // In Manage Picklane screen, user is given a provision to select the SKU+Inventory class
  // to remove the zero qty SKU.
  $(document).on("click", ".js-datatable-sku-details tbody tr", function(evt) {
    var tablerow      = $(this).closest("tr");
    //var clickedentity = tablerow.find("td:eq(12)").text();

    Inventory_MP_RemoveInv_UpdateValues(tablerow);
  });

  // This is a key press event to filter value in Manage Picklane
  $("[data-rfname='FilterValue']").on("keyup", function() {
    var searchvalue = $(this).val().toLowerCase();
    var operation = $("[data-rfname='Operation']").val();
    if (operation == "ManagePicklane")
    {
      Inventory_MP_FilterValueEntered(searchvalue);
    }
    if ((operation == "AdjustQty") || (operation == "TransferInventory"))
    {
      Inventory_AdjustOrTransfer_FilterValueEntered(searchvalue);
    }
  });

});

//*****************************************************************************
//*************************** Add SKU To LPN **********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// function to skip input validations and assign value to RFFormAction
function Inventory_AddSKUToLPN_Complete(evt)
{
  // when the user clicks complete/done button, assign value to RFFormAction
  $("[data-rfname='RFFormAction']").val("AddSKUToLPNComplete");
  SkipInputValidationsAndSubmit();
} // Inventory_AddSKUToLPN_Complete

//-----------------------------------------------------------------------------
// function to get values for the scanned SKU
function Inventory_AddSKUToLPN_GetValues()
{

  var inventoryuom      = $("[data-rfname='m_SKUInfo_InventoryUoM']").val();
  var unitsperinnerpack = $("[data-rfname='m_SKUInfo_UnitsPerInnerPack']").val();
  var innerpacksperlpn  = $("[data-rfname='m_SKUInfo_InnerPacksPerLPN']").val();
  var unitsperlpn       = $("[data-rfname='m_SKUInfo_UnitsPerLPN']").val();

  return [inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn];
} // Inventory_AddSKUToLPN_GetValues

//-----------------------------------------------------------------------------
// custom handler to perform form related updates on show
function Inventory_AddSKUToLPN_OnShow()
{
  // Get the scanned SKU
  var scannedentity = $("[data-rfname='SKU']").val();

  // if sku is not scanned/entered earlier, skip form related updates
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
    return;

  // clear the inputs under input panel
  QuantityInputPanel_ClearForm();

  // fetch the required values
  var [inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn]  = Inventory_AddSKUToLPN_GetValues();

  var selecteduom = inventoryuom.substring(0, 2);
  var storagetype = ''; //To handle undefined error as we are using match function

  // Initialize values for fields in the quantity input panel
  QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Inventory_AddSKUToLPN_OnShow

//-----------------------------------------------------------------------------
//custom handler to change input controls from eaches to cases
function Inventory_AddSKUToLPN_SelectCases_Onchange()
{
  // fetch the required values
  var [inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn]  = Inventory_AddSKUToLPN_GetValues();

  var selecteduom = 'CS';
  var storagetype = ''; //To handle undefined error as we are using match function

  QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)

} // Inventory_AddSKUToLPN_SelectCases_Onchange

//-----------------------------------------------------------------------------
//custom handler to change input controls from cases to eaches
function Inventory_AddSKUToLPN_SelectEaches_Onchange()
{
  // fetch the required values
  var [inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn]  = Inventory_AddSKUToLPN_GetValues();

  var selecteduom = 'EA';
  var storagetype = ''; //To handle undefined error as we are using match function

  QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)

} // Inventory_AddSKUToLPN_SelectEaches_Onchange

//*****************************************************************************
//************************ Adjust Location Quantity ****************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// When AdjustLocQty form is being shown, based upon whether LPN is single SKU
// or mixed SKU, the form has to be setup accordingly and this method does that.
function Inventory_AdjustLocQty_OnShow()
{
  // get the numskus value
  var numskus = $("[data-rfname='m_LocationInfo_NumSKUs']").val();

  // set the visibility of change panel to show the differences between current and new values
  QuantityInputPanel_ShowChangedValues('Y');

  // QIP by default has minimum value of 1 for Cases & Units, however in adjust we need to allow
  // user to zero out the qty and hence min values are changed to zero.
  QuantityInputPanel_InitializeMin(0);

  // we need the next sequence only for single sku location
  if ((numskus > 1) || (numskus == null) || (numskus == undefined) || (numskus == ""))
  {
      return;
  }

  // get the SKU and set values for single SKU Location
  var scannedentity = $("[data-rfname='m_LocationInfo_SKU']").val();
  Inventory_InitializeQIPFromDTSKUDetails(scannedentity, null)

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Inventory_AdjustLocQty_OnShow

//-----------------------------------------------------------------------------
// Validate the scanned entity highlight the row and set input  values for QIP(Quantity Input Panel)
function Inventory_AdjustLocQty_OnSKUEnter(evt)
{
  /* Get the scanned entity */
  var scannedentity = $("[data-rfname='SKU']").val();

  // if the user has skipped entering the value, then assume that the user wishes to
  // skip entering the value and return later
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
      return;
  }

  // set the values
  Inventory_InitializeQIPFromDTSKUDetails(scannedentity, null)

  // do not process any further
  evt.stopPropagation();
  evt.preventDefault();
  return;
} // Inventory_AdjustLocQty_OnSKUEnter

//*****************************************************************************
//*************************** Adjust LPN Qty **********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// When AdjustLPNQty form is being shown, based upon whether LPN is single SKU
// or mixed SKU, the form has to be setup accordingly and this method does that.
function Inventory_AdjustLPNQty_OnShow()
{
  // get the numlpns value
  var numlines = $("[data-rfname='m_LPNInfo_NumLines']").val();

  // set the visibility of change panel to show the differences between current and new values
  QuantityInputPanel_ShowChangedValues('Y');

  // QIP by default has minimum value of 1 for Cases/Units, however in adjust we need to allow
  // user to zero out the qty and hence min values are changed to zero.
  QuantityInputPanel_InitializeMin(0);

  // if multi-SKU LPN, then there is no further setup to done now, it would be done after
  // user scans the SKU, so return
  if ((numlines > 1) || (numlines == null) || (numlines == undefined) || (numlines == ""))
  {
      return;
  }

  if (numlines == 1)
  {
    // Use the SKU of the LPN and get the details and setup QIP accordingly
    var scannedentity  = $("[data-rfname='m_LPNInfo_SKU']").val();
    Inventory_InitializeQIPFromDTSKUDetails(scannedentity, null)
  }

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Inventory_AdjustLPNQty_OnShow

//-----------------------------------------------------------------------------
// Validate the scanned entity highlight the row and set input  values for QIP(Quantity Input Panel)
function Inventory_AdjustLPNQty_OnSKUEnter(evt)
{
  /* Get the scanned entity */
  var scannedentity = $("[data-rfname='SKU']").val();

  // if the user has skipped entering the value, then assume that the user wishes to
  // skip entering the value and return later
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
      return;
  }

  // set the values for QIP
  Inventory_InitializeQIPFromDTSKUDetails(scannedentity, null)

  // do not process any further
  evt.stopPropagation();
  evt.preventDefault();
  return;
} // Inventory_AdjustLPNQty_OnSKUEnter

//-----------------------------------------------------------------------------
// This method filters the value and shows rows with value entered by the
// user. If no matches are found then nothing will get displayed in table
function Inventory_AdjustOrTransfer_FilterValueEntered(searchvalue)
{
  var numskus = $("[data-rfname='m_LocationInfo_NumSKUs']").val();
  var numlines = $("[data-rfname='m_LPNInfo_NumLines']").val();
  var locsubtype = $("[data-rfname='m_LocationInfo_LocationSubType']").val();

  // Apply the filter on the data table using the given search value
  $(".js-datatable-content-details tbody tr").filter(function() {
    $(this).toggle($(this).text().toLowerCase().indexOf(searchvalue) > -1)
  });

  // after filtering the rows, get the count of visible rows.
  var visiblerows = $('tr:visible').length - 1;

  // If the entire list of SKUs in the Location is not being shown and
  // user has given atleast 3 chars to search and
  // the given search value is not in the list already,
  if (((parseInt(numskus) >= 10) || ((parseInt(numlines) >= 10))) && ((searchvalue.length) > 3))
  // && (visiblerows == 0))
  {
    $("[data-rfname='RFFormAction']").val("GetSKUs");
    SkipInputValidationsAndSubmit();
  }
} // Inventory_AdjustOrTransfer_FilterValueEntered

//*****************************************************************************
//*************************** Select Cases/Eaches *****************************
//*****************************************************************************

//-----------------------------------------------------------------------------
//custom handler to change input controls from eaches to cases
function Inventory_AdjustOrTransferLocQty_SelectCases_Onchange()
{
  var numskus = $("[data-rfname='m_LocationInfo_NumSKUs']").val();

  if (numskus == 1)
  {
    var scannedentity = $("[data-rfname='m_LocationInfo_SKU']").val();
  }
  else
  if (numskus > 1)
  {
    var scannedentity = $("[data-rfname='SKU']").val();
  }

  // if multi SKU Picklane, identify the scanned entity as well.
  var tablerow  = DataTableSKUDetails_GetTableRow(scannedentity);

  // fetch the required values
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var storagetype  = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var selecteduom;

  QuantityInputPanel_SetupInnerPacks (inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)

} // Inventory_AdjustOrTransferLocQty_SelectCases_Onchange

//-----------------------------------------------------------------------------
//custom handler to change input controls from cases to eaches
function Inventory_AdjustOrTransferLocQty_SelectEaches_Onchange()
{
  var numskus = $("[data-rfname='m_LocationInfo_NumSKUs']").val();

  if (numskus == 1)
  {
    var scannedentity = $("[data-rfname='m_LocationInfo_SKU']").val();
  }
  else
  if (numskus > 1)
  {
    var scannedentity = $("[data-rfname='SKU']").val();
  }

  // if multi SKU Picklane, identify the scanned entity as well.
  var tablerow      = DataTableSKUDetails_GetTableRow(scannedentity);

  // fetch the required values
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var storagetype  = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var selecteduom;

  QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)

} // Inventory_AdjustOrTransferLocQty_SelectEaches_Onchange

//-----------------------------------------------------------------------------
//custom handler to change input controls from eaches to cases
function Inventory_AdjustOrTransferLPNQty_SelectCases_Onchange()
{
  var numlines = $("[data-rfname='m_LPNInfo_NumLines']").val();

  if (numlines == 1)
  {
    var scannedentity = $("[data-rfname='m_LPNInfo_SKU']").val();
  }
  else
  if (numlines > 1)
  {
    var scannedentity = $("[data-rfname='SKU']").val();
  }

  // if multi SKU LPN, identify the scanned entity as well.
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  // fetch the required values
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var selecteduom  = 'CS';
  var storagetype  = "";

  QuantityInputPanel_SetupInnerPacks (inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)

} // Inventory_AdjustOrTransferLPNQty_SelectCases_Onchange

//-----------------------------------------------------------------------------
//custom handler to change input controls from cases to eaches
function Inventory_AdjustOrTransferLPNQty_SelectEaches_Onchange()
{
  var numlines = $("[data-rfname='m_LPNInfo_NumLines']").val();

  if (numlines == 1)
  {
    var scannedentity = $("[data-rfname='m_LPNInfo_SKU']").val();
  }
  else
  if (numlines > 1)
  {
    var scannedentity = $("[data-rfname='SKU']").val();
  }

  // if multi SKU LPN, identify the scanned entity as well.
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  // fetch the required values
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var selecteduom  = 'EA';
  var storagetype  = "";

  QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)

} // Inventory_AdjustOrTransferLPNQty_SelectEaches_Onchange

//*****************************************************************************
//********************** Adjust Quantity common methods ***********************
//*****************************************************************************

//-----------------------------------------------------------------------------
//custom handler to validate Reason codes
function Inventory_AdjustQty_ValidateReasonCode(evt)
{
  var reasoncode = $("[data-rfname='ReasonCode']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid reason code";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_AdjustQty_ValidateReasonCode

//*****************************************************************************
//***************************** Build Pallet **********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
//custom handler to execute complete build function call
function Inventory_BuildPallet_CompleteOrPause(evt)
{
  // when the user clicks complete button, assign value to RFFormAction
  $("#RFSkipInputValidation").val(true);
  $("[data-rfname='RFFormAction']").val("CompleteBuild");
  $("form").submit();
} // Inventory_BuildPallet_CompleteOrPause

//*****************************************************************************
//***************************** Build Inventory *******************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// custom handler to Perform form related updates on show
function Inventory_BuildInv_OnShow()
{
  // Get the scanned SKU
  var scannedentity = $("[data-rfname='SKU']").val();

  // if sku is not scanned/entered earlier, skip form related updates
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
    return;

  // clear the inputs under input panel
  QuantityInputPanel_ClearForm();

  // fetch the required values
  var inventoryuom = $("[data-rfname='m_SKUInfo_InventoryUoM']").val();
  var unitsperinnerpack = $("[data-rfname='m_SKUInfo_UnitsPerInnerPack']").val();
  var innerpacksperlpn = $("[data-rfname='m_SKUInfo_InnerPacksPerLPN']").val();
  var unitsperlpn = $("[data-rfname='m_SKUInfo_UnitsPerLPN']").val();

  var selecteduom = inventoryuom.substring(0, 2);
  var storagetype = ''; //To handle undefined error as we are using match function

  // Initialize values for fields in the quantity input panel
  QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

  // We need additional attributes for standard QIP panel,
  // Any changes to js method names, need here as well
  selector = "[data-rfname='NewUnits1']";
  values   = {"data-rfvalidationhandler":"Inventory_BuildInv_SetFocus","data-rfvalidateon":"FOCUSOUT"};
  QuantityInputPanel_AddAttributes(selector,values)

  // Generally validation handler settings are defined after form is rendered. In
  // this case as we added validation handler in form show, call the function to
  // define the settings
  VerifyFormForValidationSettings();

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Inventory_BuildInv_OnShow

//-----------------------------------------------------------------------------
//custom handler to change input controls from eaches to cases
function Inventory_BuildInv_SelectCases_Onchange()
{
  // fetch the required values
  var inventoryuom = $("[data-rfname='m_SKUInfo_InventoryUoM']").val();
  var unitsperinnerpack = $("[data-rfname='m_SKUInfo_UnitsPerInnerPack']").val();
  var innerpacksperlpn = $("[data-rfname='m_SKUInfo_InnerPacksPerLPN']").val();
  var unitsperlpn = $("[data-rfname='m_SKUInfo_UnitsPerLPN']").val();

  var selecteduom = 'CS';
  var storagetype = ''; //To handle undefined error as we are using match function

  QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)

} // Inventory_BuildInv_SelectCases_Onchange

//-----------------------------------------------------------------------------
//custom handler to change input controls from cases to eaches
function Inventory_BuildInv_SelectEaches_Onchange()
{
  // fetch the required values
  var inventoryuom = $("[data-rfname='m_SKUInfo_InventoryUoM']").val();
  var unitsperinnerpack = $("[data-rfname='m_SKUInfo_UnitsPerInnerPack']").val();
  var innerpacksperlpn = $("[data-rfname='m_SKUInfo_InnerPacksPerLPN']").val();
  var unitsperlpn = $("[data-rfname='m_SKUInfo_UnitsPerLPN']").val();

  var selecteduom = 'EA';
  var storagetype = ''; //To handle undefined error as we are using match function

  QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)

} // Inventory_BuildInv_SelectEaches_Onchange

//-----------------------------------------------------------------------------
// Custom handler to set focus for Pallet or Location
function Inventory_BuildInv_SetFocus()
{
  // fetch the required values
  var pallet   = $("[data-rfname='Pallet']").val();
  var location = $("[data-rfname='Location']").val();

  if ((pallet == null) || (pallet == undefined) || (pallet == ""))
    $("[data-rfname='Pallet']").focus();
  else
  if ((location == null) || (location == undefined) || (location == ""))
    $("[data-rfname='Location']").focus();
  else
    // if user scanned Pallet and Location, then set focus to LPN
    $("[data-rfname='LPN']").focus();

} // Inventory_BuildInv_SetFocus

//-----------------------------------------------------------------------------
// Custom handler to set focus for Pallet or Location
function Inventory_BuildInv_SetFocusToLocOrLPN()
{
  // fetch the required values
  var location = $("[data-rfname='Location']").val();

  if ((location == null) || (location == undefined) || (location == ""))
    $("[data-rfname='Location']").focus();
  else
    $("[data-rfname='LPN']").focus();

} // Inventory_BuildInv_SetFocusToLocOrLPN

//-----------------------------------------------------------------------------
//custom handler to validate InvClass that is selected under BuildInv
function Inventory_BuildInv_ValidateInvClass1(evt)
{
  var inventoryclass = $("[data-rfname='InventoryClass1']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (inventoryclass == '*')
  {
    message.Message.DisplayText = "Please select a valid Inventory Class";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_BuildInv_ValidateInvClass1

//-----------------------------------------------------------------------------
//custom handler to validate Owner that is selected under BuildInv
function Inventory_BuildInv_ValidateOwnership(evt)
{
  var owner = $("[data-rfname='Owner']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (owner == '*')
  {
    message.Message.DisplayText = "Please select a valid Owner";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_BuildInv_ValidateOwnership

//-----------------------------------------------------------------------------
//custom handler to validate Reason codes
function Inventory_BuildInv_ValidateReasonCode(evt)
{
  var reasoncode = $("[data-rfname='ReasonCode']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid reason code";
  }
  else
  if (reasoncode != '999')
  {
    message.Message.DisplayText = "Reason should be 999-Initial Inventory"
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_BuildInv_ValidateReasonCode

//-----------------------------------------------------------------------------
// custom handler to perform form related updates on submit
function Inventory_BuildInv_Submit(evt)
{
  var lpn     = $("[data-rfname='LPN']").val();
  var numlpns = parseInt($("[data-rfname='NumLPNs']").val());

  // If user is updating existing SKU, then ensure that
  if ((lpn != undefined) && (lpn != "") && (numlpns > 1))
  {
    DisplayErrorMessage("Num LPNs should not be more than 1 when LPN is scanned");
    return;
  }

  $('form').submit();

} // Inventory_BuildInv_Submit

//-----------------------------------------------------------------------------
//custom handler to validate Warehouse that is selected under BuildInv
function Inventory_BuildInv_ValidateWarehouse(evt)
{
  var warehouse = $("[data-rfname='Warehouse']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (warehouse == '*')
  {
    message.Message.DisplayText = "Please select a valid Warehouse";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_BuildInv_ValidateWarehouse

//*****************************************************************************
//***************************** Create Inv LPN ********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// custom handler to perform form related updates on show
function Inventory_CreateInvLPN_OnShow()
{
  // Get the scanned SKU
  var scannedentity = $("[data-rfname='SKU']").val();

  // if sku is not scanned/entered earlier, skip form related updates
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
    return;

  // clear the inputs under input panel
  QuantityInputPanel_ClearForm();

  // fetch the required values
  var inventoryuom = $("[data-rfname='m_SKUInfo_InventoryUoM']").val();
  var unitsperinnerpack = $("[data-rfname='m_SKUInfo_UnitsPerInnerPack']").val();
  var innerpacksperlpn = $("[data-rfname='m_SKUInfo_InnerPacksPerLPN']").val();
  var unitsperlpn = $("[data-rfname='m_SKUInfo_UnitsPerLPN']").val();

  var selecteduom = inventoryuom.substring(0, 2);
  var storagetype = ''; //To handle undefined error as we are using match function

  // Initialize values for fields in the quantity input panel
  QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Inventory_CreateInvLPN_OnShow

//-----------------------------------------------------------------------------
//custom handler to validate InvClass that is selected under CreateInvLPN
function Inventory_CreateInvLPN_ValidateInvClass1(evt)
{
  var reasoncode = $("[data-rfname='InventoryClass1']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid Inventory Class";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_CreateInvLPN_ValidateInvClass1

//-----------------------------------------------------------------------------
//custom handler to validate Owner that is selected under CreateInvLPN
function Inventory_CreateInvLPN_ValidateOwnership(evt)
{
  var reasoncode = $("[data-rfname='Owner']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid Owner";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_CreateInvLPN_ValidateOwnership

//-----------------------------------------------------------------------------
//custom handler to validate Reason codes
function Inventory_CreateInvLPN_ValidateReasonCode(evt)
{
  var reasoncode = $("[data-rfname='ReasonCode']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid reason code";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_CreateInvLPN_ValidateReasonCode

//-----------------------------------------------------------------------------
//custom handler to validate Warehouse that is selected under CreateInvLPN
function Inventory_CreateInvLPN_ValidateWarehouse(evt)
{
  var reasoncode = $("[data-rfname='Warehouse']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid Warehouse";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_CreateInvLPN_ValidateWarehouse

//*****************************************************************************
//********************** Set QIP Values on table click ************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// this method is used to set the values in QIP based on the scannedentity/tablerow
// i.e., passed to this method. As the table might have multiple rows with same SKU but
// different labelcodes, we may need to adjust/perform any action against one particular
// record having specific code. So we have given an option for user to tap on table
// and we will fetch the row index and passed which will be unique.
function Inventory_InitializeQIPFromDTSKUDetails(scannedsku, row)
{
  var currentoperation = $("[data-rfname='Operation']").val();
  var tablerow;

  if (currentoperation == 'AddSKUToLPN')
  {
    return;
  }

  // Set value for SKU
  $("[data-rfname='SKU']").val(scannedsku);

  // Remove the previous highlighted row and hide all the inputs & reason code
  DataTableSKUDetails_ClearHighlightedRow();
  QuantityInputPanel_HideInputs();
  $('.amf-datacard-ReasonCodes-input').addClass('hidden');

  // get the table row if not passed
  if (row == null)
    tablerow = DataTableSKUDetails_GetTableRow(scannedsku);
  else
    tablerow = row;

  if ($(tablerow).length == 0)
  {
    DisplayErrorMessage("Scanned SKU is not present in the list");
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // clear the inputs under input panel and show the reason codes
  QuantityInputPanel_ClearForm();
  $('.amf-datacard-ReasonCodes-input').removeClass('hidden');

  // Highlight the row which has the scanned entity
  DataTableSKUDetails_HighlightRow(tablerow, scannedsku);

  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);
  var [quantity, quantity1, quantity2, availableqty, reservedqty, qtyordered, qtyreserved, minqty, maxqty] = DataTableSKUDetails_GetQtyValues(tablerow);

  QuantityInputPanel_SetRange(minqty, maxqty, null, null, null);

  // Initialize values for fields in the quantity input panel
  QuantityInputPanel_InitializeForSKU(inventoryuom, null, "", unitsperinnerpack, innerpacksperlpn, unitsperlpn);

  // Save the LPNDetailId from the selected row to be passed back to SQL
  $("[data-rfname='LPNDetailId']").val($($(tablerow).find("td")[50]).text());
} // Inventory_InitializeQIPFromDTSKUDetails

//*****************************************************************************
//*************************** Manage Picklane *********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// In Add Inventory, when user Submits the form, we need to verify if the user
// selected the record to update for multi-SKU+InventoryClass and this function
// validates and if it passes calls submit
function Inventory_MP_AddInv_Confirm(evt)
{
  var newskuadded  = $("[data-rfname='m_NewSKUAddedForDynamicLoc']").val();
  var rowselected;

  // If user is updating existing SKU, then ensure that 
  if ((newskuadded == 'N') &&
     (!($(document).find('.js-datatable-loc-details tr').hasClass("amf-form-datatable-row-highlight-tablet"))))
  {
      rowselected  = 'N';
  }
    else
      rowselected  = 'Y';

  if (rowselected == 'N')
  {
    DisplayErrorMessage("Please select the record to update inventory");
    return;
  }

  $('form').submit();

} // Inventory_MP_AddInv_Confirm

//-----------------------------------------------------------------------------
// When Update Inventory form is shown, we would need to capture the SKUId and LPNId
// of the SKU being added from the Loc-Details datatable to pass back on submit
function Inventory_MP_AddInv_OnShow()
{
  // get the SKU being adjusted/added
  var sku = $("[data-rfname='m_SKU']").val();

  // if new SKU is added for dynamic picklane then we will get this value
  var newskuadded = $("[data-rfname='m_NewSKUAddedForDynamicLoc']").val();

  // this value is the number of visible rows in the table
  var visiblerows = $('tr:visible').length - 1;

  // when we have same SKU with multiple inventoryclasses and user tried to update the quantity.
  if ((visiblerows > 1) && (newskuadded == 'N'))
  {
    DisplayWarningMessage("Please select at least one line to update the quantity");
  }

  // when there is only one SKU and user did not try to add new sku with inventoryclass
  if ((visiblerows == 1)&& (newskuadded == 'N'))
  {
    // identify the table row of the SKU in the data table
    var tablerow = $(document).find('.js-datatable-loc-details tr').filter(function () {
    return ($(this).find('td').eq(1).text() === sku); }).closest("tr");

    // highlight the row
    $(tablerow).first().addClass("amf-form-datatable-row-highlight-tablet");

    // Get the required values
    $("[data-rfname='CurrInvClass1']").val($($(tablerow).find("td")[9]).text());
    $("[data-rfname='CurrInvClass2']").val($($(tablerow).find("td")[10]).text());
    $("[data-rfname='CurrInvClass3']").val($($(tablerow).find("td")[11]).text());
    $("[data-rfname='LPNId']").val($($(tablerow).find("td")[12]).text());
    $("[data-rfname='SKUId']").val($($(tablerow).find("td")[13]).text());

    // when user clicked on the line fetch quantity and update it in quantity input
    $("[data-rfname='Quantity']").val($($(tablerow).find("td")[3]).text());
  }

} // Inventory_MP_AddInv_OnShow

//-----------------------------------------------------------------------------
// When user selects the record we have to update the data entry fields with the
// values from the selected record
function Inventory_MP_AddInv_UpdateValues(tablerow)
{
    // If there is any previously highlighted row clear it
    $(".amf-form-datatable-row-highlight-tablet").removeClass();

    // highlight the row
    $(tablerow).first().addClass("amf-form-datatable-row-highlight-tablet");

    // Get the required values
    $("[data-rfname='CurrInvClass1']").val($($(tablerow).find("td")[9]).text());
    $("[data-rfname='CurrInvClass2']").val($($(tablerow).find("td")[10]).text());
    $("[data-rfname='CurrInvClass3']").val($($(tablerow).find("td")[11]).text());
    $("[data-rfname='LPNId']").val($($(tablerow).find("td")[12]).text());
    $("[data-rfname='SKUId']").val($($(tablerow).find("td")[13]).text());

    $("[data-rfname='Quantity']").val($($(tablerow).find("td")[3]).text());
    $("[data-rfname='Quantity']").focus();
} // Inventory_MP_AddInv_UpdateValues

//-----------------------------------------------------------------------------
// This method filters the value and shows rows with value entered by the
// user. If no matches are found then nothing will get displayed in table
function Inventory_MP_FilterValueEntered(searchvalue)
{
  var addinventory = $("[data-rfname='ConfirmAddInventory']").prop('checked');
  var numskus = $("[data-rfname='m_LocationInfo_NumSKUs']").val();
  var locsubtype = $("[data-rfname='m_LocationInfo_LocationSubType']").val();

  // Apply the filter on the data table using the given search value
  $(".js-datatable-sku-details tbody tr").filter(function() {
    $(this).toggle($(this).text().toLowerCase().indexOf(searchvalue) > -1)
  });

  // after filtering the rows, get the count of visible rows.
  var visiblerows = $('tr:visible').length - 1;

  // If the entire list of SKUs in the Location is not being shown and
  // user has given atleast 3 chars to search and
  // the given search value is not in the list already,
  if ((parseInt(numskus) >= 30) && ((searchvalue.length) > 3))
  // && (visiblerows == 0))
  {
    $("[data-rfname='RFFormAction']").val("GetSKUs");
    SkipInputValidationsAndSubmit();
  }
} // Inventory_MP_FilterValueEntered

//-----------------------------------------------------------------------------
//custom handler to validate Min/Max qty for SetupPicklane
function Inventory_MP_MinMaxQty(evt)
{
  var minimumqty = $("[data-rfname='MinQuantity']").val();
  var maximumqty = $("[data-rfname='MaxQuantity']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (parseInt(minimumqty) > parseInt(maximumqty))
  {
    message.Message.DisplayText = "Max qty should be greater than Min qty";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_MP_MinMaxQty

//-----------------------------------------------------------------------------
// function to assign the form action and submit form
function Inventory_MP_RefreshGrid(evt)
{
  $("[data-rfname='RFFormAction']").val("RefreshDataTable");
  SkipInputValidationsAndSubmit();
}

//-----------------------------------------------------------------------------
// When user selects the record we have to update the data entry fields with the
// values from the selected record
function Inventory_MP_RemoveInv_UpdateValues(tablerow)
{
    // If there is any previously highlighted row clear it
    $(".amf-form-datatable-row-highlight-tablet").removeClass();

    // highlight the user clicked row
    $(tablerow).first().addClass("amf-form-datatable-row-highlight-tablet");

    // Get the required values
    $("[data-rfname='LPNId']").val($($(tablerow).find("td")[12]).text());
    $("[data-rfname='SKUId']").val($($(tablerow).find("td")[13]).text());

    $("[data-rfname='SKU']").val($($(tablerow).find("td")[1]).text());
    $("[data-rfname='SKU']").focus();
} // Inventory_MP_RemoveInv_UpdateValues

//-----------------------------------------------------------------------------
//custom handler to set focus on SKU after selection of any of the options
function Inventory_MP_SelectOption_Onchange()
{
  //This is used to set focus to SKU when user checks or unchecks the options
  $("[data-rfname='SKU']").focus();
} // Inventory_MP_SelectOption_Onchange

//-----------------------------------------------------------------------------
// function t assign the value to RF Form action and will navigate user to 1st screen to scan Location
function Inventory_MP_Stop(evt)
{
  $("[data-rfname='RFFormAction']").val("Stop");
  SkipInputValidationsAndSubmit();
} // Inventory_MP_Stop

//-----------------------------------------------------------------------------
//custom handler to validate InvClass that is selected under ManagePicklane
function Inventory_MP_ValidateInvClass1(evt)
{
  var reasoncode = $("[data-rfname='InventoryClass1']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid Inventory Class";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_MP_ValidateInvClass1

//-----------------------------------------------------------------------------
//custom handler to validate ReasonCodes for AddInventory under ManagePicklane
function Inventory_MP_ValidateReasonCodes(evt)
{
  var reasoncode = $("[data-rfname='ReasonCode']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid Reason Code";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_MP_ValidateReasonCodes

//-----------------------------------------------------------------------------
//custom handler to validate selected options for ManagePicklane
function Inventory_MP_ValidateSelectedOptions(evt)
{
  var addsku = $("[data-rfname='ConfirmAddSKU']").prop('checked');
  var removesku = $("[data-rfname='ConfirmRemoveSKU']").prop('checked');
  var setuppicklane = $("[data-rfname='ConfirmSetupPicklane']").prop('checked');
  var addinventory = $("[data-rfname='ConfirmAddInventory']").prop('checked');
  var status = $("[data-rfname='m_LocationInfo_LocationStatus']").val();
  var sku = $("[data-rfname='SKU']").val();
  var numskus = $("[data-rfname='m_LocationInfo_NumSKUs']").val();
  var invclass = $("[data-rfname='m_InventoryClasses']").val();
  var locsubtype = $("[data-rfname='m_LocationInfo_LocationSubType']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  // Ensure SKU is given except when only option selected is setuppicklane
  if (((sku == null) || (sku == "") || (sku == undefined)) &&
      ((addsku || removesku || addinventory) == true))
  {
    message.Message.DisplayText = "SKU is required";
  }
  else
  // Check at least one option is selected
  if ((removesku == false) && (addsku == false) &&
      (setuppicklane == false) && (addinventory == false))
  {
    message.Message.DisplayText = "Please select at least one option";
  }
  else
  // Can only remove SKU if Location has at least one SKU setup already
  if ((removesku == true) && (numskus == 0))
  {
    message.Message.DisplayText = "There are no SKUs setup on the Picklane to remove";
  }
  else
  // For Empty location we need to select add SKU when there is no SKU present
  if ((addsku == false) && (numskus == 0))
  {
    message.Message.DisplayText = "Please add a SKU before attempting to perform other options";
  }
  else
  // No other option should be selected when RemoveSKU is selected
  if ((removesku == true) && ((addsku || setuppicklane || addinventory) == true))
  {
    message.Message.DisplayText = "Please select only Remove SKU. Cannot perform other functions along with removing SKU";
  }
  else
  // Add SKU leads to new screen if label code selecting is valid. User will not
  // get a chance to select Add Inventory option.So validating here itself
  if ((addsku == true) && (locsubtype == 'D') && (addinventory == false))
  {
    message.Message.DisplayText = "SKU can be added to dynamic picklane with inventory, please select Update Inventory as well";
  }

  // Assign values for the variables
  if (message.Message.DisplayText == null)
  {
    // Reset the values, as updates are made client side values have to be cleared
    $("[data-rfname='ConfirmAddSKU']").val(null);
    $("[data-rfname='ConfirmRemoveSKU']").val(null);
    $("[data-rfname='ConfirmSetupPicklane']").val(null);
    $("[data-rfname='ConfirmAddInventory']").val(null);

    // Assign values for checked options
    if (addsku == true)
      $("[data-rfname='ConfirmAddSKU']").val("Y");
    if (removesku == true)
      $("[data-rfname='ConfirmRemoveSKU']").val("Y");
    if (setuppicklane == true)
      $("[data-rfname='ConfirmSetupPicklane']").val("Y");
    if (addinventory == true)
      $("[data-rfname='ConfirmAddInventory']").val("Y");

    if ((addsku == true) && (invclass != ''))
    {
      $("[data-rfname='RFFormAction']").val("GetInvClasses");
    }

    return null; // caller expects null when there are no validation messages
  }
  else
    return message;

} // Inventory_MP_ValidateSelectedOptions

//-----------------------------------------------------------------------------
//custom handler to validate UoM for SetupPicklane and AddInventory under ManagePicklane
function Inventory_MP_ValidateUoM(evt)
{
  var reasoncode = $("[data-rfname='UoM']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  if (reasoncode == '*')
  {
    message.Message.DisplayText = "Please select a valid UoM";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Inventory_MP_ValidateUoM

//*****************************************************************************
//*************************** Transfer Loc Qty*********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// When TransferLocQty form is being shown, based upon whether LPN is single SKU
// or mixed SKU, the form has to be setup accordingly and this method does that.
function Inventory_TransferLocQty_OnShow()
{
  // get the numlpns value
  var numskus = $("[data-rfname='m_LocationInfo_NumSKUs']").val();

  // We need additional attributes for standard QIP panel, called the function to add them
  selector = "[data-rfname='NewUnits']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector, values);

  selector = "[data-rfname='NewUnits1']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector, values);

  // Generally validation handler settings are defined after form is rendered. In
  // this case as we added validation handler in form show, call the function to
  // define the settings
  VerifyFormForValidationSettings();

  // we need the next sequence only for single sku lpn
  if ((numskus > 1) || (numskus == null)  || (numskus == undefined) || (numskus == ""))
  {
      return;
  }

  // clear the inputs under input panel
  QuantityInputPanel_ClearForm();

  // get the table row
  var scannedentity = $("[data-rfname='m_LocationInfo_SKU']").val();
  var tablerow      = DataTableSKUDetails_GetTableRow(scannedentity);

  // fetch the required values
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  // set is between values for validating
  QuantityInputPanel_InitializeIsBetween(totalunits, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

  var storagetype  = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var selecteduom;

  // Initialize values for fields in the quantity input panel
  QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

} // Inventory_TransferLocQty_OnShow

//-----------------------------------------------------------------------------
// Validate the scanned entity highlight the row and set input  values for QIP(Quantity Input Panel)
function Inventory_TransferLocQty_OnSKUEnter(evt)
{
  /* Get the scanned entity */
  var scannedentity = $("[data-rfname='SKU']").val();

  // if the user has skipped entering the value, then assume that the user wishes to
  // skip entering the value and return later
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
      return;
  }

  // hide inputs in quantity input panel
  QuantityInputPanel_HideInputs();

  //Remove the previous highlighted row and hide all the inputs
  DataTableSKUDetails_ClearHighlightedRow();

  // Validates the scanned SKU and returns the table row if it is a valid SKU.
  // if it is not in the list, tablerow is not returned
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  if ($(tablerow).length == 0)
  {
    DisplayErrorMessage("Scanned SKU is not presesnt in the location");
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // Highlight the row which has the scanned entity and clear the inputs
  DataTableSKUDetails_HighlightRow(tablerow, scannedentity);
  QuantityInputPanel_ClearForm();

  // get all the values of the scanned SKU from the details table
  // any changes to the table structure would require changes here
  // fetch the required values
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  // set is between values for validating
  QuantityInputPanel_InitializeIsBetween(totalunits, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

  var storagetype  = $("[data-rfname='m_LocationInfo_StorageType']").val();
  var selecteduom;

  // Initialize values for fields in the quantity input panel
  QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

  // do not process any further
  evt.stopPropagation();
  evt.preventDefault();
  return;
} // Inventory_TransferLocQty_OnSKUEnter

//*****************************************************************************
//*************************** Transfer LPN Qty*********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// When TransferLPNQty form is being shown, based upon whether LPN is single SKU
// or mixed SKU, the form has to be setup accordingly and this method does that.
function Inventory_TransferLPNQty_OnShow()
{
  // get the numlpns value
  var numlines = $("[data-rfname='m_LPNInfo_NumLines']").val();

  // We need additional attributes for standard QIP panel, called the function to add them
  selector = "[data-rfname='NewUnits']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector, values);

  selector = "[data-rfname='NewUnits1']";
  values   = {"data-rfvalidateon":"FOCUSOUT","data-rfsubmitform":"false"};
  QuantityInputPanel_AddAttributes(selector, values);

  // Generally validation handler settings are defined after form is rendered. In
  // this case as we added validation handler in form show, call the function to
  // define the settings
  VerifyFormForValidationSettings();

  // we need the next sequence only for single sku lpn
  if ((numlines > 1) || (numlines == null) || (numlines == undefined) || (numlines == ""))
  {
      return;
  }

  if (numlines == 1)
  {
    // clear the inputs under input panel
    QuantityInputPanel_ClearForm();

    // Validates the scanned SKU and returns the table row if it is a valid SKU.
    // if it is not in the list, tablerow is not returned
    var scannedentity  = $("[data-rfname='m_LPNInfo_SKU']").val();
    var tablerow       = DataTableSKUDetails_GetTableRow(scannedentity);

    // get all the values of the scanned SKU from the details table
    // any changes to the table structure would require changes here
    var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

    // set is between values for validating
    QuantityInputPanel_InitializeIsBetween(totalunits, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

    var selecteduom  = inventoryuom.substring(0, 2);
    var storagetype  = "";

    // Initialize values for fields in the quantity input panel
    QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperinnerpack, innerpacksperlpn, unitsperlpn);
  }

} // Inventory_TransferLPNQty_OnShow

//-----------------------------------------------------------------------------
//custom handler to highlight the row and update the values
function Inventory_TransferLPNQty_OnSKUEnter(evt)
{
  /* Get the scanned entity */
  var scannedentity = $("[data-rfname='SKU']").val();

  // if the user has skipped entering the value, then assume that the user wishes to
  // skip entering the value and return later
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
      return;
  }

  //Remove the previous highlighted row and hide all the inputs in Quantity Input Panel
  DataTableSKUDetails_ClearHighlightedRow();
  QuantityInputPanel_HideInputs();

  // Validates the scanned SKU and returns the table row if it is a valid SKU.
  // if it is not in the list, tablerow is not returned
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  if ($(tablerow).length == 0)
  {
    DisplayErrorMessage("Scanned SKU is not associated with the lpn");
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // Highlight the row which has the scanned entity and clear inputs under input panel
  DataTableSKUDetails_HighlightRow(tablerow, scannedentity);
  QuantityInputPanel_ClearForm();

  // get all the values of the scanned SKU from the details table
  // any changes to the table structure would require changes here
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  // set is between values for validating
  QuantityInputPanel_InitializeIsBetween(totalunits, unitsperinnerpack, innerpacksperlpn, unitsperlpn);

  var selecteduom  = inventoryuom.substring(0, 2);
  var storagetype  = "";

  // Initialize values for fields in the quantity input panel
  QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperinnerpack, innerpacksperlpn, unitsperlpn);
  // do not process any further
  evt.stopPropagation();
  evt.preventDefault();
  return;
} // Inventory_TransferLPNQty_OnSKUEnter

//-----------------------------------------------------------------------------
// method to assign value to RFFormAction and submit on continue button click
function Inventory_TransferQty_Continue(evt)
{
  $("[data-rfname='RFFormAction']").val("ConfirmAndContinue");
  SkipInputValidationsAndSubmit();
} // Inventory_TransferQty_Continue

//*****************************************************************************
//************************* Transfer Picklane *********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
//custom handler to set focus to next input
function Inventory_TransferPicklane_ConfirmQtyCheckBox_Onchange()
{
   //This is used to set focus to Location when user checks or unchecks confirm reserve qty transfer
   $("[data-rfname='ToLocation']").focus();
}

//-----------------------------------------------------------------------------
//custom handler to execute complete function call
function Inventory_TransferPicklane_ConfirmReservedQtyValidation()
{
   var message = null;
   var QtyConfirmed = $("[data-rfname='ConfirmQty']").prop('checked');

   if (((QtyConfirmed == null) || (QtyConfirmed == "") || (QtyConfirmed == false) || (QtyConfirmed == undefined)))
   {
     message = {};
     message.Message = {};
     message.Message.DisplayText = "Please confirm the reserved quantity transfer to complete transfer picklane";
   }

   return message;
}
