//-----------------------------------------------------------------------------
$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

});

//-----------------------------------------------------------------------------
// After user scans a valid item and gives LPN, ReasonCode and disposition the
// details would have to be added to the table which is the repository of the
// items being returned and will be processed on confirmation
function Returns_AddItem(evt)
{
  // If the SKU has already been validated and determined that it is invalid
  // then we just need to return without doing anything
  var invalidentity = $("[data-rfname='SKU']").attr("invalid-entity");

  // If we have value for the above attribute we will not proceed further
  if (invalidentity == 'Y')
    return;

  // Get the scanned SKU and Qty
  var scannedsku    = $("[data-rfname='SKU']").val();
  var newqty        = $("[data-rfname='Quantity']").val();
  var disposition   = $("[data-rfname='Disposition']").val();
  var reasoncode    = $("[data-rfname='ReasonCode']").val();
  var iserror       = 0;

  // If SKU is not scanned by user raise error and focus on SKU
  if ((scannedsku == null) || (scannedsku == undefined) || (scannedsku == ""))
  {
    DisplayErrorMessage("Please scan a valid SKU and provide valid details to add the Item");
    $("[data-rfname='SKU']").focus();
    iserror = 1;
  }

  if (disposition === '*')
  {
    DisplayErrorMessage("Please select a disposition to proceed further");
    $("[data-rfname='Disposition']").focus();
    iserror = 1;
  }

  // As * is the 1st record, pass empty value as user did not select any reason
  if (reasoncode === '*')
  {
    DisplayErrorMessage("Please select a reason for the return");
    $("[data-rfname='ReasonCode']").focus();
    iserror = 1;
  }

  if (iserror == 1)
  {
    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // If SKU is scanned by user call method to add to the table
  if ((scannedsku != null) && (scannedsku != undefined) && (scannedsku != ""))
  {
    Returns_AddRecordToTable();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

} // Returns_AddItem

//-----------------------------------------------------------------------------
// Assuming that the SKU has already been validated and so just add the details
// to the table
function Returns_AddRecordToTable()
{
  // Get the scanned entities
  var scannedentity = $("[data-rfname='SKU']").val();
  var scannedlpn    = $("[data-rfname='LPN']").val();
  var quantity      = $("[data-rfname='Quantity']").val();
  var disposition   = $("[data-rfname='Disposition']").val();
  var reasoncode    = $("[data-rfname='ReasonCode']").val();
  var entityid      = "";
  var entitytype    = "";

  // we will fetch the values of scannedentityid and type only when user keyed in LPN/Location
  // Lets say user scanned an LPN/Location and SKU, again user scanned a SKU from list but did not
  // scan either LPN/Location, as we will still have values in these fields we need to ignore them.
  if ((scannedlpn != undefined) && (scannedlpn != "") && (scannedlpn != null))
  {
    entityid      = $("[data-rfname='m_ValidatedEntityId']").val();
    entitytype    = $("[data-rfname='m_ValidatedEntityType']").val();
  }

  // Json object
  var inputdata           = {};

  inputdata["UpdateType"] = FORMCONTENT_UPDATETYPE_ADD;
  inputdata["UpdateMode"] = FORMCONTENT_UPDATEMODE_BEFORE;

  // Process
  // Add the values to the table
  inputdata["EntityName"]   = "SKU";
  inputdata["ControlValue"] = [
                                {"SKU":scannedentity,
                                 "EntityKey":scannedlpn,
                                 "Quantity":quantity,
                                 "Reason":reasoncode,
                                 "Disposition":disposition,
                                 "EntityId":entityid,
                                 "EntityType":entitytype}
                              ];

  // Tabulate information that is given
  ChangeFormContent('.js-datatable-returns-returndetails', inputdata);

  // Update the total items scanned by user
  var returnqty = $("[data-rfjsname='ReturnQuantity']").text();
  totalreturnqty = parseInt(returnqty) + parseInt(quantity);
  $("[data-rfjsname='ReturnQuantity']").text(totalreturnqty);

  // Clear the inputs and set focus
  $("[data-rfname='SKU']").val(null);
  $("[data-rfname='LPN']").val(null);
  $("[data-rfname='SKU']").focus();

} // Returns_AddRecordToTable

//-----------------------------------------------------------------------------
// when user is done scanning all the items, user can confirm to post the
// returned items and may be create an RMA
function Returns_Confirm(evt)
{
  // Get the table rows
  var tablerows = $('.js-datatable-returns-returndetails').find("tbody tr");

  // If table has scanned entities, then process the returns
  if ((tablerows.length > 0))
  {
    SkipInputValidationsAndSubmit();
  }
  else
  // if user has not scanned any SKU
  if ((tablerows.length <= 0))
  {
    DisplayErrorMessage("Need to have at least one item returned to confirm");
    $("[data-rfname='SKU']").focus();
    return;
  }
} // Returns_Confirm

//-----------------------------------------------------------------------------
// This function is invoked before showing the form to user
function Returns_Confirm_OnShow()
{
  // Fetch values
  var scannedsku  = $("[data-rfname='m_ValidatedSKU']").val();
  var scannedlpn  = $("[data-rfname='m_LPN']").val();
  var scanlpn     = $("[data-rfname='m_ScanningLPNOptional']").val();
  // Initialize variables
  var returndata         = $("[data-rfname='m_ReturnData']").val();
  var returndatalist     = {};
  var returndatalistlen  = 0;
  //var inputdata          = {};
  //var values          = {};

  // Continue to tabulate these, only if the above nodal data exists
  if ((returndata != undefined) && (returndata != ""))
  {
    returndatalist    = JSON.parse($("[data-rfname='m_ReturnData']").val());
    returndatalistlen = $(returndatalist["ReturnData"]["ReturnTable"]).length;

    // If the object has only 1 array, convert that into json object array
    if (returndatalistlen == 1)
    {
      var returndatalistarray = [];
      returndatalistarray.push(returndatalist.ReturnData.ReturnTable);
      returndatalist.ReturnData.ReturnTable = returndatalistarray;
    }

  // loop through the list
  for (len = 0; len < returndatalistlen; len++)
  {
    Returns_Confirm_TableInsertUpdate(returndatalist["ReturnData"]["ReturnTable"][len]["EntityKey"],
                                      returndatalist["ReturnData"]["ReturnTable"][len]["SKU"],
                                      returndatalist["ReturnData"]["ReturnTable"][len]["Quantity"],
                                      returndatalist["ReturnData"]["ReturnTable"][len]["Reason"],
                                      returndatalist["ReturnData"]["ReturnTable"][len]["Disposition"],
                                      returndatalist["ReturnData"]["ReturnTable"][len]["EntityId"],
                                      returndatalist["ReturnData"]["ReturnTable"][len]["EntityType"],
                                      FORMCONTENT_UPDATETYPE_ADDUPDATE,
                                      FORMCONTENT_UPDATEMODE_BEFORE)
    }
  } // end of for loop

  if ((scannedsku == null) || (scannedsku == undefined) || (scannedsku == ""))
  {
    $("[data-rfname='SKU']").focus();
  }
  if ((scannedsku != undefined) && (scannedsku != "") && (scannedlpn == ""))
  {
    $("[data-rfname='SKU']").val(scannedsku);
    $("[data-rfname='Quantity']").focus();
  }
  else
  if ((scannedlpn != undefined) && (scannedlpn != ""))
  {
    $("[data-rfname='SKU']").val(scannedsku);
    $("[data-rfname='LPN']").val(scannedlpn);
    $("[data-rfname='Disposition']").focus();
  }

  if ((scanlpn == 'Y') && (scannedsku != undefined) && (scannedsku != ""))
  {
    // Setup for Adding the SKU to table
    $(document).find(".js-returns-additem").trigger("click");
  }

  SetFocusFlagValue(true);
} // Returns_Confirm_OnShow

//-----------------------------------------------------------------------------
// Function to tabulate data on the data table
function Returns_Confirm_TableInsertUpdate(entitykey, sku, quantity, reasoncode, disposition, entityid, entitytype, updatetype, updatemode)
{
  // form related
  var tableelement      = ".js-datatable-returns-returndetails";
  // Json objects
  var inputdata         = {};

  // Process
  // Add the values to the table
  inputdata["EntityName"]   = "SKU";
  inputdata["ControlValue"] = [
                                {"SKU":sku,
                                 "EntityKey":entitykey,
                                 "Quantity":quantity,
                                 "Reason":reasoncode,
                                 "Disposition":disposition,
                                 "EntityId":entityid,
                                 "EntityType":entitytype}
                              ];

  inputdata["UpdateType"]   = updatetype;
  inputdata["UpdateMode"]   = updatemode;

  // Tabulate information that is given
  ChangeFormContent(tableelement, inputdata);

} // Returns_Confirm_TableInsertUpdate

//-----------------------------------------------------------------------------
// Custom handler to populate the list of Entities to be sent as inputXML
// Output json object from this function
function Returns_PopulateEntityInput()
{
  // Define an empty array to store json objects
  var jsonarray  = [];

  // Find table header columns
  var tableheaders = $("[data-rfrecordname='ReturnTable']").find("thead tr th");

  // TODO Code is not readable. could be made simpler with some changes
  // TODO let us leave it at that for now here. we can revisit, if need be.
  // Loop through the body elements and store each row as json object into the array declared above
  var tablerows = $("[data-rfrecordname='ReturnTable']").find("tbody tr").each(function(index)
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
  jsonresult["ReturnTable"] = jsonarray;

  $("[data-rfname='ReturnData']").val(JSON.stringify(jsonresult));
} // Returns_PopulateEntityInput

//-----------------------------------------------------------------------------
// method to check if scanned lpn/location that the returned item is being
// placed into is valid or not
function Returns_Validate_Entity(evt)
{
  // Get the scanned entity
  var scannedentity = $("[data-rfname='LPN']").val();

  // if the mode is not defined or scan mode then the next set of function is not needed
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
    return;
  }

  $("[data-rfname='RFFormAction']").val("ValidateEntity");
  SkipInputValidationsAndSubmit();

} // Returns_Validate_Entity

//-----------------------------------------------------------------------------
// method to check if scanned sku is present in shipped details, if not present
// will assign a value to form action to validate whether it is valid or not
function Returns_Validate_SKUOrUPC(evt)
{
  // Clear the invalid-entity attribute as we will be validating it now
  $("[data-rfname='SKU']").removeAttr("invalid-entity");

  // Get the scanned entity and lpn scan optional or not
  var scannedentity = $("[data-rfname='SKU']").val();
  var scanlpn       = $("[data-rfname='m_ScanningLPNOptional']").val();

  // if the mode is not defined or scan mode then the next set of function is not needed
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
    return;
  }

  // we will get table row
  var tablerow  = DataTableSKUDetails_GetTableRow(scannedentity);

  if ($(tablerow).length == 0)
  {
    // assign value to RFFormAction and submit the form
    $("[data-rfname='RFFormAction']").val("ValidateSKU");
    SkipInputValidationsAndSubmit();
  }
  else
  if ($(tablerow).length > 0)
  {
    var sku = $($(tablerow).find("td")[7]).text();
    $("[data-rfname='SKU']").val(sku);
  }

  // if scanning an LPN is optional then add the SKU to grid
  if (scanlpn == 'Y')
  {
    // Setup for Adding the SKU to table
    $(document).find(".js-returns-additem").trigger("click");
    //$("[data-rfname='SKU']").focus();
    //$("[data-rfname='Quantity']").focus();
    //SetFocusbyTabOrder();

    // We need to add attribute to prevent validating again in AddItem. Without this, if
    // if user keyed in a SKU and clicked on Add Item we would validate it again
    //var selector = "[data-rfname='SKU']";
    //var values   = {"invalid-entity":"Y"};
    //QuantityInputPanel_AddAttributes(selector,values)

    //$("[data-rfname='SKU']").focus();
    // do not process any further
    //evt.stopPropagation();
    //evt.preventDefault();
    //return;
  }

  //SetFocusFlagValue(true);
} // Returns_Validate_SKUOrUPC

//-----------------------------------------------------------------------------
//custom handler to execute Start Returns function call
function Returns_ReturnRMA_Highlight(evt)
{
  /* Highlight current pick task's row in the data table */
  var scannedsku = $("[data-rfname='SKU']").val();

  //Remove the previous highlighted row
  $(".amf-form-datatable-row-highlight-tablet").removeClass();

  if ((scannedsku != null) && (scannedsku != undefined) && (scannedsku != ''))
  {
    // get the table row information
    var tableRow = $(document).find('.js-datatable-returns-details tr').filter(function () {
    return ($(this).find('td').eq(0).text() === scannedsku); }).closest("tr");

    //Highlight the row which has the scanned SKU
    $(tableRow).find("td").filter(function () {
    return ($(this).text() === scannedsku); }).closest("tr").addClass("amf-form-datatable-row-highlight-tablet");
    if ($(document).find(".amf-form-datatable-row-highlight-tablet").length > 0)
    {
      $(document).find(".amf-form-datatable-row-highlight-tablet")[0].scrollIntoView();
    }
  }
} // Returns_ReturnRMA_Highlight
