import {exportBackup,inspectBackup,mergeBackup,MAX_BACKUP_BYTES} from './backup.mjs';
import {PROGRESS,REVIEW,STORAGE_KEY,progressKey,emptyProgress,transition,loadProgress,saveProgress,validateCatalogue} from './model.mjs';
const $=id=>document.getElementById(id);
const node=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
const button=(text,fn,cls='secondary')=>{const b=node('button',text,cls);b.type='button';b.onclick=fn;return b;};
let catalogue,selected,records={},persist=false,lastSaved=null,pendingImport=null,importGeneration=0;const answers=new Map();
const age=()=>$('age').value;
const key=()=>progressKey(selected,age());
const progress=()=>records[key()]||emptyProgress();
function save(){if(!persist)return;try{if(localStorage.getItem(STORAGE_KEY)!==lastSaved){pauseSaving();return;}saveProgress(localStorage,records);lastSaved=localStorage.getItem(STORAGE_KEY);$('storage-status').textContent='Шаги и статусы сохранены в браузере. Ответы не записаны.';}catch{persist=false;$('persist').checked=false;$('storage-status').textContent='Не удалось сохранить. Прогресс остаётся только в этой вкладке.';}}
function act(type,value){records[key()]=transition(selected,progress(),{type,value});save();renderList();renderLesson();}
function filtered(){return catalogue.skills.filter(s=>($('block').value==='all'||s.block===$('block').value)&&($('availability').value==='all'||s.availability===$('availability').value)&&`${s.id} ${s.title}`.toLocaleLowerCase('ru').includes($('search').value.trim().toLocaleLowerCase('ru')));}
function renderList(){const list=$('skills');list.replaceChildren();const items=filtered();$('count').textContent=items.length;if(!items.length)list.append(node('p','Ничего не найдено. Попробуйте другой запрос.'));
 for(const s of items){const b=button('',()=>{selected=s;renderList();renderLesson();$('lesson').focus();},'skill');b.setAttribute('aria-pressed',String(selected?.id===s.id));b.append(node('span',`${s.id} · ${s.blockTitle}`,'small'),node('strong',s.title),node('span',s.availability==='outline'?'Тема без упражнения':PROGRESS[(records[progressKey(s,age())]||emptyProgress()).status],'small'));list.append(b);}}
function section(title,text){const el=node('section');el.append(node('h3',title),node('p',text));return el;}
function renderLesson(){const area=$('lesson');area.replaceChildren();if(!selected){area.append(node('h2','Выберите навык из каталога'));return;}
 const p=progress();area.append(node('p',`${selected.id} / ${selected.blockTitle}`,'eyebrow'),node('h2',selected.title));
 const badges=node('div',undefined,'badges');badges.append(node('span',`Материал: ${REVIEW[selected.review.status]}`,'pill amber'),node('span',`Прогресс: ${PROGRESS[p.status]}`,'pill'));area.append(badges);
 const link=node('a','Исходный текст в Notion ↗');link.href=selected.source.url;link.target='_blank';link.rel='noopener noreferrer';area.append(link,node('p','«На проверке» означает ожидание согласования. Эффективность этого упражнения отдельно не оценена.','small'));
 if(selected.availability==='outline'){area.append(section('Упражнение ещё не подготовлено','В исходной архитектуре есть название темы. Практика, вопросы и критерий не добавлены автоматически. Эта тема пока недоступна для прохождения.'));return;}
 const ageInfo=catalogue.ages.find(a=>a.id===age());area.append(section(`Формат · ${ageInfo.label}`,ageInfo.guidance));const adaptation=node('details');adaptation.append(node('summary','Возрастная методика из источника'),node('p',selected.ageAdaptation),node('p','Шаги ниже общие. Отдельные возрастные тексты ещё требуют разработки и согласования.'));area.append(adaptation);
 area.append(section('Жизненная ситуация',selected.situations[age()==='18+'?'adult':'child']),section('Как это работает',selected.mechanism));
 const practice=node('section',undefined,'practice');
 if(p.status==='not_started'){practice.append(node('h3',`Практика · шагов: ${selected.steps.length}`),node('p','Можно обсудить вымышленную ситуацию. Личные подробности не обязательны.'),button('Начать упражнение',()=>act('start'),'primary'));}
 else if(p.step<selected.steps.length){practice.append(node('p',`Шаг ${p.step+1} из ${selected.steps.length}`,'eyebrow'),node('h3',selected.steps[p.step].text));const bar=node('progress');bar.max=selected.steps.length;bar.value=p.completed.length;bar.setAttribute('aria-label','Пройденные шаги');practice.append(bar);const nav=node('div',undefined,'actions');const back=button('Назад',()=>act('back'));back.disabled=p.step===0;nav.append(back,button('Выполнено →',()=>act('next'),'primary'));practice.append(nav,node('p','Можно сделать паузу: выберите другой навык или вернитесь позже в этой вкладке.','small'));}
 else {practice.append(node('h3','Шаги пройдены. Что получилось?'),node('p',selected.recommendation));
 for(const [kind,title] of [['reflection','Рефлексивный вопрос'],['coaching','Коучинговый вопрос']]) selected.questions[kind].forEach((q,i)=>{const id=`answer-${kind}-${i}`,answerKey=`${key()}/${kind}/${i}`;const label=node('label',`${title}: ${q}`);label.htmlFor=id;const input=node('textarea');input.id=id;input.rows=3;input.maxLength=3000;input.placeholder='Можно ответить мысленно или пропустить';input.value=answers.get(answerKey)||'';input.oninput=()=>answers.set(answerKey,input.value);practice.append(label,input);});
 practice.append(section('Наблюдаемый критерий',selected.criterion));const label=node('label',undefined,'check');const check=node('input');check.type='checkbox';check.checked=p.criterionObserved;check.onchange=()=>act('observe',check.checked);label.append(check,node('span','Я наблюдал(а) выполнение этого критерия в безопасной ситуации.'));practice.append(label,node('p','«Закреплено» — ваша отметка, не подтверждение устойчивого освоения, роста EQ или одобрения материала.','small'));const done=button(p.status==='consolidated'?'Отмечено: закреплено':'Отметить «закреплено»',()=>act('consolidate'),'primary');done.disabled=!p.criterionObserved||p.status==='consolidated';practice.append(done,button('Вернуться к шагам',()=>act('back')));}
 area.append(practice);if(p.status!=='not_started')area.append(button('Начать этот навык заново',()=>{if(confirm('Сбросить шаги и ответы этого навыка для выбранного возраста?')){for(const k of answers.keys())if(k.startsWith(key()+'/'))answers.delete(k);act('reset');}}));
 const original=node('details',undefined,'source');original.append(node('summary','Дословная карточка источника'),node('pre',selected.source.excerpt));area.append(original);
}
function refresh(){const items=filtered();if(!items.some(s=>s.id===selected?.id))selected=items[0];renderList();renderLesson();}
$('persist').onchange=()=>{persist=$('persist').checked;if(persist){try{const latest=localStorage.getItem(STORAGE_KEY);if(latest!==lastSaved&&!confirm('Сохранённые данные изменились в другой вкладке. Заменить их прогрессом этой вкладки?')){persist=false;$('persist').checked=false;return;}lastSaved=latest;}catch{}save();}else{try{localStorage.removeItem(STORAGE_KEY);lastSaved=null;$('storage-status').textContent='Запись в браузере удалена. Текущий прогресс остался только в этой вкладке.';}catch{$('storage-status').textContent='Не удалось удалить запись браузера. Удалите данные сайта в настройках браузера.';}}};
$('clear').onclick=()=>{if(!confirm('Удалить все шаги, статусы и ответы тренажёра на этом устройстве?'))return;records={};answers.clear();cancelImport();persist=false;$('persist').checked=false;try{localStorage.removeItem(STORAGE_KEY);lastSaved=null;$('storage-status').textContent='Прогресс тренажёра удалён.';}catch{$('storage-status').textContent='Состояние вкладки очищено. Запись на диске удалить не удалось — очистите данные сайта в браузере.';}renderList();renderLesson();};

function pauseSaving(){
 persist=false;$('persist').checked=false;$('reload-saved').hidden=false;
 $('storage-status').textContent='Прогресс изменён в другой вкладке. Автосохранение приостановлено; текущая практика осталась в памяти. Загрузите сохранённые данные или экспортируйте эту вкладку.';
}
window.addEventListener('storage',event=>{
 if(!catalogue || (event.key!==STORAGE_KEY && event.key!==null))return;
 if(event.newValue===null){
  records={};answers.clear();cancelImport();persist=false;lastSaved=null;$('persist').checked=false;$('reload-saved').hidden=true;
  $('storage-status').textContent='Сохранение удалено в другой вкладке. Эта вкладка тоже очищена.';renderList();renderLesson();
 }else pauseSaving();
});
$('reload-saved').onclick=()=>{
 if(!confirm('Загрузить прогресс браузера вместо текущей вкладки? Ответы в этой вкладке будут очищены.'))return;
 try{const incoming=loadProgress(localStorage,catalogue);const raw=localStorage.getItem(STORAGE_KEY);records=incoming;lastSaved=raw;persist=raw!==null;answers.clear();cancelImport();$('persist').checked=persist;$('reload-saved').hidden=true;renderList();renderLesson();$('storage-status').textContent='Сохранённый прогресс загружен.';}
 catch{$('storage-status').textContent='Не удалось прочитать сохранение. Текущий прогресс сохранён в памяти.';}
};
function cancelImport(){importGeneration++;pendingImport=null;$('import-preview').hidden=true;$('import-file').value='';$('replace-conflicts').checked=false;}
$('export').onclick=()=>{
 const blob=new Blob([exportBackup(records,catalogue)],{type:'application/json'});const url=URL.createObjectURL(blob);const a=node('a');a.href=url;a.download='yugatn-skills-progress.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);$('backup-status').textContent='Файл подготовлен без личных ответов и редакционных статусов.';
};
$('import-file').onchange=async()=>{
 const file=$('import-file').files[0];cancelImport();const generation=importGeneration;if(!file)return;
 try{if(file.size>MAX_BACKUP_BYTES)throw Error('Файл больше 512 КБ.');const text=await file.text();if(generation!==importGeneration)return;
  pendingImport=inspectBackup(text,catalogue);const conflicts=Object.keys(pendingImport.records).filter(k=>Object.hasOwn(records,k)).length;
  $('import-summary').textContent=`Совместимых записей: ${pendingImport.accepted}. Пропущено (другая версия/возраст или неверная запись): ${pendingImport.skipped}. Совпадений с текущими: ${conflicts}. По умолчанию текущие записи сохраняются.`;
  $('apply-import').disabled=pendingImport.accepted===0;$('import-preview').hidden=false;$('backup-status').textContent='Проверьте состав копии. До нажатия «Применить импорт» ничего не изменяется.';
 }catch(error){if(generation===importGeneration)$('backup-status').textContent=error.message;}
};
$('cancel-import').onclick=()=>{cancelImport();$('backup-status').textContent='Импорт отменён. Прогресс не изменён.';};
$('apply-import').onclick=()=>{
 if(!pendingImport)return;const replace=$('replace-conflicts').checked;
 if(replace&&!confirm('Заменить совпадающие записи? Более свежий прогресс может быть утрачен.'))return;
 records=mergeBackup(records,pendingImport.records,replace);answers.clear();cancelImport();save();renderList();renderLesson();$('backup-status').textContent=persist?'Прогресс импортирован и сохранён в браузере.':'Прогресс импортирован в память вкладки. Для сохранения включите запись или скачайте копию.';
};

async function init(){try{const response=await fetch('./data/skills.json');if(!response.ok)throw Error('Catalogue unavailable');catalogue=validateCatalogue(await response.json());
 for(const a of catalogue.ages){const o=node('option',a.label);o.value=a.id;$('age').append(o);}$('age').value='12-17';
 for(const [id,title] of new Map(catalogue.skills.map(s=>[s.block,s.blockTitle]))){const o=node('option',`${id} · ${title}`);o.value=id;$('block').append(o);}
 try{records=loadProgress(localStorage,catalogue);lastSaved=localStorage.getItem(STORAGE_KEY);persist=lastSaved!==null;$('persist').checked=persist;}catch{$('storage-status').textContent='Сохранённый прогресс недоступен или повреждён. Работаем в памяти вкладки; можно удалить старую запись кнопкой ниже.';}
 for(const id of ['block','availability'])$(id).onchange=refresh;$('search').oninput=refresh;$('age').onchange=()=>{renderList();renderLesson();};$('loading').hidden=true;$('workspace').hidden=false;refresh();
 }catch{$('loading').hidden=true;$('error').hidden=false;$('error').textContent='Не удалось загрузить каталог. Запустите сайт через HTTP по инструкции README и обновите страницу.';}}
init();
