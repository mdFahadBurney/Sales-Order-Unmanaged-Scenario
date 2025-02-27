@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Item Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_ITEM_SO as select from zso_item_mfb
association to parent ZI_HEADER_SO as _SOHeader on $projection.OrderNo = _SOHeader.OrderNo
composition[1..*] of ZI_WHSE_SO as _SOWhse
//association[1..*] to ZI_WHSE_SO as _SOWhse on $projection.ItemNo = _SOWhse.ItemNo
{
    key so_number as OrderNo,
    key item_no as ItemNo,
    material_no as MaterialNo,
    material_desc as MaterialDesc,
    @Semantics.amount.currencyCode: 'Currency'
    item_amt as ItemAmt,
    currency as Currency,
   // zso_item_mfb.itemL as LocalLastChangedAt,
    
 //   comments as Comments,
    /* Associations */
    _SOHeader
    , _SOWhse
}
