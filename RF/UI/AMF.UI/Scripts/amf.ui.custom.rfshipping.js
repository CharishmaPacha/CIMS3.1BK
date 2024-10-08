//-----------------------------------------------------------------------------
$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

  // This is a key press event to filter value in LPN Reservation
  $("[data-rfname='FilterValue']").on("keyup", function() {
    var searchvalue = $(this).val().toLowerCase();
    Shipping_LoadInquiry_FilterValueEntered(searchvalue);
  });

});
//-----------------------------------------------------------------------------
// function to check for scanned entity in the list, if not present will add
function Shipping_CaptureSerialNo_AddToList(evt)
{
  // Get the user scanned/entered values
  var serialno  = $("[data-rfname='SerialNo']").val();

  if ((serialno == null) || (serialno == undefined) || (serialno == ""))
  {
    $("[data-rfname='SerialNo']").focus();
    return;
  }

  // Json object
  var inputdata           = {};
  var isserialnoscanned   = 0; // boolean value: true if scanned, false if not scanned

  // Set the flag to true if the entity was already scanned earlier
  isserialnoscanned  = CheckTableEntry('.js-datatable-shipping-captureserialno', serialno);

  if (isserialnoscanned)
  {
    DisplayErrorMessage("Serial No is already scanned/associated");
    $("[data-rfname='SerialNo']").val(null);
    $("[data-rfname='SerialNo']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }
  else // New scan: Adds a new row in the data table
  {
    inputdata["UpdateType"] = FORMCONTENT_UPDATETYPE_ADD;
    inputdata["UpdateMode"] = FORMCONTENT_UPDATEMODE_BEFORE;
  }

  // Process
  // Add the values to the table
  inputdata["EntityName"]   = "SerialNo";
  inputdata["ControlValue"] = [
                                {"SerialNo":serialno,
                                 "Random":Math.random()}
                              ];

  $("[data-rfname='SerialNo']").val(null);
  $("[data-rfname='SerialNo']").focus();

  // Tabulate serialno that is scanned
  ChangeFormContent('.js-datatable-shipping-captureserialno', inputdata);

  //var tableRow = $(document).find('.js-datatable-shipping-captureserialno').filter(function () {
  //return ($(this).find('td').eq(0).text() === serialno); }).closest("tr");

  // Remove the previous highlighted row
  //$(".amf-form-datatable-row-highlight-tablet").removeClass();

  // Highlight the row
  //$(tableRow).addClass("amf-form-datatable-row-highlight-tablet");
 // $(document).find(".amf-form-datatable-row-highlight-tablet")[0].scrollIntoView();
} // Shipping_CaptureSerialNo_AddToList

//-----------------------------------------------------------------------------
// confirm the action based on option selected
function Shipping_CaptureSerialNo_Confirm(evt)
{
  // Get the table rows
  var tablerows = $('.js-datatable-shipping-captureserialno').find("tbody tr");

  // If table has scanned entities, then proceed
  if ((tablerows.length > 0))
  {
  }
  else
  // if user has not scanned any serialnos and confirms the action, then throw an error
  if ((tablerows.length <= 0))
  {
    DisplayErrorMessage("Please scan atleast on serial no to confirm");
    $("[data-rfname='SerialNo']").val(null);
    $("[data-rfname='SerialNo']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // Check which radio button is checked by user
  var confirmadd     = $("[data-rfname='ConfirmAdd']").prop('checked');
  var confirmreplace = $("[data-rfname='ConfirmReplace']").prop('checked');
  var confirmclear   = $("[data-rfname='ConfirmClear']").prop('checked');
  var confirmdelete  = $("[data-rfname='ConfirmDelete']").prop('checked');

  // Assign value for checked option
  if (confirmadd == true)
    $("[data-rfname='Option']").val("A");
  if (confirmreplace == true)
    $("[data-rfname='Option']").val("R");
  if (confirmclear == true)
    $("[data-rfname='Option']").val("C");
  if (confirmdelete == true)
    $("[data-rfname='Option']").val("D");

  // Skip all the validations and submit the form
  SkipInputValidationsAndSubmit();
} // Shipping_CaptureSerialNo_Confirm

//-----------------------------------------------------------------------------
// This is a on show method, where we will do some form related updates
function Shipping_CaptureSerialNo_OnShow()
{
  // Get the validated LPN value
  var lpn = $("[data-rfname='m_LPNInfo_LPN']").val();

  if ((lpn == null) || (lpn == undefined) || (lpn == ""))
    return;

  // show the radio group
  $('.amf-datacard-Radiobuttons-SelectOption').removeClass('hidden');

  // set the default check to add
  $("#Add").prop("checked", true);
  $("#Replace").prop("disabled", true);
  $("#Delete").prop("disabled", true);

} // Shipping_CaptureSerialNo_OnShow

//-----------------------------------------------------------------------------
// Custom handler to populate the list of Entities to be sent as inputXML
// Output json object from this function
function Shipping_CaptureSerialNo_PopulateEntityInput()
{
  // Define an empty array to store json objects
  var jsonarray  = [];

  // Find table header columns
  var tableheaders = $("[data-rfrecordname='SerialNo']").find("thead tr th");

  // TODO Code is not readable. could be made simpler with some changes
  // TODO let us leave it at that for now here. we can revisit, if need be.
  // Loop through the body elements and store each row as json object into the array declared above
  var tablerows = $("[data-rfrecordname='SerialNo']").find("tbody tr").each(function(index)
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
  jsonresult["SerialNo"] = jsonarray;

  $("[data-rfname='SerialNos']").val(JSON.stringify(jsonresult));
} // Shipping_CaptureSerialNo_PopulateEntityInput

//-----------------------------------------------------------------------------
// Uncheck other radio buttons
function Shipping_CaptureSerialNo_SelectOption_Add(evt)
{
  $("#Add").prop("checked", true);

  $("#Clear").prop("checked", false);

  $("[data-rfname='SerialNo']").focus();
} // Shipping_CaptureSerialNo_SelectOption_Add

//-----------------------------------------------------------------------------
// Uncheck other radio buttons
function Shipping_CaptureSerialNo_SelectOption_Clear(evt)
{
  $("#Clear").prop("checked", true);

  $("#Add").prop("checked", false);

  $("[data-rfname='SerialNo']").focus();
} // Shipping_CaptureSerialNo_SelectOption_Add

//-----------------------------------------------------------------------------
// This method filters the value and shows rows with value entered by the
// user. If no matches are found then nothing will get displayed in table
function Shipping_LoadInquiry_FilterValueEntered(searchvalue)
{
  $(".js-datatable-load-details tbody tr").filter(function() {
    $(this).toggle($(this).text().toLowerCase().indexOf(searchvalue) > -1)
  });

} // Shipping_LoadInquiry_FilterValueEntered
