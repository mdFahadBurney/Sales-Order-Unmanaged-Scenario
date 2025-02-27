@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Warehouse Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_WHSE_SO as projection on ZI_WHSE_SO
{
        @Consumption.valueHelpDefinition: [{ entity:{name: 'ZI_WHSE_NUMBER_VH', element: 'Value' } }]
    key WarehouseNo,
    key SoNumber,
    key ItemNo,
    WarehouseAddress,
    MaterialNo,
    @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
    Quantity,
       @Consumption.valueHelpDefinition: [{ entity:{name: 'I_UnitOfMeasureStdVH', element: 'UnitOfMeasure' } }]
    UnitOfMeasure,
    Comments,
   // LocalLastChangedAt,
    /* Associations */
    _SOHeader : redirected to  ZC_HEADER_SO,
    _SOItem : redirected to parent ZC_ITEM_SO
}
