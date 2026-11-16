export const PROGRESS={not_started:'не начато',in_progress:'в процессе',consolidated:'закреплено'};
export const REVIEW={under_review:'на проверке',approved:'согласовано',unconfirmed:'не подтверждено'};
export const STORAGE_KEY='yugatn.soft-skills.progress.v1';
export const progressKey=(skill,age)=>`${skill.id}@${skill.version}/${age}`;
export const emptyProgress=()=>({status:'not_started',step:0,completed:[],criterionObserved:false});
export function normalizeProgress(input,skill) {
 const result=emptyProgress();
 if(!input || typeof input!=='object' || skill.availability!=='exercise') return result;
 result.completed=[...new Set(Array.isArray(input.completed)?input.completed:[])].filter(id=>skill.steps.some(s=>s.id===id));
 result.step=Number.isInteger(input.step)?Math.max(0,Math.min(input.step,skill.steps.length)):0;
 result.criterionObserved=input.criterionObserved===true;
 result.status=Object.hasOwn(PROGRESS,input.status)?input.status:'not_started';
 if(result.status==='not_started') return emptyProgress();
 if(result.status==='consolidated' && (result.completed.length!==skill.steps.length || !result.criterionObserved)) result.status='in_progress';
 return result;
}
export function transition(skill,input,action) {
 const p=normalizeProgress(input,skill);
 if(skill.availability!=='exercise') return p;
 switch(action.type) {
 case 'start': if(p.status==='not_started')p.status='in_progress'; break;
 case 'next':
  if(p.status==='not_started')break;
  if(p.step<skill.steps.length){const id=skill.steps[p.step].id;if(!p.completed.includes(id))p.completed.push(id);p.step++;}break;
 case 'back':p.step=Math.max(0,p.step-1);break;
 case 'observe':p.criterionObserved=action.value===true;if(!p.criterionObserved && p.status==='consolidated')p.status='in_progress';break;
 case 'consolidate':if(p.status!=='not_started'&&p.completed.length===skill.steps.length&&p.criterionObserved)p.status='consolidated';break;
 case 'reset':return emptyProgress();
 default:throw Error('Unknown action');
 }
 return p;
}
export function loadProgress(storage,catalogue) {
 const raw=storage.getItem(STORAGE_KEY);if(!raw)return {};
 const parsed=JSON.parse(raw);if(parsed.schemaVersion!==1 || !parsed.records || typeof parsed.records!=='object' || Array.isArray(parsed.records))throw Error('Unsupported progress format');
 const result={};for(const skill of catalogue.skills)for(const age of catalogue.ages){const key=progressKey(skill,age.id);if(Object.hasOwn(parsed.records,key))result[key]=normalizeProgress(parsed.records[key],skill);}
 return result;
}
export function saveProgress(storage,records){storage.setItem(STORAGE_KEY,JSON.stringify({schemaVersion:1,records}));}
export function validateCatalogue(c) {
 if(c.schemaVersion!==1 || !Array.isArray(c.skills) || c.skills.length!==95)throw Error('Expected 95 topics');
 const ids=new Set();
 for(const s of c.skills){
  if(ids.has(s.id))throw Error('Duplicate skill');ids.add(s.id);
  if(!Object.hasOwn(REVIEW,s.review.status))throw Error('Invalid review status');
  if(s.review.status==='approved'&&(!s.review.approvedBy||!s.review.approvedAt))throw Error('Approval evidence required');
  if(!s.source.url.startsWith('https://app.notion.com/p/')||!s.source.sha256)throw Error('Source required');
  if(s.availability==='exercise'&&(!s.steps.length||!s.mechanism||!s.ageAdaptation||!s.situations.child||!s.situations.adult||!s.questions.reflection.length||!s.questions.coaching.length||!s.criterion))throw Error(`Incomplete exercise ${s.id}`);
 }
 return c;
}
