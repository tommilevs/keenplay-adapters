import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';

const root=path.resolve(import.meta.dirname,'..');
const app=path.join(root,'apps','keenplay-s-ui');
const manifestPath=path.join(app,'playkeen.yaml');
const versionPath=path.join(app,'UPSTREAM_VERSION');
const current=(await fs.readFile(versionPath,'utf8')).trim();
const response=await fetch('https://api.github.com/repos/alireza0/s-ui/releases/latest',{headers:{'User-Agent':'KeenPlay-adapters','Accept':'application/vnd.github+json',...(process.env.GITHUB_TOKEN?{Authorization:`Bearer ${process.env.GITHUB_TOKEN}`}:{})}});
if(!response.ok)throw new Error(`Upstream GitHub API returned ${response.status}`);
const release=await response.json();
const asset=release.assets?.find(item=>item.name==='s-ui-linux-arm64.tar.gz');
const expected=asset?.digest?.match(/^sha256:([a-f0-9]{64})$/i)?.[1]?.toLowerCase();
if(!asset||!expected||!asset.browser_download_url?.startsWith('https://github.com/alireza0/s-ui/releases/download/'))throw new Error('Upstream arm64 release asset or SHA-256 digest is unavailable');
const version=release.tag_name;
const changed=version!==current;
if(changed){
  const archiveResponse=await fetch(asset.browser_download_url,{headers:{'User-Agent':'KeenPlay-adapters'}});
  if(!archiveResponse.ok)throw new Error(`Upstream archive download returned ${archiveResponse.status}`);
  const bytes=Buffer.from(await archiveResponse.arrayBuffer());
  const actual=createHash('sha256').update(bytes).digest('hex');
  if(actual!==expected)throw new Error('Upstream archive SHA-256 digest mismatch');
  const tmp=await fs.mkdtemp(path.join(os.tmpdir(),'keenplay-sui-'));
  try {
    const downloaded=path.join(tmp,'sui.tar.gz');
    await fs.writeFile(downloaded,bytes);
    const files=execFileSync('tar',['-tzf',downloaded],{encoding:'utf8'}).split(/\r?\n/);
    if(!files.some(file=>path.posix.basename(file)==='sui'))throw new Error('Upstream archive contains no `sui` executable');
  } finally {await fs.rm(tmp,{recursive:true,force:true});}
  const yaml=await fs.readFile(manifestPath,'utf8');
  await fs.writeFile(manifestPath,yaml.replace(/^version:.*$/m,`version: ${version.replace(/^v/,'')}`));
  await fs.writeFile(versionPath,`${version}\n`);
}
const tag=version.replace(/^v/,'');
const dist=path.join(root,'dist');
await fs.mkdir(dist,{recursive:true});
const packagePath=path.join(dist,`keenplay-s-ui-${tag}.tar.gz`);
execFileSync('tar',['-czf',packagePath,'-C',app,'playkeen.yaml','UPSTREAM_VERSION','app','MIGRATION.md']);
if(process.env.GITHUB_OUTPUT)await fs.appendFile(process.env.GITHUB_OUTPUT,`version=${tag}\nchanged=${changed}\n`);
console.log(`S-UI upstream ${version}; adapter bundle ${changed?'refreshed':'rebuilt'}.`);
