$ErrorActionPreference = 'Stop';

$packageName = 'academic-workflow-suite'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = 'https://github.com/academicworkflow/suite/releases/download/v{{VERSION}}/academic-workflow-suite-{{VERSION}}-x86_64.msi'

$packageArgs = @{
  packageName    = $packageName
  fileType       = 'MSI'
  url64bit       = $url64
  softwareName   = 'Academic Workflow Suite*'
  checksum64     = '{{CHECKSUM}}'
  checksumType64 = 'sha256'
  silentArgs     = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs

Write-Host "Academic Workflow Suite has been installed successfully!" -ForegroundColor Green
Write-Host "Run 'aws --help' to get started." -ForegroundColor Cyan
