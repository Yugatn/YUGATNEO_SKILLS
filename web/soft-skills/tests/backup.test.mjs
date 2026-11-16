import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {exportBackup,inspectBackup,mergeBackup,MAX_BACKUP_BYTES} from '../backup.mjs';
import {progressKey,normalizeProgress,emptyProgress} from '../model.mjs';
const catalogue=JSON.parse(fs.readFileSync(new URL('../data/skills.json',import.meta.url)));
const skill=catalogue.skills.find(s=>s.availability==='exercise');
const key=progressKey(skill,'12-17');
const progress={status:'in_progress',step:1,completed:['step-1'],criterionObserved:false};
test('export includes only current compatible progress, never answers or review',()=>{
 const raw=exportBackup({[key]:{...progress,answer:'secret',review:'approved'},stale:{...progress}},catalogue);
 assert.ok(!raw.includes('secret'));assert.ok(!raw.includes('approved'));assert.ok(!raw.includes('stale'));
 assert.deepEqual(inspectBackup(raw,catalogue).records,{[key]:progress});
});
test('import rejects wrong app, future format, malformed JSON and excessive size',()=>{
 for(const raw of ['null','[]','{','{}','{"app":"other","schemaVersion":1,"records":{}}','{"app":"yugatn-soft-skills","schemaVersion":2,"records":{}}','x'.repeat(MAX_BACKUP_BYTES+1)])assert.throws(()=>inspectBackup(raw,catalogue));
});
test('unknown versions, outline keys and invalid record objects are skipped',()=>{
 const raw=JSON.stringify({app:'yugatn-soft-skills',schemaVersion:1,records:{[key]:null,stale:progress,[progressKey(catalogue.skills[0],'12-17')]:progress}});
 const result=inspectBackup(raw,catalogue);assert.equal(result.accepted,0);assert.equal(result.skipped,3);
});
test('import cannot fabricate completed status with missing steps',()=>{
 const raw=JSON.stringify({app:'yugatn-soft-skills',schemaVersion:1,records:{[key]:{...progress,status:'consolidated',criterionObserved:true,review:'approved'}}});
 const result=inspectBackup(raw,catalogue);assert.equal(result.records[key].status,'in_progress');assert.ok(!('review'in result.records[key]));
});
test('merge keeps local conflicts by default and preserves unrelated records',()=>{
 const existing={[key]:progress,other:progress};const incoming={[key]:emptyProgress(),new:progress};
 assert.deepEqual(mergeBackup(existing,incoming),{...existing,new:progress});
 assert.deepEqual(mergeBackup(existing,incoming,true),{[key]:emptyProgress(),other:progress,new:progress});
 assert.deepEqual(existing,{[key]:progress,other:progress});
});
test('not started imported records cannot retain hidden completion',()=>{
 assert.deepEqual(normalizeProgress({...progress,status:'not_started',criterionObserved:true},skill),emptyProgress());
});
