#requires -Version 7
<#
.SYNOPSIS
  Deterministic sensitivity classifier for /pressure-test — the fail-closed gate that
  forces deep mode + egress firewalling on security / PII / credential content, so the
  escalation decision never rides on the agent's judgment.

.DESCRIPTION
  Rationale: rules whose failure produces durable wrong
  output need enforcement, not loading discipline; "triggering is judgment, not
  deterministic — a probabilistic safety net, not a hard guarantee." A missed security
  escalation is durable-consequence, so the gate is deterministic regex/keyword matching,
  not a model read. Model judgment may only RAISE sensitivity above this floor, never lower it.

  Classifies an artifact (file path OR raw text) into one of three verdicts:
    sensitive  - a HARD signal matched: a concrete secret/credential/private-key/PII pattern,
                 or a sensitive filename/extension. -> force deep + firewall egress.
    uncertain  - only SOFT signals (security/PII *topic* words, or generic key=value in an
                 .example/.sample file), OR the artifact may be incomplete (-Partial),
                 OR the scan errored. -> ask the user (interactive) / auto-deep+firewall (unattended).
    clean      - nothing matched. -> standard depth, egress open.

  FAIL-CLOSED: any read/scan error returns 'uncertain' (never 'clean'); -Partial floors a
  'clean' result up to 'uncertain'. The safe side is always more scrutiny, never less.

.PARAMETER Path
  Absolute path to the artifact file to classify.

.PARAMETER Text
  Raw artifact text to classify (use when there is no file — pasted content).

.PARAMETER Partial
  Set when the supplied Text/Path may be an excerpt rather than the complete artifact.
  Floors a 'clean' verdict up to 'uncertain' (we cannot certify content we may not fully hold).

.PARAMETER Json
  Emit the result object as compact JSON (for consumption by the orchestrator).

.OUTPUTS
  PSCustomObject: verdict, signals[] ({class,type,sample,where}), reason, scanned_chars, partial, source
#>
# Top-level params are intentionally NON-mandatory and set-free so this file can be
# dot-sourced (to import Test-Sensitivity) without triggering a parameter prompt.
# The CLI block at the bottom validates presence when the file is run directly.
param(
    [string]$Path,
    [string]$Text,
    [switch]$Partial,
    [switch]$Json
)

function Test-LuhnValid {
    param([string]$Digits)
    $d = ($Digits -replace '\D', '')
    if ($d.Length -lt 13 -or $d.Length -gt 19) { return $false }
    $sum = 0; $alt = $false
    for ($i = $d.Length - 1; $i -ge 0; $i--) {
        $n = [int][string]$d[$i]
        if ($alt) { $n *= 2; if ($n -gt 9) { $n -= 9 } }
        $sum += $n; $alt = -not $alt
    }
    return ($sum % 10 -eq 0)
}

function Test-Sensitivity {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(ParameterSetName = 'Path', Mandatory, Position = 0)][string]$Path,
        [Parameter(ParameterSetName = 'Text', Mandatory)][string]$Text,
        [switch]$Partial
    )

    $signals = [System.Collections.Generic.List[object]]::new()
    $source = $null
    $fileName = $null
    $content = $null
    $scanError = $null

    # --- Acquire content (fail-closed on error) ---
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        $source = $Path
        try {
            if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
                $scanError = "path not found or not a file"
            }
            else {
                $fileName = Split-Path -Leaf $Path
                $content = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
            }
        }
        catch { $scanError = $_.Exception.Message }
    }
    else {
        $source = '<text>'
        $content = $Text
    }

    if ($scanError) {
        $result = [pscustomobject]@{
            verdict = 'uncertain'; signals = @(); reason = "scan error (fail-closed to uncertain): $scanError"
            scanned_chars = 0; partial = [bool]$Partial; source = $source
        }
        return $result
    }
    if ($null -eq $content) { $content = '' }

    $isExampleFile = $false
    if ($fileName) {
        $isExampleFile = $fileName -match '(?i)(\.(example|sample|template|dist|spec)$|\bexample\b|\bsample\b)'
    }

    # --- Layer 1: sensitive filename / extension (HARD, unless an example file) ---
    if ($fileName) {
        $sensExt = '(?i)\.(env|pem|key|pfx|p12|keystore|jks|kdbx|ppk|asc|tfstate)$'
        $sensName = '(?i)(^|[._-])(id_rsa|id_dsa|id_ecdsa|id_ed25519|netrc|htpasswd|pgpass|credentials?|secrets?)([._-]|$)'
        if ($fileName -match $sensExt -or $fileName -match $sensName) {
            $cls = if ($isExampleFile) { 'SOFT' } else { 'HARD' }
            $signals.Add([pscustomobject]@{ class = $cls; type = 'sensitive-filename'; sample = $fileName; where = 'filename' })
        }
    }

    # --- Layer 2: high-confidence content patterns ---
    # Strong token/key/PII formats: HARD even inside an example file (they shouldn't be there).
    $strong = @(
        @{ type = 'private-key-block'; rx = '-----BEGIN (?:RSA |EC |DSA |OPENSSH |PGP |ENCRYPTED )?PRIVATE KEY-----' }
        @{ type = 'aws-access-key-id'; rx = '\bAKIA[0-9A-Z]{16}\b' }
        @{ type = 'google-api-key'; rx = '\bAIza[0-9A-Za-z_\-]{35}\b' }
        @{ type = 'slack-token'; rx = '\bxox[baprs]-[0-9A-Za-z]{8,}' }
        @{ type = 'github-token'; rx = '\bgh[pousr]_[0-9A-Za-z]{36,}\b' }
        @{ type = 'stripe-live-key'; rx = '\bsk_live_[0-9A-Za-z]{16,}\b' }
        @{ type = 'jwt'; rx = '\beyJ[A-Za-z0-9_\-]{6,}\.eyJ[A-Za-z0-9_\-]{6,}\.[A-Za-z0-9_\-]{6,}\b' }
        @{ type = 'us-ssn'; rx = '\b\d{3}-\d{2}-\d{4}\b' }
    )
    foreach ($p in $strong) {
        $m = [regex]::Match($content, $p.rx)
        if ($m.Success) {
            $samp = $m.Value; if ($samp.Length -gt 24) { $samp = $samp.Substring(0, 18) + '...[redacted]' }
            $signals.Add([pscustomobject]@{ class = 'HARD'; type = $p.type; sample = $samp; where = 'content' })
        }
    }

    # Credentialed URL (scheme://user:pass@host): structure-based, so its value may be a
    # placeholder. HARD normally, demoted to SOFT for placeholder creds or example files —
    # same treatment as a generic secret assignment (unlike the always-HARD token formats above).
    $urlM = [regex]::Match($content, '\b[a-z][a-z0-9+.\-]*://(?<ui>[^/\s:@]+:[^/\s:@]{3,})@')
    if ($urlM.Success) {
        $ui = $urlM.Groups['ui'].Value
        $isPh = $ui -match '(?i)(your[_-]|<[^>]+>|xxx|changeme|redact|example|placeholder|user:pass|todo|fixme)'
        $cls = if ($isExampleFile -or $isPh) { 'SOFT' } else { 'HARD' }
        $signals.Add([pscustomobject]@{ class = $cls; type = 'credentialed-url'; sample = '://...:[redacted]@'; where = 'content' })
    }

    # Credit-card: candidate digit runs, Luhn-validated (HARD only if Luhn passes).
    foreach ($m in [regex]::Matches($content, '\b(?:\d[ -]?){13,19}\b')) {
        if (Test-LuhnValid $m.Value) {
            $signals.Add([pscustomobject]@{ class = 'HARD'; type = 'credit-card-luhn'; sample = '****'; where = 'content' })
            break
        }
    }

    # Generic secret assignment: HARD normally, demoted to SOFT inside an example file
    # (example/sample/template files carry placeholder values, not real secrets).
    $assignRx = '(?im)\b(api[_-]?key|secret|client[_-]?secret|access[_-]?token|auth[_-]?token|password|passwd|pwd|private[_-]?key|bearer)\b\s*[:=]\s*["'']?[^\s"''#]{8,}'
    $am = [regex]::Match($content, $assignRx)
    if ($am.Success) {
        # Skip obvious placeholders (your-key-here, xxxx, <...>, changeme, redacted, example).
        $val = $am.Value
        $isPlaceholder = $val -match '(?i)(your[_-]|<[^>]+>|xxx|changeme|redact|example|placeholder|\*\*\*|todo|fixme)'
        $cls = if ($isExampleFile -or $isPlaceholder) { 'SOFT' } else { 'HARD' }
        $samp = ($val -replace '([:=]\s*["'']?).*', '$1...[redacted]')
        $signals.Add([pscustomobject]@{ class = $cls; type = 'secret-assignment'; sample = $samp; where = 'content' })
    }

    # --- Layer 3: topic keywords (SOFT — talks about security/PII but no concrete secret) ---
    $topics = @(
        'password', 'oauth', 'oidc', 'saml', 'credential', 'api key', 'private key', 'secret key',
        'encrypt', 'decrypt', 'cipher', 'tls', 'ssl', 'certificate', 'vulnerab', '\bCVE\b', 'exploit',
        'sql injection', 'xss', 'csrf', 'authn', 'authz', 'access control', 'privilege',
        'personally identifiable', '\bPII\b', '\bSSN\b', 'social security', '\bHIPAA\b', '\bPHI\b',
        '\bPCI\b', '\bGDPR\b', 'confidential', 'proprietary', 'attorney', 'indemnif', 'liability',
        'non-disclosure', '\bNDA\b', 'patient record', 'medical record', 'passport number',
        'bank account', 'routing number', '\bIBAN\b'
    )
    $topicHits = [System.Collections.Generic.List[string]]::new()
    foreach ($kw in $topics) {
        if ([regex]::IsMatch($content, "(?i)$kw")) {
            $topicHits.Add(($kw -replace '\\b', ''))
            if ($topicHits.Count -ge 6) { break }
        }
    }
    if ($topicHits.Count -gt 0) {
        $signals.Add([pscustomobject]@{ class = 'SOFT'; type = 'security-topic'; sample = ($topicHits -join ', '); where = 'content' })
    }

    # --- Verdict ---
    $hasHard = @($signals | Where-Object class -eq 'HARD').Count -gt 0
    $hasSoft = @($signals | Where-Object class -eq 'SOFT').Count -gt 0

    if ($hasHard) {
        $verdict = 'sensitive'
        $reason = 'HARD signal(s): ' + (@($signals | Where-Object class -eq 'HARD' | ForEach-Object type) -join ', ')
    }
    elseif ($hasSoft) {
        $verdict = 'uncertain'
        $reason = 'only SOFT signal(s): ' + (@($signals | Where-Object class -eq 'SOFT' | ForEach-Object type) -join ', ')
    }
    elseif ($Partial) {
        $verdict = 'uncertain'
        $reason = 'no signal but artifact may be incomplete (-Partial) — floored to uncertain'
    }
    else {
        $verdict = 'clean'
        $reason = 'no security/PII/credential signals matched'
    }

    if ($Partial -and $verdict -eq 'clean') { $verdict = 'uncertain'; $reason = 'partial artifact — floored clean->uncertain' }

    return [pscustomobject]@{
        verdict       = $verdict
        signals       = @($signals)
        reason        = $reason
        scanned_chars = $content.Length
        partial       = [bool]$Partial
        source        = $source
    }
}

# --- CLI entry: only when run directly (not dot-sourced) AND given an artifact ---
if ($MyInvocation.InvocationName -ne '.' -and ($PSBoundParameters.ContainsKey('Path') -or $PSBoundParameters.ContainsKey('Text'))) {
    $res = if ($PSBoundParameters.ContainsKey('Text')) {
        Test-Sensitivity -Text $Text -Partial:$Partial
    }
    else {
        Test-Sensitivity -Path $Path -Partial:$Partial
    }
    if ($Json) { $res | ConvertTo-Json -Depth 6 -Compress }
    else { $res | Format-List }
}
