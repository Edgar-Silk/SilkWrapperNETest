# Script to build PDFium.DLL  -- Includes depot_tools
# Arguments
param (
    # Options: x86 | x64
    [string]$Arch ='x64',
    # Not use at the moment
    [string]$Wrapper_Branch  = ' '
)

# Globals
$BuildDir       = (Get-Location).path

# Configuration:
Write-Host "Architecture: " $Arch
Write-Host "Wrapper branch: " $Pdfium_Branch
Write-Host "Directory to Build: " $BuildDir

# Set environmental variables 
$env:Path = "$BuildDir/depot_tools;$env:Path"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
$env:DEPOT_TOOLS_UPDATE = "0"

# Set directory variable
$WrapperDir = $BuildDir+'/Wrapper'

# Set build temporary path
if ([System.IO.Directory]::Exists($WrapperDir)) {
    Set-Location $WrapperDir
}
else {
    New-Item -Path $WrapperDir -ItemType Directory
    Set-Location $WrapperDir
}

# Visual Studio MSI-Builder - Find and set compiler
Write-Host "Locate VS 2017 MSBuilder.exe"
function buildVS {
    param (
        [parameter(Mandatory=$true)]
        [String] $path,
            
        [parameter(Mandatory=$false)]
        [bool] $clean = $true
    )
    process {
        $msBuildExe = Resolve-Path "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2017/*/MSBuild/*/bin/msbuild.exe" -ErrorAction SilentlyContinue
      
        if ($clean) {
            Write-Host "Cleaning $($path)" -foregroundcolor green
            & "$($msBuildExe)" "$($path)" /t:Clean /m 
        }

        Write-Host "Building $($path)" -foregroundcolor green
        & "$($msBuildExe)" "$($path)" /t:Build /m /p:Configuration=Release,Platform=$Arch /v:n
    }
}

# Get Git hub project
$Project_Name = 'SilkWrapperNET'
Write-Host "Getting Wrapper repository from github"

git clone -q --branch=master 'https://github.com/Edgar-Silk/SilkWrapperNET' 

Set-Location $WrapperDir'/'$Project_Name

buildVS -path ./SilkWrapperNET.sln 

# Check if the DLL exist. Then, copy to Wrapper/Lib
Write-Host "Checking for PDFium.DLL library..."
Set-Location $BuildDir'/pdfium'

if ($Arch -eq 'x64') {
    $OUT_DLL_DIR = $BuildDir + '/Lib/x64'
}
elseif ($Arch -eq 'x86') {
    $OUT_DLL_DIR = $BuildDir + '/Lib/x86'
}
else {
    Write-Host "Arch not defined or invalid..."
    Exit
}

# Copy to solution project directory
Write-Host "Copy pdfium DLL to Wrapper solution project"

$Lib_Dir  = $WrapperDir+"/"+$Project_Name+"/"+$Project_Name+"/lib/"+$Arch

if ([System.IO.Directory]::Exists( $Lib_Dir )) {
    Set-Location $Lib_Dir
}
else {
    New-Item -Path $Lib_Dir -ItemType Directory
    Set-Location $Lib_Dir
}

if (Test-Path -Path $OUT_DLL_DIR'/pdfium.dll') {
    Copy-Item $OUT_DLL_DIR'/pdfium.dll' -Destination $Lib_Dir
}

# Make NuGet package
Write-Host "Make NuGet Package..."

Set-Location $WrapperDir"/"$Project_Name"/"$Project_Name
nuget pack SilkWrapperNET.csproj -properties "Configuration=Release;Platform=$Arch"

# Set build temporary path
$OUT_NUGET_DIR = $BuildDir+'/NuGet/'+$Arch

# Copy final NuGet package
if ([System.IO.Directory]::Exists($OUT_NUGET_DIR)) {
    Set-Location $OUT_NUGET_DIR
}
else {
    New-Item -Path $OUT_NUGET_DIR -ItemType Directory
    Set-Location $OUT_NUGET_DIR
}

Write-Host 'Copy NuGet files output to: ' $OUT_NUGET_DIR

Copy-Item -Path "$WrapperDir/$Project_Name/$Project_Name/*.*.*.*.nupkg" -Destination $OUT_NUGET_DIR


Set-Location $BuildDir