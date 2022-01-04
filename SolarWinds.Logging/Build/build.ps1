param(
    [Parameter(Position=0,Mandatory=0)]
    [string[]]$taskList = @(),
    [Parameter(Position=1,Mandatory=0)]
    [string]$workingDirectory,
    [Parameter(Position=2,Mandatory=0)]
    [switch]$resetBuildFramework = $false,
    [Parameter(Position=3,Mandatory=0)]
    [switch]$isPersonal = $false,
    [Parameter(Position=4,Mandatory=0)]
    [string]$buildFile,
    [Parameter(Position=5,Mandatory=0)]
    [string]$framework,
    [Parameter(Position=6,Mandatory=0)]
    [switch]$docs = $false,
    [Parameter(Position=7,Mandatory=0)]
    [System.Collections.Hashtable]$parameters = @{},
    [Parameter(Position=8, Mandatory=0)]
    [System.Collections.Hashtable]$properties = @{},
    [Parameter(Position=9, Mandatory=0)]
    [alias("init")]
    [scriptblock]$initialization = {},
    [Parameter(Position=10, Mandatory=0)]
    [switch]$nologo = $false,
    [Parameter(Position=11, Mandatory=0)]
    [switch]$help = $false,
    [Parameter(Position=12, Mandatory=0)]
    [string]$scriptPath,
    [Parameter(Position=13,Mandatory=0)]
    [switch]$detailedDocs = $false
)    


# get working directory path
if ( !$workingDirectory )
{
	$Global:rootPath = Split-Path $PSScriptRoot -Parent
}
else
{
	$Global:rootPath = $workingDirectory
}

Set-Location $Global:rootPath

$buildTempPath = join-path $Global:rootPath 'bin/BuildTempFiles'

# default values for paket.exe and Build package
$defaultPaketClientPath = 'http://dev-artifactory.dev.local/artifactory/nuget-3rdParty/Paket/paket.exe'


# delete old packages if needed
if ( $resetBuildFramework -and (Test-Path $buildTempPath) )
{
	Remove-Item -Recurse -Force $buildTempPath
}

# paket.exe path
$paketClientPath = $Env:PaketClientPath
if ( !$paketClientPath )
{
	$paketClientPath = $defaultPaketClientPath
}

# local paths for paket files
$paketDirectoryPath = Join-Path $buildTempPath 'Paket'
$paketClientLocalPath = Join-Path $paketDirectoryPath 'paket.exe'
$paketDependenciesLocalPath = Join-Path $buildTempPath 'paket.dependencies'
$paketClientLocalPathTemp = $paketClientLocalPath + '.tmp'


# create directory structure for BuildFramework related parts
if (-not (Test-Path $buildTempPath -pathType container))
{
	New-Item $buildTempPath -type directory
}
if (-not (Test-Path $paketDirectoryPath) )
{
	New-Item $paketDirectoryPath -type directory
}

# check / delete temporary paket.exe and paket.dependencies
if (Test-Path $paketClientLocalPathTemp)
{
	Remove-Item $paketClientLocalPathTemp -Force
}

# download recent paket.exe as temporary
$wc = (New-Object System.Net.WebClient)
$wc.DownloadFile($paketClientPath, $paketClientLocalPathTemp)
$wc.Dispose()

# try update current version with recently downloaded ones
if (Test-Path $paketClientLocalPathTemp)
{
	if (Test-Path $paketClientLocalPath)
	{
		Remove-Item $paketClientLocalPath -Force
	}
	Rename-Item $paketClientLocalPathTemp $paketClientLocalPath
}

# Set location to fill structure expected by paket.exe
$paketDependenciesPath = Join-Path $Global:rootPath 'build\paket.dependencies'
if (Test-Path $paketDependenciesPath){
	Copy-Item -Path $paketDependenciesPath -Destination $buildTempPath -Force
}
else {
	Write-Error ('Paket.dependencies file for build package definition was not found on path ' + $paketDependenciesPath)
}


Set-Location $paketDirectoryPath

# download SwBuild package and it's dependencies
& $paketClientLocalPath install

$swBuildDependencyPackagesPath = Join-Path $buildTempPath 'packages'
$swBuildPackagePath = Join-Path $swBuildDependencyPackagesPath 'SolarWinds.Build'

if (-not (Test-Path $swBuildPackagePath -PathType Container))
{
	Write-Error 'SW Build package directory was not found!'
}
$swBuildPackagePath = Join-Path $swBuildPackagePath 'content\Scripts\build.ps1'
if (-not (Test-Path $swBuildPackagePath -PathType Leaf))
{
	Write-Error 'SW Build package directory root is missing expected build.ps1 file!'
}

# run build from downloaded package and pass params
& $swBuildPackagePath -rootPath $Global:rootPath -isPersonal $isPersonal -buildFile $buildFile -taskList $taskList -framework $framework -parameters $parameters -properties $properties -initialization $initialization -nologo $nologo -help $help -scriptPath $scriptPath 

if (-not $psake.build_success) { 
    $exitCode=([int]$LASTEXITCODE, 1 -ne 0)[0]
	Write-Host ("Exit code should be " + $LASTEXITCODE)
	Write-Host ("Psake result is " + $psake.build_success)
    $Host.SetShouldExit($exitCode)
	Write-Host "I set SetShouldExit"
    exit $exitCode
}

return 0