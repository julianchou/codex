#Requires -Version 7.0
[CmdletBinding()] param(
  [switch]$NoInstall
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version Latest

function Write-Section($t){ Write-Host "==> $t" -ForegroundColor Cyan }
function Has-Cmd($n){ return [bool](Get-Command $n -ErrorAction SilentlyContinue) }
function Try-Run([string]$cmd, [string]$args){
  Write-Host ("$cmd $args"); & $cmd $args; if ($LASTEXITCODE -ne 0) { throw "指令失敗：$cmd $args (exit $LASTEXITCODE)" }
}

New-Item -ItemType Directory -Force -Path "artifacts" | Out-Null
New-Item -ItemType Directory -Force -Path "artifacts/lint" | Out-Null

$failed = @()

Write-Section '一般檔案檢查（行尾空白）'
$includes = @('*.md','*.yml','*.yaml','*.ps1','*.psm1','*.psd1','*.json','*.ts','*.tsx','*.js','*.jsx','*.py','*.go','*.rs','*.java','*.cs')
$files = Get-ChildItem -Recurse -File -Include $includes -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\(node_modules|dist|build|\.git)\\' }
$violations = New-Object System.Collections.Generic.List[object]
foreach($f in $files){
  $m = Select-String -Path $f.FullName -Pattern '\s+$' -AllMatches -Encoding UTF8 -ErrorAction SilentlyContinue
  if($m){ foreach($mm in $m){ $violations.Add([PSCustomObject]@{ File=$f.FullName; Line=$mm.LineNumber }) } }
}
if($violations.Count -gt 0){
  Write-Warning ("發現行尾空白 {0} 處（僅列出前 20 筆）：" -f $violations.Count)
  $violations | Select-Object -First 20 | ForEach-Object { Write-Host "  $($_.File):$($_.Line)" }
  $failed += 'trailing-whitespace'
}

# PowerShell 腳本靜態分析（若可用）
Write-Section 'PowerShell 腳本分析（PSScriptAnalyzer 若可用）'
$psFiles = Get-ChildItem -Recurse -File -Include *.ps1,*.psm1 -ErrorAction SilentlyContinue
if($psFiles){
  if(Get-Module -ListAvailable -Name PSScriptAnalyzer){
    $r = Invoke-ScriptAnalyzer -Path $psFiles.FullName -Recurse -Severity Warning,Error -ErrorAction SilentlyContinue
    if($r){
      $r | Format-Table -AutoSize | Out-Host
      if(($r | Where-Object { $_.Severity -eq 'Error' }).Count -gt 0){ $failed += 'psscriptanalyzer' }
    }
  } elseif(-not $NoInstall){
    try{ Install-Module -Scope CurrentUser -Force PSScriptAnalyzer -ErrorAction Stop; Import-Module PSScriptAnalyzer -ErrorAction Stop }
    catch{ Write-Warning "PSScriptAnalyzer 安裝失敗，略過分析。" }
  }
}

# Node/TypeScript（若可用）
if(Test-Path 'package.json'){
  Write-Section 'Node/TypeScript Lint（若可用）'
  $pm = if(Test-Path 'pnpm-lock.yaml'){'pnpm'} elseif(Test-Path 'yarn.lock'){'yarn'} elseif(Test-Path 'package-lock.json'){'npm'} else {'npm'}
  if(-not $NoInstall){
    try{
      switch($pm){
        'pnpm' { if(Has-Cmd 'pnpm'){ Try-Run pnpm 'install --frozen-lockfile' } }
        'yarn' { if(Has-Cmd 'yarn'){ Try-Run yarn 'install --frozen-lockfile' } }
        default { if(Has-Cmd 'npm'){ Try-Run npm 'ci --ignore-scripts' } }
      }
    } catch{ Write-Warning $_.Exception.Message }
  }
  try{
    $pkg = Get-Content package.json -Raw | ConvertFrom-Json
    $hasLint = $pkg.PSObject.Properties.Name -contains 'scripts' -and ($pkg.scripts.PSObject.Properties.Name -contains 'lint')
    if($hasLint){
      switch($pm){
        'pnpm' { Try-Run pnpm 'run -s lint' }
        'yarn' { Try-Run yarn 'run -s lint' }
        default { Try-Run npm 'run -s lint' }
      }
    } elseif(Has-Cmd 'npx'){
      try{ Try-Run npx '-y --yes eslint . --max-warnings=0' } catch{ Write-Warning 'eslint 不可用或未設定，略過。' }
    } else { Write-Host '無可用 Lint 指令，略過。' }
  } catch{ Write-Warning '無法解析 package.json，略過 Node Lint。' }
}

# .NET（若可用）
if((Get-ChildItem -Recurse -Filter *.sln -ErrorAction SilentlyContinue) -or (Get-ChildItem -Recurse -Filter *.csproj -ErrorAction SilentlyContinue)){
  Write-Section '.NET 格式檢查（dotnet format --verify-no-changes）'
  if(Has-Cmd 'dotnet'){
    try{ Try-Run dotnet 'format --verify-no-changes' } catch{ $failed += 'dotnet-format' }
  }
}

# Go（若可用）
if(Test-Path 'go.mod'){
  Write-Section 'Go 格式檢查（gofmt -l）'
  if(Has-Cmd 'gofmt'){
    $list = (& gofmt -l .)
    if($LASTEXITCODE -ne 0){ $failed += 'gofmt'; Write-Warning 'gofmt 執行失敗。' }
    elseif($list){ $failed += 'gofmt'; Write-Warning "gofmt 有未格式化檔案：`n$list" }
  }
}

# Python（若可用）
if((Test-Path 'pyproject.toml') -or (Get-ChildItem -Recurse -Filter requirements*.txt -ErrorAction SilentlyContinue)){
  Write-Section 'Python Lint（ruff 若可用）'
  $py = if(Has-Cmd 'python3'){'python3'} elseif(Has-Cmd 'python'){'python'} else {$null}
  if($py){
    if(Has-Cmd 'ruff'){ Try-Run ruff 'check .' }
    elseif(-not $NoInstall){ try{ & $py -m pip install -q ruff | Out-Null; Try-Run ruff 'check .' } catch{ Write-Warning 'ruff 安裝失敗，略過。' } }
  }
}

if($failed.Count -gt 0){ Write-Error ("Lint 失敗：{0}" -f ($failed -join ', ')) } else { Write-Host 'Lint 全部通過或略過。' -ForegroundColor Green }
