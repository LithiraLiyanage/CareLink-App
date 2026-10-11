const fs = require('node:fs');
const path = require('node:path');
const { getGlobalDefaultAccount, getAccessToken } = require('firebase-tools/lib/auth');

const project = 'carelink-hci';
const scopes = ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase'];

async function main() {
  const account = getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase CLI is not signed in. Run firebase login.');
  const credentials = await getAccessToken(account.tokens.refresh_token, scopes);
  async function get(resource) {
    const response = await fetch(`https://firebaserules.googleapis.com/v1/${resource}`, {
      headers: { Authorization: `Bearer ${credentials.access_token}` },
    });
    if (!response.ok) throw new Error(`Rules API ${response.status} for ${resource}`);
    return response.json();
  }

  let releases = [];
  let pageToken;
  do {
    const query = pageToken ? `?pageToken=${encodeURIComponent(pageToken)}` : '';
    const page = await get(`projects/${project}/releases${query}`);
    releases.push(...(page.releases ?? []));
    pageToken = page.nextPageToken;
  } while (pageToken);

  const normalize = source => source.replace(/\r\n/g, '\n').trim();
  console.log(JSON.stringify({ project, releases: releases.map(release => release.name) }));
  for (const [service, localFile, matchesRelease] of [
    ['Firestore', 'firestore.rules', release => release.name.endsWith('/cloud.firestore')],
    ['Storage', 'storage.rules', release => /\/firebase\.storage(?:\/|$)/.test(release.name)],
  ]) {
    const local = fs.readFileSync(path.resolve(__dirname, '..', localFile), 'utf8');
    const selected = releases.filter(matchesRelease);
    if (!selected.length) {
      console.log(JSON.stringify({ service, project, deployed: false, localMatchesLive: false }));
    }
    for (const release of selected) {
      const ruleset = await get(release.rulesetName);
      const sources = ruleset.source?.files ?? [];
      if (process.argv.includes('--save-snapshot') && sources.length === 1) {
        const directory = path.resolve(__dirname, '..', 'build', 'firebase-audit');
        fs.mkdirSync(directory, { recursive: true });
        fs.writeFileSync(path.join(directory, `${service.toLowerCase()}.live.rules`), sources[0].content);
      }
      console.log(JSON.stringify({
        service, project, deployed: true, release: release.name,
        ruleset: release.rulesetName, releasedAt: release.updateTime,
        localMatchesLive: sources.length === 1 && normalize(sources[0].content) === normalize(local),
        liveCollections: service === 'Firestore'
          ? (sources[0]?.content.match(/match\s+\/\w+\/\{\w+\}/g) ?? []) : undefined,
      }));
    }
  }

  if (process.argv.includes('--configuration')) {
    for (const [service, url, summarize] of [
      ['Storage buckets', `https://storage.googleapis.com/storage/v1/b?project=${project}`,
        data => (data.items ?? []).map(bucket => ({ name: bucket.name, location: bucket.location }))],
      ['Authentication configuration', `https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config`,
        data => ({ emailPassword: data.signIn?.email, authorizedDomains: data.authorizedDomains })],
      ['Google provider', `https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/defaultSupportedIdpConfigs`,
        data => (data.defaultSupportedIdpConfigs ?? []).map(provider => ({ name: provider.name, enabled: provider.enabled }))],
    ]) {
      const response = await fetch(url, { headers: { Authorization: `Bearer ${credentials.access_token}` } });
      const data = await response.json();
      console.log(JSON.stringify({ service, httpStatus: response.status, configuration: response.ok ? summarize(data) : data.error?.message }));
    }
  }
}

main().catch(error => { console.error(error.message); process.exitCode = 1; });
