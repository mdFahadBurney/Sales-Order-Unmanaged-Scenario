@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Whse Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_WHSE_SO as select from zso_whse_mfb
association to parent ZI_ITEM_SO as _SOItem on  $projection.ItemNo = _SOItem.ItemNo
                                            and $projection.SoNumber = _SOItem.OrderNo
       association to ZI_HEADER_SO as _SOHeader on $projection.SoNumber = _SOHeader.OrderNo
{

    key whse_no as WarehouseNo,
    key so_number as SoNumber,
    key item_no as ItemNo,
    whse_address as WarehouseAddress,
   material_no as MaterialNo,
    @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'   
    quantity as Quantity,
   unit_of_measure as UnitOfMeasure,
    comments as Comments,
   // zso_whse_mfb.locallastchangedat as LocalLastChangedAt,

    /* Associations */
    _SOItem,
    _SOHeader
}
