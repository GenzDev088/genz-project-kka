param(
  [string]$ProjectPath = "C:\OTAX\base MANTA",
  [string]$GitHubUser = "yoialdiansyah-dot",
  [string]$RepoName = "base-manta-ipa",
  [string]$GitEmail = "yoialdiansyah@gmail.com",
  [string]$GitName = "yoialdiansyah-dot",
  [string]$WorkflowName = "Build iOS IPA",
  [string]$WorkflowFile = "ios-ipa.yml",
  [string]$CommitMessage = "Add unsigned iOS IPA GitHub Actions build",
  [switch]$UseClipboardToken,
  [switch]$DownloadArtifact
)

$ErrorActionPreference = "Stop"

function Assert-Command {
  param([string]$Name)

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Command '$Name' tidak ditemukan. Install dulu lalu jalankan ulang."
  }
}

function Normalize-Token {
  param([string]$Value)

  if (-not $Value) {
    return $null
  }

  return (($Value -replace "\r", "") -replace "\n", "").Trim()
}

function Get-PlainToken {
  if ($env:GITHUB_TOKEN) {
    return Normalize-Token -Value $env:GITHUB_TOKEN
  }

  $localTokenFile = Join-Path $ProjectPath ".github-token.local"
  if (Test-Path -LiteralPath $localTokenFile) {
    $fileToken = Normalize-Token -Value (Get-Content -LiteralPath $localTokenFile -Raw)
    if ($fileToken) {
      return $fileToken
    }
  }

  if ($UseClipboardToken) {
    $clipboardToken = Normalize-Token -Value (Get-Clipboard -Raw)
    if ($clipboardToken) {
      return $clipboardToken
    }

    throw "Clipboard kosong. Copy GitHub PAT dulu lalu jalankan ulang dengan -UseClipboardToken."
  }

  $secureToken = Read-Host "Masukkan GitHub PAT" -AsSecureString
  $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)

  try {
    return Normalize-Token -Value ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr))
  }
  finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

function Get-GitHubHeaders {
  param([string]$Token)

  return @{
    Authorization = "Bearer $Token"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
  }
}

function Invoke-GitHubApi {
  param(
    [string]$Method,
    [string]$Uri,
    [string]$Token,
    $Body
  )

  $params = @{
    Method = $Method
    Uri = $Uri
    Headers = Get-GitHubHeaders -Token $Token
  }

  if ($null -ne $Body) {
    $params.Body = ($Body | ConvertTo-Json -Depth 10)
    $params.ContentType = "application/json"
  }

  try {
    return Invoke-RestMethod @params
  }
  catch {
    $statusCode = $null
    $responseBody = $null

    if ($_.Exception.Response) {
      $statusCode = $_.Exception.Response.StatusCode.value__

      try {
        $stream = $_.Exception.Response.GetResponseStream()
        if ($stream) {
          $reader = New-Object System.IO.StreamReader($stream)
          $responseBody = $reader.ReadToEnd()
          $reader.Dispose()
          $stream.Dispose()
        }
      }
      catch {
      }
    }

    if ($statusCode) {
      throw "GitHub API $Method $Uri gagal dengan status $statusCode. $responseBody"
    }

    throw
  }
}

function Get-GitHubRepo {
  param(
    [string]$RepoFullName,
    [string]$Token
  )

  try {
    return Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$RepoFullName" -Headers (Get-GitHubHeaders -Token $Token)
  }
  catch {
    $response = $_.Exception.Response
    if ($response -and $response.StatusCode.value__ -eq 404) {
      return $null
    }

    throw
  }
}

function Invoke-GitAuthenticated {
  param(
    [string[]]$Arguments,
    [string]$Token
  )

  $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("x-access-token:$Token"))
  & git -c ("http.extraheader=AUTHORIZATION: basic $basic") @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Perintah git gagal: git $($Arguments -join ' ')"
  }
}

function Get-GitRemoteUrl {
  param([string]$RemoteName)

  $remoteNames = @(git remote)
  if ($LASTEXITCODE -ne 0) {
    throw "Gagal membaca daftar remote git."
  }

  if ($RemoteName -notin $remoteNames) {
    return $null
  }

  $remoteUrl = git remote get-url $RemoteName
  if ($LASTEXITCODE -ne 0) {
    throw "Gagal membaca URL remote '$RemoteName'."
  }

  return $remoteUrl
}

function Wait-WorkflowRun {
  param(
    [string]$RepoFullName,
    [string]$WorkflowFile,
    [string]$Branch,
    [string]$Token
  )

  $run = $null

  for ($attempt = 0; $attempt -lt 24; $attempt++) {
    Start-Sleep -Seconds 5
    $runs = Invoke-GitHubApi -Method Get -Uri "https://api.github.com/repos/$RepoFullName/actions/workflows/$WorkflowFile/runs?branch=$Branch&event=workflow_dispatch&per_page=5" -Token $Token
    $run = $runs.workflow_runs | Select-Object -First 1
    if ($run) {
      break
    }
  }

  if (-not $run) {
    throw "Workflow berhasil dipicu, tetapi run belum muncul di GitHub Actions."
  }

  while ($true) {
    $run = Invoke-GitHubApi -Method Get -Uri "https://api.github.com/repos/$RepoFullName/actions/runs/$($run.id)" -Token $Token
    Write-Host "Workflow status: $($run.status) / $($run.conclusion)"

    if ($run.status -eq "completed") {
      return $run
    }

    Start-Sleep -Seconds 10
  }
}

function Download-WorkflowArtifact {
  param(
    [string]$RepoFullName,
    [string]$Token,
    [int64]$RunId,
    [string]$DestinationDir
  )

  $artifacts = Invoke-GitHubApi -Method Get -Uri "https://api.github.com/repos/$RepoFullName/actions/runs/$RunId/artifacts" -Token $Token
  $artifact = $artifacts.artifacts | Select-Object -First 1

  if (-not $artifact) {
    throw "Artifact belum tersedia untuk run $RunId."
  }

  if (-not (Test-Path -LiteralPath $DestinationDir)) {
    New-Item -ItemType Directory -Path $DestinationDir | Out-Null
  }

  $zipPath = Join-Path $DestinationDir "$($artifact.name).zip"
  Invoke-WebRequest -Uri $artifact.archive_download_url -Headers (Get-GitHubHeaders -Token $Token) -OutFile $zipPath
  Write-Host "Artifact downloaded ke: $zipPath"

  $extractDir = Join-Path $DestinationDir $artifact.name
  if (Test-Path -LiteralPath $extractDir) {
    Remove-Item -LiteralPath $extractDir -Recurse -Force
  }

  Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

  $ipa = Get-ChildItem -Path $extractDir -Filter *.ipa -Recurse | Select-Object -First 1
  if ($ipa) {
    Write-Host "File IPA siap dipakai di: $($ipa.FullName)"
  }
  else {
    Write-Host "Artifact berhasil diekstrak ke: $extractDir"
  }
}

Assert-Command git

if (-not (Test-Path -LiteralPath $ProjectPath)) {
  throw "Project path tidak ditemukan: $ProjectPath"
}

Set-Location $ProjectPath

if (-not (Test-Path -LiteralPath ".git")) {
  git init | Out-Null
}

git config user.name $GitName
git config user.email $GitEmail

$currentBranch = git branch --show-current
if (-not $currentBranch) {
  git branch -M main
}
elseif ($currentBranch -ne "main") {
  git branch -M main
}

$token = Get-PlainToken
$repoFullName = "$GitHubUser/$RepoName"

try {
  $repo = Get-GitHubRepo -RepoFullName $repoFullName -Token $token

  if (-not $repo) {
    Invoke-GitHubApi -Method Post -Uri "https://api.github.com/user/repos" -Token $token -Body @{
      name = $RepoName
      private = $false
    } | Out-Null
  }

  $originUrl = Get-GitRemoteUrl -RemoteName "origin"
  if (-not $originUrl) {
    git remote add origin "https://github.com/$repoFullName.git"
  }
  elseif ($originUrl -notmatch [Regex]::Escape("$repoFullName.git")) {
    git remote set-url origin "https://github.com/$repoFullName.git"
  }

  git add .

  $hasChanges = git status --porcelain
  if ($hasChanges) {
    git commit -m $CommitMessage
  }

  Invoke-GitAuthenticated -Arguments @("push", "-u", "origin", "main") -Token $token

  Invoke-GitHubApi -Method Post -Uri "https://api.github.com/repos/$repoFullName/actions/workflows/$WorkflowFile/dispatches" -Token $token -Body @{
    ref = "main"
  } | Out-Null

  $run = Wait-WorkflowRun -RepoFullName $repoFullName -WorkflowFile $WorkflowFile -Branch "main" -Token $token

  if ($run.conclusion -ne "success") {
    throw "Workflow selesai dengan status '$($run.conclusion)'. Cek GitHub Actions untuk log detail."
  }

  if ($DownloadArtifact) {
    Download-WorkflowArtifact -RepoFullName $repoFullName -Token $token -RunId $run.id -DestinationDir ".\downloaded-ipa"
  }
}
finally {
  Remove-Variable token -ErrorAction SilentlyContinue
}
