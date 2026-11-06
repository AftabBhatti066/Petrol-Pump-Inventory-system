'use strict';
const db = require('../config/db');
const service = require('../services/meterFlow').createService(db);
const respond = handler => async (req,res) => {
    try {
        const data=await handler(req);
        res.set('Cache-Control','no-store');
        res.json({status:'Success',...data});
    } catch(error) {
        console.error('Meter flow:',error.message);
        const migrationMissing=error.code==='42P01';
        res.status(error.status || 500).json({status:'Error',message:migrationMissing
            ? 'Run sql/01_meter_flow.sql before using this page.'
            : error.status ? error.message : 'Database operation failed. Nothing from this save was committed. Please retry.'});
    }
};
exports.getDay=respond(req=>service.getDay(req.query.userId,req.query.date));
exports.initialize=respond(req=>service.initialize(req.body));
exports.saveDay=respond(req=>service.saveDay(req.body));
exports.getLatestDate=respond(async req=>{
    const day=await service.getDay(req.query.userId);
    return {latest_date:day.last_saved_date || day.latest_legacy_date || null,working_date:day.default_date,setup_required:day.setup_required};
});
// Compatibility GET endpoints for callers outside this page.
exports.getAllReadings=respond(async req=>{
    const day=await service.getDay(req.query.userId,req.query.date);
    if(day.setup_required) return {data:[],setup_required:true};
    const data=Object.entries(day.opening.nozzles).map(([nozzle_name,opening_reading])=>({
        nozzle_name,fuel_type:nozzle_name.startsWith('Diesel')?'Diesel':'Super',opening_reading,
        closing_reading:day.inputs.nozzles[nozzle_name],liters_sold:day.snapshot?.nozzle_sales[nozzle_name]||0,reading_date:day.date
    })); return {data};
});
exports.getTankStock=respond(async req=>{
    const day=await service.getDay(req.query.userId,req.query.date);
    return {setup_required:day.setup_required,data:day.setup_required?[]:Object.entries(day.opening.fuel).map(([fuel_type,current_stock])=>({fuel_type,current_stock}))};
});
exports.getLubricantStock=respond(async req=>{
    const day=await service.getDay(req.query.userId,req.query.date);
    return {setup_required:day.setup_required,data:day.setup_required?[]:day.items.map(item_name=>({item_name,current_stock:day.opening.lubricants[item_name],purchase_price:day.rates.lubricants[item_name],shift_sales_deduct:0}))};
});
exports.getRates=respond(async req=>{
    const day=await service.getDay(req.query.userId,req.query.date);
    return {data:day.setup_required?[]:Object.entries(day.rates.fuel).map(([product_type,purchase_price])=>({product_type,purchase_price}))};
});
exports.legacyWrite=(req,res)=>res.status(409).json({status:'Error',message:'Refresh Meter Reading and use Save & Close Day. Individual writes have been replaced by one atomic day save.'});
