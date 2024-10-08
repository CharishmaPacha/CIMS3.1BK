$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

  // This is a key press event to filter value in Order packing screen
  $("[data-rfname='FilterValue']").on("keyup", function() {
    var searchvalue = $(this).val().toLowerCase();
    Packing_OrderPacking_FilterValueEntered(searchvalue);
  });

});

//-----------------------------------------------------------------------------
// This method is used to get the quantity values of the SKU (tableRow) being packed
function PackingDetails_GetQtyValues(tableRow)
{
  // get current packed and topack qty
  var toPackqty = $($(tableRow).find("td")[4]).text();
  var packedQty = $($(tableRow).find("td")[5]).text();

  // ParseInt to convert to integer
  toPackqty = parseInt(toPackqty);
  packedQty = parseInt(packedQty);

  return [toPackqty, packedQty];
} // PackingDetails_GetQtyValues

//-----------------------------------------------------------------------------
// This method is used to get the several SKU attributes of the SKU (tableRow) being packed
function PackingDetails_GetSKUValues(tableRow)
{
  var sku            = $($(tableRow).find("td")[0]).text();
  var skuDescription = $($(tableRow).find("td")[1]).text();
  var UPC            = $($(tableRow).find("td")[7]).text();
  var sku1           = $($(tableRow).find("td")[10]).text();
  var sku2           = $($(tableRow).find("td")[11]).text();
  var sku3           = $($(tableRow).find("td")[12]).text();
  var sku4           = $($(tableRow).find("td")[13]).text();
  var sku5           = $($(tableRow).find("td")[14]).text();
  var skuImageUrl    = $($(tableRow).find("td")[20]).text();

  return [sku, skuDescription, UPC, sku1, sku2, sku3, sku4, sku5, skuImageUrl];
} // DataTableSKUDetails_GetSKUValues

//-----------------------------------------------------------------------------
// this method checks for SKU/UPC/Barcode/AlternateSKU and will fetch the table row index
function PackingDetails_GetTableRow(scannedSKU)
{
  // get the table row information
  var tableRow = $(document).find('.js-datatable-packing-packlist tr').filter(function () {
  return ($(this).find('td').eq(0).text() === scannedSKU); }).closest("tr");

  if ($(tableRow).length == 0) // check if user scanned UPC
    {
      tableRow = $(document).find('.js-datatable-packing-packlist tr').filter(function () {
      return ($(this).find('td').eq(7).text() === scannedSKU); }).closest("tr");
    }

  if ($(tableRow).length == 0) // check if user scanned Barcode
    {
      tableRow = $(document).find('.js-datatable-packing-packlist tr').filter(function () {
      return ($(this).find('td').eq(8).text() === scannedSKU); }).closest("tr");
    }

  if ($(tableRow).length == 0) // check if user scanned AlternateSKU
    {
      tableRow = $(document).find('.js-datatable-packing-packlist tr').filter(function () {
      return ($(this).find('td').eq(9).text() === scannedSKU); }).closest("tr");
    }

  return tableRow;
} // PackingDetails_GetTableRow

//-----------------------------------------------------------------------------
// Highlight the SKU that is being packed
function PackingDetails_HighlightRow(tableRow)
{
  // Remove the previous highlighted row in to-pack-list
  $(".amf-form-datatable-row-highlight-tablet").removeClass();

  // If SKU is found, then highlight it
  if ((tableRow != null) && (tableRow != undefined) && (tableRow != ''))
  {
    // Highlight the row which has the scanned SKU/UPC/Barcode/AlternateSKU
    $(tableRow).addClass("amf-form-datatable-row-highlight-tablet");
    $(document).find(".amf-form-datatable-row-highlight-tablet")[0].scrollIntoView();
  }
} // PackingDetails_HighlightRow

//-----------------------------------------------------------------------------
// When all validations have passed and it is confirmed that user can pack the
// given quantity, we confirm the same by updating the PackingDetails. This
// table will be send back to SQL later as confirmation of SKU and Qtys packed
// in the carton
function PackingDetails_UpdateQtyPacked(tableRow, packQty)
{
  var toPackQtyCellIndex = 4;
  var qtyPackedCellIndex = 5;

  var newPackedqty;
  var newtoPackqty;

  // get the current values in the table for the table row
  var packedQty = $($(tableRow).find("td")[qtyPackedCellIndex]).text();
  var toPackqty = $($(tableRow).find("td")[toPackQtyCellIndex]).text();

  //verify the packedqty value
  if (packedQty == 0)  // Packed Qty will be 0 if nothing packed against that SKU earlier
    newPackedqty = packQty;
  else
    newPackedqty = parseInt(packedQty) + parseInt(packQty);

  // calculate the new toPackqty
  newtoPackqty = parseInt(toPackqty) - parseInt(packQty);

  // assign value to packedQty and toPackqty
  $($(tableRow).find("td")[toPackQtyCellIndex]).text(newtoPackqty);
  $($(tableRow).find("td")[qtyPackedCellIndex]).text(newPackedqty);

  return newtoPackqty;

} // PackingDetails_UpdateQtyPacked

//-----------------------------------------------------------------------------
// function is invoked when user intends to close the carton. It checks for packed qty,
// if nothing packed then it raises an error otherwise will submit
function Packing_ConfirmPackOrder(evt)
{
  // Check if there are any lines in the packlist with packedqty > 0
  var isPacked = $(document).find('.js-datatable-packing-packlist tr').filter(function () {
  return ($(this).find('td').eq(5).text() > 0); }).closest("tr").index();

  // if there were no units packed at all, then raise an error
  if (isPacked < 0)
  {
    DisplayErrorMessage("Please pack atleast 1 unit");
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  /* Everything successful.. submit */
  $("form").submit();
} // Packing_ConfirmPackOrder

//-----------------------------------------------------------------------------
// If a valid SKU has been given then pack the given SKU
function Packing_OnSKUEnter()
{
  var scannedSKU = $("[data-rfname='SKU']").val();

  // If there is no SKU, then do nothing. Validation will happen when item is packed
  if ((scannedSKU == null) || (scannedSKU == undefined) || (scannedSKU == ''))
    return;

  // If there is a SKU, but the quantity is not valid, then prompt user to enter the
  // quantity, no error should be raised that qty is missing, as user may first enter
  // the SKU and then the quantity
  if (!Packing_ValidateQty(false))
    return;

  // Call the button click method if we have both SKU and Quantity
  $(document).find(".js-packing-confirmsku").trigger("click");
} // Packing_OnSKUEnter

//-----------------------------------------------------------------------------
// Function to validate if the qty to pack is valid.
// if raiseerror is true, then an error would be displayed to user
// if raiseerror is false, then it would be silent and just prompt user to enter the qty
function Packing_ValidateQty(raiseerror)
{
  var isvalid = true;

  // Get the pack quantity
  var packQty = $("[data-rfname='Quantity']").val();
  packQty = parseInt(packQty);

  // If qty to pack is not specified or invalid, then focus on it for user to enter a valid qty
  if ((packQty < 1) || (isNaN(packQty)))
  {
    isvalid = false;

    // if raiseerror, then display error to user
    if (raiseerror)
    {
      DisplayErrorMessage("Please specify the quantity for the item being packed");
      $("[data-rfname='Quantity']").val(1);
      $("[data-rfname='Quantity']").focus();

      // do not process any further
      evt.stopPropagation();
      evt.preventDefault();
    }
    else
    // if not raiserror, then be silent and just prompt user to enter a valid qty
    {
      $("[data-rfname='Quantity']").focus();
    }
  }

  return (isvalid);
} // Packing_ValidateQty


//-----------------------------------------------------------------------------
// This method filters the value and shows rows with value entered by the
// user. If no matches are found then nothing will get displayed in table
function Packing_OrderPacking_FilterValueEntered(searchvalue)
{
  $(".js-datatable-packing-packlist tbody tr").filter(function() {
    $(this).toggle($(this).text().toLowerCase().indexOf(searchvalue) > -1)
  });

} // Packing_OrderPacking_FilterValueEntered

//-----------------------------------------------------------------------------
// This is invoked when user is confirming to pack an item. i.e qty and SKU
// have been given and user is confirming that that many units of the SKU
// are being packed into the current carton
function Packing_ScanPackItem(evt)
{
  // fetch the SKU and qty to be packed
  var scannedSKU = $("[data-rfname='SKU']").val();
  var packQty = $("[data-rfname='Quantity']").val();
  packQty = parseInt(packQty);

  // If the quantity is not valid, then set focus on Qty and exit
  if (!Packing_ValidateQty(true))
    return;

  // If SKU is missing, then set focus on it and exit
  if ((scannedSKU == null) || (scannedSKU == undefined) || (scannedSKU == ''))
  {
    // DisplayErrorMessage("SKU is required and cannot be empty");
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // get the table row index
  var tableRow = PackingDetails_GetTableRow(scannedSKU);

  // If user scanned a SKU which is not present in list then validate
  if (tableRow.length < 1)
  {
    DisplayErrorMessage("SKU is not present in the list");
    $("[data-rfname='SKU']").val(null);
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // Highlight the SKU being packed
  PackingDetails_HighlightRow(tableRow);

  // Get the SKU attributes
  var [sku, skuDescription, UPC, sku1, sku2, sku3, sku4, sku5, skuImageUrl] = PackingDetails_GetSKUValues(tableRow);

  // Get the toPack and packedQty values
  var [toPackqty, packedQty] = PackingDetails_GetQtyValues(tableRow);

  // If toPackqty is 0 then ask user to scan other SKU
  if (toPackqty == 0)
  {
    DisplayErrorMessage("Packed all units against SKU " + sku + ", please scan another SKU");
    $("[data-rfname='SKU']").val(null);
    $("[data-rfname='Quantity']").val(1);
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // Check whether the scanned qty is greater than required qty
  if (packQty > toPackqty)
  {
    DisplayErrorMessage("Cannot pack " + packQty + " units, only " + toPackqty + " unit(s) of SKU " +
                        sku + " remain to be packed");
    $("[data-rfname='Quantity']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // Update the Packing Details table with the qty packed of the scanned SKU
  var newtoPackqty = PackingDetails_UpdateQtyPacked (tableRow, packQty);

  // Update the total items remaining to be packed by subtracting the units just packed
  var itemsRemaining = $("[data-rfjsname='RemainingUnitsToPack']").text();
  itemsRemaining = parseInt(itemsRemaining) - parseInt(packQty);
  $("[data-rfjsname='RemainingUnitsToPack']").text(itemsRemaining);

  // Reset for the next item
  $("[data-rfname='SKU']").val(null);
  $("[data-rfname='Quantity']").val(1);
  $("[data-rfname='SKU']").focus();

  // Show info of the SKU just packed
  Packing_ShowPackedSKUInfo (tableRow);

  if (newtoPackqty == 0)
    DisplaySuccessMessage("Packed all units of " + scannedSKU);
  else
    DisplaySuccessMessage("Packed " + packQty + " unit(s) of SKU " + scannedSKU);

} // Packing_ScanPackItem

//-----------------------------------------------------------------------------
// Custom handler to populate the list of Entities to be sent as inputXML
// Output json object from this function
function Packing_PopulateEntityInput()
{
  // Define an empty array to store json objects
  var jsonarray  = [];

  // Find table header columns
  var tableheaders = $("[data-rfrecordname='CartonDetails']").find("thead tr th");

  // TODO Code is not readable. could be made simpler with some changes
  // TODO let us leave it at that for now here. we can revisit, if need be.
  // Loop through the body elements and store each row as json object into the array declared above
  var tablerows = $("[data-rfrecordname='CartonDetails']").find("tbody tr").each(function(index)
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
  jsonresult["CartonDetails"] = jsonarray;

  $("[data-rfname='PackingCarton']").val(JSON.stringify(jsonresult));
} // Packing_PopulateEntityInput

//-----------------------------------------------------------------------------
// Show the details of the SKU that is just packed
function Packing_ShowPackedSKUInfo(tableRow)
{
  // fetch the required values
  var [sku, skuDescription, UPC, sku1, sku2, sku3, sku4, sku5] = PackingDetails_GetSKUValues(tableRow);

  // Show the SKU info that is packed
  $('.js-packing-skuinfo').removeClass('hidden');

  $("[data-rfjsname='SKU']").text(sku);
  $("[data-rfjsname='SKUDescription']").text(skuDescription);
  $("[data-rfjsname='UPC']").text(UPC);
  $("[data-rfjsname='sku1']").text(sku1);
  $("[data-rfjsname='sku2']").text(sku2);
  $("[data-rfjsname='sku3']").text(sku3);
  $("[data-rfjsname='sku4']").text(sku4);
  $("[data-rfjsname='sku5']").text(sku5);

  //$(document).find(".js-packing-image").attr("src", "https://obermeyer-acquia-prod-env-files.s3.us-west-2.amazonaws.com/public/styles/product_detail/public/products/photos/"+image);

} // Packing_ShowPackedSKUInfo
