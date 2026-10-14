const fs = require('fs');
const path = require('path');

class OAuthScanner {
  constructor() { this.findings = []; }
  scan(dir) {
    const files = this.getFiles(dir);
    files.forEach(f => this.scanFile(f, fs.readFileSync(f, 'utf-8')));
    return this.findings;
  }
  getFiles(dir) {
    let files = [];
    try {
      fs.readdirSync(dir, { withFileTypes: true }).forEach(e => {
        if (e.name.startsWith('.')) return;
        const p = path.join(dir, e.name);
        if (e.isDirectory()) files = files.concat(this.getFiles(p));
        else if (['.go', '.ts', '.js', '.py'].includes(path.extname(e.name))) files.push(p);
      });
    } catch(e) {}
    return files;
  }
  scanFile(f, c) {
    if (c.match(/redirect_uri.*req\.query/i)) this.findings.push({file: f, vuln: 'Unvalidated redirect_uri'});
    if (c.match(/skipPkceValidation.*true/i)) this.findings.push({file: f, vuln: 'Missing PKCE'});
  }
  report() {
    console.log(this.findings.length ? `Found ${this.findings.length} issues:\n` + this.findings.map(f => `  ${f.vuln} in ${f.file}`).join('\n') : '✓ No vulnerabilities');
  }
}
module.exports = OAuthScanner;
