'use strict';
const FUELS = ['Diesel', 'Super'];
const NOZZLES = ['Diesel (N1)', 'Diesel (N2)', 'Diesel (N3)', 'Diesel (N4)', 'Super (N1)', 'Super (N2)'];
const DEFAULT_LUBRICANTS = ['T 2 20Ltrs', 'Balize .75', 'Balize 1Ltrs', 'Cariant 3Ltrs', 'Cariant 4ltrs', 'Deo 6000 4Ltrs', 'Deo 6000 10Ltrs', 'Deo 8000 4Ltrs', 'Deo 8000 10Ltrs'];
function fail(message, status = 400) { const e = new Error(message); e.status = status; throw e; }
function date(value) {
    if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) fail('Valid YYYY-MM-DD date required.');
    const d = new Date(value + 'T00:00:00Z');
    if (!Number.isFinite(d.getTime()) || d.toISOString().slice(0, 10) !== value || value < '2000-01-01' || value > '9998-12-31') fail('Invalid working date.');
    return value;
}
function nextDate(value) { const d = new Date(date(value) + 'T00:00:00Z'); d.setUTCDate(d.getUTCDate() + 1); return d.toISOString().slice(0, 10); }
function number(value, label, integer = false) {
    if (value === null || value === undefined || value === '' || typeof value === 'boolean') fail(label + ' required.');
    const n = Number(value);
    if (!Number.isFinite(n) || n < 0 || n > 999999999 || (integer && !Number.isInteger(n))) fail(label + ': valid non-negative ' + (integer ? 'whole number' : 'number') + ' required.');
    if (Math.abs(n * 100 - Math.round(n * 100)) > 0.0001) fail(label + ': maximum 2 decimal places.');
    return Math.round(n * 100) / 100;
}
const round = n => Math.round((n + Number.EPSILON) * 100) / 100;
function normalizeBaseline(raw, items) {
    const b = { nozzles: {}, fuel: {}, lubricants: {} };
    for (const n of NOZZLES) b.nozzles[n] = number(raw?.nozzles?.[n], n + ' opening');
    for (const f of FUELS) b.fuel[f] = number(raw?.fuel?.[f], f + ' actual tank stock');
    for (const name of items) b.lubricants[name] = number(raw?.lubricants?.[name], name + ' opening', true);
    return b;
}
function normalizeInputs(raw, items) {
    const out = { nozzles: {}, fuel: {}, lubricants: {} };
    for (const n of NOZZLES) out.nozzles[n] = number(raw?.nozzles?.[n], n + ' closing');
    for (const f of FUELS) {
        const rec = raw?.fuel?.[f];
        const qty = number(rec?.qty, f + ' receipt');
        const amount = number(rec?.amount, f + ' receipt amount');
        if ((qty === 0 && amount !== 0) || (qty > 0 && amount <= 0)) fail(f + ': enter a positive receipt amount for received litres; zero litres requires zero amount.');
        out.fuel[f] = { qty, amount };
    }
    for (const name of items) {
        const rec = raw?.lubricants?.[name];
        const qty = number(rec?.qty, name + ' receipt', true);
        const sales = number(rec?.sales, name + ' sales', true);
        const rate = number(rec?.rate, name + ' purchase rate');
        if (qty > 0 && rate <= 0) fail(name + ': purchase rate required.');
        const amount = round(qty * rate);
        if (amount > 999999999) fail(name + ': amount too large.');
        out.lubricants[name] = { qty, sales, rate, amount };
    }
    return out;
}
function calculate(opening, inputs, workDate) {
    const snapshot = { opening: structuredClone(opening), closing: structuredClone(opening), sales: { Diesel: 0, Super: 0 }, nozzle_sales: {} };
    for (const n of NOZZLES) {
        const delta = round(inputs.nozzles[n] - opening.nozzles[n]);
        if (delta < 0) fail(workDate + ': ' + n + ' closing cannot be below opening (' + opening.nozzles[n] + ').');
        snapshot.nozzle_sales[n] = delta;
        const f = n.startsWith('Diesel') ? 'Diesel' : 'Super';
        snapshot.sales[f] = round(snapshot.sales[f] + delta);
        snapshot.closing.nozzles[n] = inputs.nozzles[n];
    }
    for (const f of FUELS) {
        const closing = round(opening.fuel[f] + inputs.fuel[f].qty - snapshot.sales[f]);
        if (closing < 0) fail(workDate + ': ' + f + ' stock insufficient. Check opening, receipt and nozzle readings.');
        snapshot.closing.fuel[f] = closing;
    }
    for (const [name, rec] of Object.entries(inputs.lubricants)) {
        const closing = opening.lubricants[name] + rec.qty - rec.sales;
        if (closing < 0) fail(workDate + ': ' + name + ' stock insufficient.');
        snapshot.closing.lubricants[name] = closing;
    }
    return snapshot;
}
function blankInputs(opening, rates) {
    const inputs = { nozzles: { ...opening.nozzles }, fuel: {}, lubricants: {} };
    for (const f of FUELS) inputs.fuel[f] = { qty: 0, amount: 0 };
    for (const name of Object.keys(opening.lubricants)) inputs.lubricants[name] = { qty: 0, sales: 0, rate: rates.lubricants[name] || 0, amount: 0 };
    return inputs;
}
module.exports = { FUELS, NOZZLES, DEFAULT_LUBRICANTS, fail, date, nextDate, number, round, normalizeBaseline, normalizeInputs, calculate, blankInputs };
