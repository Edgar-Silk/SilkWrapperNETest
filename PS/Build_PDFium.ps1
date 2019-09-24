# Script to build PDFium.DLL  -- Includes depot_tools
# Arguments
param(
    # Options: x86 | x64
    [string]$Arch ='x64',
    # Chromium/3907, from https://pdfium.googlesource.com/pdfium/
    [string]$Pdfium_Branch  = 'eb590e0e22e9119779befd7d5d6763b0dac91119',
    # Depot_tools, from  https://chromium.googlesource.com/chromium/tools/depot_tools/f73f0f401a6b895ebb32839e1b82e4e42bfb6dea  
    [string]$Depot_Branch   = 'f73f0f401a6b895ebb32839e1b82e4e42bfb6dea'  
)

# Globals
$BuildDir       = (Get-Location).path

# Configuration:
Write-Host "Architecture: " $Arch
Write-Host "PDFium branch: " $Pdfium_Branch
Write-Host "Depot_tools branch: " $Depot_Branch
Write-Host "Directory to Build: " $BuildDir

# Check for Depot_tools
Write-Host "Checking for depot_tools directory ..."

# Set environmental variables 
$env:Path = "$BuildDir/depot_tools;$env:Path"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
$env:DEPOT_TOOLS_UPDATE = "0"

#Check if we have "depot_tools" directory
if ([System.IO.Directory]::Exists($BuildDir+'/depot_tools')) {
    Write-Host "Directory found!"
    Set-Location $BuildDir'/depot_tools'
}
else {
    # Download depot_tools from google repository
    Write-Host "Directory not Found"
    
    git clone -q --branch=master https://chromium.googlesource.com/chromium/tools/depot_tools

    Set-Location $BuildDir'/depot_tools'

    git status

    #Here, we select the active branch
    git checkout $Depot_Branch
    
}

Write-Host "Testing 'gclient' command for the first time. This will configure python and git on Windows"
gclient 
# Finish setting up depot_tools

# Start setting up PDFium repository
Set-Location $BuildDir

# Here, takes time to download and set up
Write-Host "Checking PDFium repository branch: " $Pdfium_Branch 

gclient config --unmanaged https://pdfium.googlesource.com/pdfium.git

gclient sync --revision "$Pdfium_Branch" -R

## Patch for BUILD.gn
Set-Location $BuildDir'/pdfium' 

#Start patching the configuration BUILD.gn
Write-Host "Start patching BUILD.gn"

#Copy the original file
if (-Not (Test-Path -Path $BuildDir'/pdfium/BUILD.ORG.gn')) {
    Copy-Item './BUILD.gn' './BUILD.ORG.gn'
}

# Set file name
$File = './BUILD.ORG.gn'
$FileOut = './BUILD.mod.gn'

# Process lines of text from file and assign result to $NewContent variable
$NewContent = Get-Content -Path $File |
    ForEach-Object {
        # Output the existing line to pipeline in any case
        
        # If line matches regex
        if ($_ -match ([regex]::Escape('PNG_USE_READ_MACROS'))) {
            # Add output additional line
            $_
            '    "FPDFSDK_EXPORTS",'
        }
        
        elseif ($_ -match ('jumbo_component.+')) {
            # Add output additional line
            'shared_library("pdfium") {'
        }

        elseif ($_ -match ('complete_static_lib.+')) {
            # Add output additional line
            '    complete_shared_lib = true'
        }
        
        elseif ($_ -match ([regex]::Escape('public_configs = [ ":pdfium_public_config" ]'))) {
            # Add output additional line
            $_
            '  sources = []'
        }

        else { $_ }

    }

# Write content of $NewContent variable back to file
$NewContent | Out-File -FilePath $FileOut -Encoding Default -Force

Copy-Item './BUILD.mod.gn' './BUILD.gn' -Force

Write-Host "Finish patching BUILD.gn"

# Patch for pdfview.h

Write-Host "Start patching fpdfview.h"

Set-Location $BuildDir'/pdfium/public' 

#Copy the original file
if (-Not (Test-Path -Path $BuildDir'/pdfium/public/fpdfview.ORG.h')) {
    Copy-Item './fpdfview.h' './fpdfview.ORG.h'
}

# Set file name
$File = './fpdfview.ORG.h'
$FileOut = './fpdfview.mod.h'

# Process lines of text from file and assign result to $NewContent variable
$NewContent = Get-Content -Path $File |
    ForEach-Object {
        # Output the existing line to pipeline in any case
        
        # If line matches regex
        if ($_ -match ('^' + [regex]::Escape('#if defined(COMPONENT_BUILD)'))) {
            # Add output additional line
            '//#if defined(COMPONENT_BUILD)'
        }

        elseif ($_ -match ('^' + [regex]::Escape('#endif  // defined(WIN32)'))) {
            # Add output additional line
            $_
            '/**'
        }
        
        elseif ($_ -match ('^'+ [regex]::Escape('#endif  // defined(COMPONENT_BUILD)'))) {
            # Add output additional line
            $_
            '**/'
        }

        else { $_ }

    }

# Write content of $NewContent variable back to file
$NewContent | Out-File -FilePath $FileOut -Encoding Default -Force

Copy-Item './fpdfview.mod.h' './fpdfview.h' -Force

Write-Host "Finish patching fpdfview.h"

# Start patching the configuration fpdfview.h
Set-Location $BuildDir'/pdfium'

if ($Arch -eq 'x64') {
    $GN_ARGS = 'is_component_build = false is_official_build = true is_debug = false pdf_enable_v8 = false pdf_enable_xfa = false pdf_is_standalone = true  current_cpu=\"x64\" target_cpu=\"x64\" '
    $GN_OUTDIR = 'out/sharedReleasex64'
    $OUT_DLL_DIR = $BuildDir + '/Lib/x64'
}
elseif ($Arch -eq 'x86') {
    $GN_ARGS = 'is_component_build = false is_official_build = true is_debug = false pdf_enable_v8 = false pdf_enable_xfa = false pdf_is_standalone = true  current_cpu=\"x86\" target_cpu=\"x86\" '
    $GN_OUTDIR = 'out/sharedReleasex86'
    $OUT_DLL_DIR = $BuildDir + '/Lib/x86'
}
else {
    Write-Host "Arch not defined or invalid..."
    Exit
}

# Configuration with 'gn' command
Write-Host 'Configure gn with --args='$GN_ARGS
gn gen $GN_OUTDIR --args=$GN_ARGS 

# Compiling
Write-Host 'Compiling with ninja... '
ninja -C $GN_OUTDIR  pdfium

# Check for the Directory existence
if ([System.IO.Directory]::Exists($OUT_DLL_DIR)) {
    Set-Location $OUT_DLL_DIR
}
else {
    New-Item -Path $OUT_DLL_DIR -ItemType Directory
    Set-Location $OUT_DLL_DIR
}

# Copy the Output library to Lib/x64 or Lib/x86
Write-Host 'Copy DLL files output to:' $OUT_DLL_DIR

Copy-Item -Path "$BuildDir/pdfium/$GN_OUTDIR/pdfium.*" -Destination $OUT_DLL_DIR

Set-Location $BuildDir