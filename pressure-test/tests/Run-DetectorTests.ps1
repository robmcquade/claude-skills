#requires -Version 7
<#
.SYNOPSIS
  Fixture suite for Test-Sensitivity.ps1 — proves the fail-closed gate against real inputs.
  Run: pwsh <skill>/tests/Run-DetectorTests.ps1   (exit 0 = all pass, 1 = any fail)

  Fixtures are GENERATED into a temp dir at runtime (and deleted after), NOT stored in the
  repo: their secret-shaped names (prod.env, server.key, *.env*) would otherwise trip
  secret-scanning hooks or risk being committed by accident. All values below are FAKE
  (AWS's documented example key, RFC example data). This keeps the skill tree secret-free
  while remaining fully self-testing on any machine.
#>
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\scripts\Test-Sensitivity.ps1"

# --- generate fixtures into a temp dir ---
$fx = Join-Path $env:TEMP ("pt-detector-fixtures-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
foreach ($sub in 'sensitive', 'clean', 'uncertain') { New-Item -ItemType Directory -Force (Join-Path $fx $sub) | Out-Null }

Set-Content "$fx\sensitive\prod.env" -NoNewline -Value @'
# Production environment — fixture; values are fake
DATABASE_URL=postgres://appuser:s3cr3tP@ss@db.internal:5432/app
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
STRIPE_KEY=sk_live_4eC39HqLyjWDarjtT1zdp7dc
'@
Set-Content "$fx\sensitive\server.key" -NoNewline -Value @'
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE
FAKEKEYMATERIALdoNotUseThisIsAFixtureForDetectorTestingOnly1234567
-----END RSA PRIVATE KEY-----
'@
Set-Content "$fx\sensitive\client-record.md" -NoNewline -Value @'
# Client intake record (fixture — fake PII)
- Name: Jane Q. Sample
- SSN: 123-45-6789
- Card on file: 4242 4242 4242 4242
'@
Set-Content "$fx\clean\marketing-memo.md" -NoNewline -Value @'
# Q3 launch memo
We are positioning the new offering around speed and clarity. Audience is small-business
owners burned by tools that demand constant babysitting. The bar is the incumbent free tier.
'@
Set-Content "$fx\clean\refactor-plan.md" -NoNewline -Value @'
# Refactor plan: extract the report renderer
Split the renderer into shapeRows(), renderTable(), and writeArtifact() so each is testable.
No behavior change intended; the snapshot tests should pass unchanged.
'@
Set-Content "$fx\uncertain\security-notes.md" -NoNewline -Value @'
# Security posture notes (discussion only — no secrets here)
We should revisit our password policy and consider OAuth for third-party login. Document how
we handle PII and our GDPR obligations. No credentials or keys live in this document.
'@
Set-Content "$fx\uncertain\database.env.example" -NoNewline -Value @'
# Copy to .env and fill in real values. This template ships with placeholders.
DATABASE_URL=postgres://your-user:your-password-here@localhost:5432/yourdb
API_KEY=<your-api-key>
SESSION_SECRET=changeme
'@

$cases = @(
    @{ name = 'prod.env (AKIA + creds)'; path = "$fx\sensitive\prod.env"; expect = 'sensitive' }
    @{ name = 'server.key (private key)'; path = "$fx\sensitive\server.key"; expect = 'sensitive' }
    @{ name = 'client-record (SSN+CC)'; path = "$fx\sensitive\client-record.md"; expect = 'sensitive' }
    @{ name = 'marketing-memo'; path = "$fx\clean\marketing-memo.md"; expect = 'clean' }
    @{ name = 'refactor-plan'; path = "$fx\clean\refactor-plan.md"; expect = 'clean' }
    @{ name = 'security-notes (topics only)'; path = "$fx\uncertain\security-notes.md"; expect = 'uncertain' }
    @{ name = 'database.env.example (placeholders)'; path = "$fx\uncertain\database.env.example"; expect = 'uncertain' }
)

$pass = 0; $fail = 0
function Check($name, $got, $expect, $extra) {
    if ($got -eq $expect) { Write-Host "  PASS  $name -> $got" -ForegroundColor Green; $script:pass++ }
    else { Write-Host "  FAIL  $name -> got '$got', expected '$expect'  ($extra)" -ForegroundColor Red; $script:fail++ }
}

try {
    Write-Host "`n== File fixtures =="
    foreach ($c in $cases) {
        $r = Test-Sensitivity -Path $c.path
        Check $c.name $r.verdict $c.expect $r.reason
    }

    Write-Host "`n== Text / Partial / fail-closed cases =="
    $r = Test-Sensitivity -Text 'token: ghp_0123456789012345678901234567890123456789'
    Check 'text: github token' $r.verdict 'sensitive' $r.reason
    $r = Test-Sensitivity -Text 'The quarterly plan focuses on three growth levers.'
    Check 'text: plain prose' $r.verdict 'clean' $r.reason
    $r = Test-Sensitivity -Text 'The quarterly plan focuses on three growth levers.' -Partial
    Check 'text: plain prose -Partial' $r.verdict 'uncertain' $r.reason
    $r = Test-Sensitivity -Path "$fx\does-not-exist.xyz"
    Check 'missing file (fail-closed)' $r.verdict 'uncertain' $r.reason
    $r = Test-Sensitivity -Text 'We need to review our password policy and OAuth scopes.'
    Check 'text: topic-only' $r.verdict 'uncertain' $r.reason
}
finally {
    Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue
}

Write-Host "`n== Summary: $pass passed, $fail failed ==" -ForegroundColor ($fail -gt 0 ? 'Red' : 'Green')
exit ([int]($fail -gt 0))
