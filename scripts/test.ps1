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
New-Item -ItemType Directory -Force -Path "artifacts/test-results" | Out-Null
New-Item -ItemType Directory -Force -Path "artifacts/coverage" | Out-Null

$ran = $false
$failed = @()

# Node/TypeScript 測試
if(Test-Path 'package.json'){
  Write-Section 'Node/TypeScript 測試'
  $pm = if(Test-Path 'pnpm-lock.yaml'){'pnpm'} elseif(Test-Path 'yarn.lock'){'yarn'} elseif(Test-Path 'package-lock.json'){'npm'} else {'npm'}
  try{
    if(-not $NoInstall){
      switch($pm){
        'pnpm' { if(Has-Cmd 'pnpm'){ Try-Run pnpm 'install --frozen-lockfile' } }
        'yarn' { if(Has-Cmd 'yarn'){ Try-Run yarn 'install --frozen-lockfile' } }
        default { if(Has-Cmd 'npm'){ Try-Run npm 'ci --ignore-scripts' } }
      }
    }
    $pkg = Get-Content package.json -Raw | ConvertFrom-Json
    $hasTest = $pkg.PSObject.Properties.Name -contains 'scripts' -and ($pkg.scripts.PSObject.Properties.Name -contains 'test')
    if($hasTest){
      $ran = $true
      switch($pm){
        'pnpm' { Try-Run pnpm 'run -s test' }
        'yarn' { Try-Run yarn 'run -s test' }
        default { Try-Run npm 'test --silent' }
      }
    }
  } catch{ $failed += 'node-test'; Write-Warning $_.Exception.Message }
}

# Python 測試
if((Test-Path 'pyproject.toml') -or (Get-ChildItem -Recurse -Filter requirements*.txt -ErrorAction SilentlyContinue)){
  Write-Section 'Python 測試'
  $py = if(Has-Cmd 'python3'){'python3'} elseif(Has-Cmd 'python'){'python'} else {$null}
  if($py){
    try{
      if(-not $NoInstall){ if(Test-Path 'requirements.txt'){ & $py -m pip install -q -r requirements.txt | Out-Null } }
      if(Has-Cmd 'pytest'){ $ran = $true; Try-Run pytest '-q' }
      else { try{ & $py -m pytest -q; if($LASTEXITCODE -eq 0){ $ran = $true } else { $failed += 'pytest' } } catch{ try{ & $py -m unittest -q; if($LASTEXITCODE -eq 0){ $ran = $true } } catch{ $failed += 'python-test' } } }
    } catch{ $failed += 'python-test'; Write-Warning $_.Exception.Message }
  }
}

# .NET 測試
if((Get-ChildItem -Recurse -Filter *.sln -ErrorAction SilentlyContinue) -or (Get-ChildItem -Recurse -Filter *.csproj -ErrorAction SilentlyContinue)){
  Write-Section '.NET 測試'
  if(Has-Cmd 'dotnet'){
    try{ $ran = $true; Try-Run dotnet 'test --nologo --verbosity:minimal' } catch{ $failed += 'dotnet-test' }
  }
}

# Go 測試
if(Test-Path 'go.mod'){
  Write-Section 'Go 測試'
  if(Has-Cmd 'go'){
    try{ $ran = $true; Try-Run go 'test ./... -count=1' } catch{ $failed += 'go-test' }
  }
}

# Rust 測試
if(Test-Path 'Cargo.toml'){
  Write-Section 'Rust 測試'
  if(Has-Cmd 'cargo'){
    try{ $ran = $true; Try-Run cargo 'test --all --quiet' } catch{ $failed += 'rust-test' }
  }
}

if(-not $ran){ Write-Host '未偵測到可執行的測試，跳過並視為成功。' -ForegroundColor Yellow; exit 0 }
if($failed.Count -gt 0){ Write-Error ("測試失敗：{0}" -f ($failed -join ', ')) } else { Write-Host '所有偵測到的測試皆通過。' -ForegroundColor Green }
