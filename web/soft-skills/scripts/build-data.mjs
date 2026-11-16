import fs from 'node:fs';
import {createHash} from 'node:crypto';
const root=new URL('../',import.meta.url);
const source=JSON.parse(fs.readFileSync(new URL('data/source-snapshot.json',root),'utf8'));
const hash=s=>createHash('sha256').update(s).digest('hex');
const skills=[];
const content=p=>p.text.split('<content>')[1].split('</content>')[0].trim();
const ages=[{id:'4-6',label:'4–6 лет',guidance:'Сказка, рисунок, игра с взрослым, 5–10 минут'},{id:'7-11',label:'7–11 лет',guidance:'Ситуации из школы, карточки, комиксы, 10–20 минут'},{id:'12-17',label:'12–17 лет',guidance:'Истории о дружбе, автономии, социальной сети, 15–30 минут'},{id:'18+',label:'18+',guidance:'Диалоги, дневник, упражнения, рабочие и семейные кейсы'}];
let i=0;
for(const m of source.architecture.matchAll(/<b>Главы [^<]+<\/b> (.*?)\. Результат:/g)) {
 for(const title of m[1].split('; ')) {
  i++;
  skills.push({id:`01.${String(i).padStart(2,'0')}`,title,block:'01',blockTitle:'Эмоциональный интеллект',version:hash(title).slice(0,12),availability:'outline',review:{status:'unconfirmed',approvedBy:null,approvedAt:null},evidenceStatus:'not_assessed',source:{url:source.url,heading:`Главы ${Math.floor((i-1)/5)*5+1}–${Math.floor((i-1)/5)*5+5}`,excerpt:title,sha256:hash(title)},situations:{child:null,adult:null},mechanism:null,ageAdaptation:null,steps:[],questions:{reflection:[],coaching:[]},criterion:null,recommendation:null});
 }
}
if(i!==35) throw Error(`Expected 35 outline topics, got ${i}`);
for(const p of source.pages) {
 const body=content(p);
 const adaptation=body.match(/<b>(?:Возрастная адаптация|Как преподавать):<\/b> ([^\n]+)/)?.[1];
 const matches=[...body.matchAll(/^## (\d+\.\d+) (.+)\n([\s\S]*?)(?=^## |$(?![\s\S]))/gm)];
 if(matches.length!==5) throw Error(`Expected 5 cards: ${p.block}`);
 for(const m of matches) {
  const raw=m[0].trim(),fields={};
  for(const f of m[3].matchAll(/<b>([^<]+):<\/b>\s*([\s\S]*?)(?=\n<b>|$(?![\s\S]))/g)) fields[f[1]]=f[2].trim();
  const get=(...keys)=>{const key=keys.find(k=>fields[k]);if(!key)throw Error(`Missing ${keys} in ${m[1]}`);return fields[key];};
  skills.push({id:m[1].split('.').map(x=>x.padStart(2,'0')).join('.'),title:m[2],block:p.block,blockTitle:p.title,version:hash(raw+adaptation).slice(0,12),availability:'exercise',review:{status:'under_review',approvedBy:null,approvedAt:null},evidenceStatus:'not_assessed',source:{url:p.url,heading:m[1]+' '+m[2],excerpt:raw,sha256:hash(raw)},situations:{child:get('Когда пригодится ребёнку','Ситуация у ребёнка'),adult:get('Когда пригодится взрослому','Ситуация у взрослого')},mechanism:get('Что происходит и почему навык важен','Как это работает','Почему навык полезен'),ageAdaptation:adaptation,steps:[...get('Инструкция','Практика — пять действий','Пошаговое упражнение').matchAll(/^\d+\. (.+)$/gm)].map((s,j)=>({id:`step-${j+1}`,text:s[1]})),questions:{reflection:[get('Бережный вопрос для саморефлексии','Вопрос для саморефлексии','Рефлексивный вопрос')],coaching:[get('Коучинговый вопрос')]},criterion:get('Как заметить прогресс','Критерий','Наблюдаемый результат'),recommendation:get('Рекомендация','Практическая рекомендация')});
 }
}
fs.writeFileSync(new URL('data/skills.json',root),JSON.stringify({schemaVersion:1,sourceUrl:source.url,retrievedAt:source.retrievedAt,ages,skills},null,2)+'\n');
console.log(`${skills.length} topics; ${skills.filter(s=>s.availability==='exercise').length} exercises. Source text preserved.`);
