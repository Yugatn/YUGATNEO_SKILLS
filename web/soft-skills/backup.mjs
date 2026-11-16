import {loadProgress,normalizeProgress,progressKey} from './model.mjs';
export const MAX_BACKUP_BYTES=512*1024;
export function exportBackup(records,catalogue){
 const clean={};
 for(const skill of catalogue.skills.filter(s=>s.availability==='exercise'))for(const age of catalogue.ages){
  const key=progressKey(skill,age.id);
  if(Object.hasOwn(records,key))clean[key]=normalizeProgress(records[key],skill);
 }
 return JSON.stringify({app:'yugatn-soft-skills',schemaVersion:1,records:clean},null,2);
}
export function inspectBackup(text,catalogue){
 if(new TextEncoder().encode(text).length>MAX_BACKUP_BYTES)throw Error('Файл больше 512 КБ.');
 let parsed;try{parsed=JSON.parse(text);}catch{throw Error('Файл не является корректным JSON.');}
 if(!parsed||parsed.app!=='yugatn-soft-skills'||parsed.schemaVersion!==1||!parsed.records||typeof parsed.records!=='object'||Array.isArray(parsed.records))throw Error('Неподдерживаемый формат резервной копии.');
 const imported=loadProgress({getItem:()=>JSON.stringify(parsed)},catalogue);
 const valid=new Set(catalogue.skills.filter(s=>s.availability==='exercise').flatMap(s=>catalogue.ages.map(a=>progressKey(s,a.id))));
 const records={};let skipped=0;
 for(const [key,value] of Object.entries(parsed.records)){
  if(!valid.has(key)||!value||typeof value!=='object'||Array.isArray(value)){skipped++;continue;}
  records[key]=imported[key];
 }
 return {records,accepted:Object.keys(records).length,skipped};
}
export function mergeBackup(current,incoming,replaceConflicts=false){
 const result={...current};
 for(const [key,value] of Object.entries(incoming))if(replaceConflicts||!Object.hasOwn(result,key))result[key]=value;
 return result;
}
