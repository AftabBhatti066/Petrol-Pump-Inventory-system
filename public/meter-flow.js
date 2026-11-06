'use strict';
const API_URL='/api/meter';
const nozzleConfig=[['Diesel (N1)','diesel_n1'],['Diesel (N2)','diesel_n2'],['Diesel (N3)','diesel_n3'],['Diesel (N4)','diesel_n4'],['Super (N1)','super_n1'],['Super (N2)','super_n2']];
const userId=localStorage.getItem('userId');
const pendingKey='meter_flow_pending_'+userId;
let day=null,busy=false,dirty=false,pending=null;
const $=id=>document.getElementById(id);
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const val=id=>Number($(id)?.value || 0);
const fmt=n=>Number(n).toFixed(2);
function message(text,error=false){$('syncStatus').textContent=text;$('syncStatus').style.color=error?'#c0392b':'#247148';}
function controls(){
    document.querySelectorAll('.matrix-input').forEach(e=>e.disabled=busy||!!pending||!day||day.setup_required);
    $('working_date').disabled=busy||!!pending||!day||day.setup_required;
    $('saveDayButton').disabled=busy||!day||day.setup_required;
    $('saveDayButton').textContent=pending?'↻ Retry pending save':'💾 Save & Close Day';
    $('refreshButton').disabled=busy||!!pending;
    document.querySelectorAll('#openingSetup input, #openingSetup button').forEach(e=>e.disabled=busy);
}
async function api(path,options={}){
    const response=await fetch(API_URL+path,{cache:'no-store',...options});
    let result;
    try{result=await response.json();}catch(_){throw new Error('Invalid server response. Your inputs have been kept.');}
    if(!response.ok||result.status!=='Success'){
        const e=new Error(result.message||'Request failed');e.httpStatus=response.status;throw e;
    }
    return result;
}
function newId(){
    if(crypto.randomUUID)return crypto.randomUUID();
    const b=crypto.getRandomValues(new Uint8Array(16));b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;
    const h=Array.from(b,x=>x.toString(16).padStart(2,'0')).join('');
    return h.slice(0,8)+'-'+h.slice(8,12)+'-'+h.slice(12,16)+'-'+h.slice(16,20)+'-'+h.slice(20);
}
function renderSetup(info){
    $('openingSetup').hidden=false;
    $('working_date').value=info.default_date;
    $('setupDate').value=info.default_date;
    $('setupDate').min=info.default_date;
    $('setupNozzles').innerHTML=nozzleConfig.map(([name],i)=>`<label>${esc(name)} initial meter <input id="setup_nozzle_${i}" type="number" min="0" step="0.01" value="${esc(info.nozzles[name]??'')}" required></label>`).join('');
    $('setupLubricants').innerHTML=info.items.map((name,i)=>`<label>${esc(name)} actual quantity <input id="setup_lub_${i}" type="number" min="0" step="1" required placeholder="Enter actual quantity"></label>`).join('');
    for(const [name,key] of nozzleConfig){$('open_'+key).textContent=info.nozzles[name]===null?'Not set':fmt(info.nozzles[name]);$('close_'+key).value='';}
    for(const key of ['diesel','super']){$('stock_open_'+key).textContent='Opening stock required';$('stock_close_'+key).textContent='—';}
    message('Enter actual opening stock for the chosen start date. Old meter history will be preserved.');
}
function renderDay(data){
    day=data;
    if(data.setup_required){renderSetup(data);controls();return;}
    $('openingSetup').hidden=true;
    $('working_date').value=data.date;$('working_date').min=data.start_date;$('working_date').max=data.default_date;
    for(const [name,key] of nozzleConfig){$('open_'+key).textContent=fmt(data.opening.nozzles[name]);$('close_'+key).value=fmt(data.inputs.nozzles[name]);}
    for(const fuel of ['Diesel','Super']){
        const key=fuel.toLowerCase();
        $('stock_open_'+key).textContent=fmt(data.opening.fuel[fuel]);
        $('receipt_'+key).value=data.inputs.fuel[fuel].qty;
        $('amount_'+key).value=fmt(data.inputs.fuel[fuel].amount);
        $('receipt_'+key).title=data.rates.fuel[fuel]>0?'Purchase rate: Rs. '+fmt(data.rates.fuel[fuel]):'Purchase rate missing: enter final receipt amount manually.';
    }
    $('lubricantBody').innerHTML=data.items.map((name,i)=>{
        const r=data.inputs.lubricants[name];
        return `<tr><td class="row-desc">${esc(name)}</td><td><span class="val-blue">${data.opening.lubricants[name]}</span></td>
        <td><input type="number" min="0" step="1" id="lub_rec_${i}" class="matrix-input" value="${r.qty}" oninput="calculateLiveSales()"></td>
        <td><input type="number" min="0" step="0.01" id="lub_rate_${i}" class="matrix-input" value="${r.rate}" oninput="calculateLiveSales()"></td>
        <td><span id="lub_amount_${i}" class="val-green">0.00</span></td>
        <td><input type="number" min="0" step="1" id="lub_sale_${i}" class="matrix-input" value="${r.sales}" oninput="calculateLiveSales()"></td>
        <td><span id="lub_close_${i}" class="val-purple">0</span></td></tr>`;
    }).join('');
    calculateLiveSales();dirty=false;
    message(data.saved?'Saved day loaded — editing updates this day.':'Ready — next working day.');
    if(pending)message('A previous save needs confirmation. Click Retry pending save; do not re-enter it.',true);
    controls();
}
async function loadCurrentStatusFromDB(useDefault=false){
    if(busy||pending)return;
    if(dirty&&!confirm('Unsaved changes discard karke saved data load karein?')){if(day&&!day.setup_required)$('working_date').value=day.date;return;}
    busy=true;controls();
    const requested=useDefault?'':$('working_date').value;
    try{const data=await api('/day?userId='+encodeURIComponent(userId)+(requested?'&date='+encodeURIComponent(requested):''));renderDay(data);}
    catch(e){if(day&&!day.setup_required)$('working_date').value=day.date;message(e.message,true);}
    finally{busy=false;controls();}
}
function onReceiptLitersChanged(key){
    if(!day||day.setup_required)return;
    const fuel=key==='diesel'?'Diesel':'Super',qty=val('receipt_'+key),rate=day.rates.fuel[fuel];
    // A litre change starts a fresh estimate; amount remains manually editable afterwards.
    $('amount_'+key).value=qty===0?'0.00':rate>0?fmt(qty*rate):'';
    calculateLiveSales();
}
function calculateLiveSales(){
    if(!day||day.setup_required)return;
    dirty=true;
    const totals={Diesel:0,Super:0};
    for(const [name,key] of nozzleConfig){
        const input=$('close_'+key),n=Number(input.value),opening=day.opening.nozzles[name];
        const valid=input.value!==''&&Number.isFinite(n)&&n>=opening;
        input.setCustomValidity(valid?'':'Closing must be at least opening; use opening again for zero sales.');
        const sold=valid?Math.round((n-opening)*100)/100:0;
        $('sales_'+key).textContent=valid?fmt(sold):'Invalid reading';
        totals[name.startsWith('Diesel')?'Diesel':'Super']+=sold;
    }
    for(const fuel of ['Diesel','Super']){
        const key=fuel.toLowerCase(),closing=day.opening.fuel[fuel]+val('receipt_'+key)-totals[fuel];
        $('stock_deduct_'+key).textContent=fmt(totals[fuel]);$('stock_close_'+key).textContent=fmt(closing);
        $('stock_close_'+key).style.color=closing<0?'#c0392b':'';
    }
    day.items.forEach((name,i)=>{
        $('lub_amount_'+i).textContent=fmt(val('lub_rec_'+i)*val('lub_rate_'+i));
        const closing=day.opening.lubricants[name]+val('lub_rec_'+i)-val('lub_sale_'+i);
        $('lub_close_'+i).textContent=closing;$('lub_close_'+i).style.color=closing<0?'#c0392b':'';
    });
}
function collectInputs(){
    for(const input of document.querySelectorAll('.matrix-input')) if(!input.reportValidity())throw new Error('Please correct the highlighted input.');
    const inputs={nozzles:{},fuel:{},lubricants:{}};
    for(const [name,key] of nozzleConfig)inputs.nozzles[name]=$('close_'+key).value;
    for(const fuel of ['Diesel','Super']){
        const key=fuel.toLowerCase();inputs.fuel[fuel]={qty:val('receipt_'+key),amount:$('amount_'+key).value};
        if(val('receipt_'+key)>0&&(!inputs.fuel[fuel].amount||Number(inputs.fuel[fuel].amount)<=0))throw new Error(fuel+': final purchase amount enter karein.');
    }
    day.items.forEach((name,i)=>inputs.lubricants[name]={qty:val('lub_rec_'+i),rate:val('lub_rate_'+i),sales:val('lub_sale_'+i)});
    return inputs;
}
async function saveAllReadings(){
    if(busy||!day||day.setup_required)return;
    try{
        if(!pending){
            const inputs=collectInputs();
            if(!confirm(day.date+' ka data save '+(day.saved?'update':'aur day close')+' karein?'))return;
            pending={userId,date:day.date,revision:day.revision,request_id:newId(),inputs};
            // Persist before sending so a lost response/reload can retry the exact same operation.
            localStorage.setItem(pendingKey,JSON.stringify(pending));
        }
    }catch(e){pending=null;message(e.message,true);return;}
    busy=true;controls();message('Saving complete day...');
    let saved=false;
    try{
        const result=await api('/save-day',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(pending)});
        saved=true;pending=null;localStorage.removeItem(pendingKey);dirty=false;
        $('working_date').value=result.default_date;
        message('Day saved. Loading next working date...');
        const data=await api('/day?userId='+encodeURIComponent(userId));renderDay(data);
    }catch(e){
        if(e.httpStatus>=400&&e.httpStatus<500){pending=null;localStorage.removeItem(pendingKey);}
        if(saved){day=null;message('Save successful, but next day did not load. Refresh Screen to reload; do not enter the receipt again.',true);}
        else message(e.message+(pending?' Use Retry pending save to safely confirm the same request.':''),true);
    }finally{busy=false;controls();}
}
async function saveOpeningSetup(event){
    event.preventDefault();if(busy)return;
    const baseline={nozzles:{},fuel:{Diesel:$('setupDiesel').value,Super:$('setupSuper').value},lubricants:{}};
    nozzleConfig.forEach(([name],i)=>baseline.nozzles[name]=$('setup_nozzle_'+i).value);
    day.items.forEach((name,i)=>baseline.lubricants[name]=$('setup_lub_'+i).value);
    if(!confirm('Selected date ke start ka actual stock aur meter readings confirm hain? Existing stock balances will be replaced by these actual values; previous values are archived.'))return;
    busy=true;controls();
    try{
        await api('/setup',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({userId,start_date:$('setupDate').value,baseline})});
        renderDay(await api('/day?userId='+encodeURIComponent(userId)));
    }catch(e){message(e.message,true);}
    finally{busy=false;controls();}
}
window.addEventListener('DOMContentLoaded',async()=>{
    if(!userId){window.location.href='login.html';return;}
    $('working_date').addEventListener('change',()=>loadCurrentStatusFromDB(false));
    $('openingSetupForm').addEventListener('submit',saveOpeningSetup);
    $('logoutBtn').addEventListener('click',()=>{
        if((dirty||pending)&&!confirm('Unsaved/pending work exists. Logout? Pending saves can be retried after login.'))return;
        localStorage.removeItem('userId');localStorage.removeItem('username');window.location.href='login.html';
    });
    try{pending=JSON.parse(localStorage.getItem(pendingKey)||'null');}catch(_){localStorage.removeItem(pendingKey);}
    busy=true;controls();
    try{renderDay(await api('/day?userId='+encodeURIComponent(userId)));}
    catch(e){message(e.message,true);}
    finally{busy=false;controls();}
});
window.addEventListener('beforeunload',event=>{if(dirty||busy){event.preventDefault();event.returnValue='';}});
