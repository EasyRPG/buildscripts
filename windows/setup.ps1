# Dependency generator for the Win32-Toolchain to compile EasyRPG Player
# Licensed under WTFPL

## Config

# XML tags to add to Release build when DebugFast is set
$debug_fast = "<Optimization>MaxSpeed</Optimization>
        <EnableEnhancedInstructionSet>StreamingSIMDExtensions2</EnableEnhancedInstructionSet>
        <BasicRuntimeChecks>Default</BasicRuntimeChecks>"

# GUID to use for projects (must contain XXXX somewhere)
$guid = "d46f955b-XXXX-48b2-a4df-983b1eaf5945".ToUpper()

$project_template = "templates/template.vcxproj"
$solution_template = "templates/template.sln"
$solution_template2 = "templates/template.global.sln"
$project_dir = "projects"
$patch_dir = "patches"
$sln_name = "easyrpg-win32-libs.sln"

## End of Config

## JSON format
#    "XXX": {
#       "Source": "Link for download, must be tar.gz or tar.bz",
#       "BaseDir": "Base path of HeaderDirs, IncludeDirs and SourceDirs, auto detected from Source if missing"
#       "Preprocessor": ["Preprocessor definitions for all targets"]
#       "Preprocessor_Debug_x86": ["Preprocessor for Debug x86 only"],
#       "Preprocessor_Debug_amd64": ["Preprocessor for Debug amd64 only"],
#       "Preprocessor_Release_x86": ["Preprocessor for Release x86 only"],
#       "Preprocessor_Release_amd64": ["Preprocessor for Release amd64 only"],
#       "Preprocessor_Debug_arm: ["Preprocessor for Debug ARM only"],
#       "Preprocessor_Release_arm: ["Preprocessor for Release ARM only"],
#       "IncludeDirs": ["Directories passed as additional include dirs to the compiler"],
#       "HeaderDirs": ["Directories containing *.h files copied to the install dir (EASYDEV_MSVC/include)"],
#       "HeaderTargetDir": "Copy to a subdirectory of the install dir",
#       "HeaderDirsRecursive: Bool (default: False). Copies the whole HeaderDir folders to the install dir.
#       "SourceFiles": ["c/cpp files to include for compiling"],
#       "SourceDirs": ["Directories to scan for c/cpp files for compiling"],
#       "SourceExcludes" ["Files to exclude in SourceDirs"],
#       "DebugFast": Bool (default: False). Writes $debug_fast in release section
#    }
#
##

function Get-ScriptDirectory {
    # via https://stackoverflow.com/q/5466329/
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if ($Invocation.PSScriptRoot) {
        $Invocation.PSScriptRoot
    } Elseif ($Invocation.MyCommand.Path) {
        Split-Path $Invocation.MyCommand.Path
    } else {
        $Invocation.InvocationName.Substring(0, $Invocation.InvocationName.LastIndexOf("\"))
    }
}

if (!(Test-Path env:EASYDEV_MSVC)) {
    # Create permanent env var
    [Environment]::SetEnvironmentVariable("EASYDEV_MSVC", "$(Get-ScriptDirectory)/build")
}

Write-Output "EasyRPG Dependency Generator for Win32"

# Add msys to PATH
$env:PATH = "$(Get-ScriptDirectory)/msys/bin;$($env:PATH)"

# Prevent "patch.exe" triggering UAC because of the filename
$env:__COMPAT_LAYER = "RunAsInvoker"

# Powershell aliases wget and diff
while (Test-Path Alias:wget) {
    Remove-Item Alias:wget -Force
}
while (Test-Path Alias:diff) {
    Remove-Item Alias:diff -Force
}

# Read depencies.json
try {
    $deps = Get-Content dependencies.json | Out-String | ConvertFrom-Json
} catch [ArgumentException] {
    Write-Error $_
    Write-Error "JSON (dependencies.json) is invalid"
    exit
}

if (Test-Path projects) {
    echo "Cleaning up previous invocation"
    Remove-Item Projects -Force -Recurse
}

mkdir projects | Out-Null

# Download files
foreach ($name in $deps.psobject.properties.name) {
    $item = $deps.$name
    if ($item.Source) {
        echo "Downloading $name"
        wget $item.Source -P $project_dir --no-check-certificate 2>&1 | Out-Null
        if ($?) {
            Write-Error "Downloading $name failed"
            exit
        }
    }
}


# Extract files
foreach ($name in $deps.psobject.properties.name) {
    $item = $deps.$name
    if ($item.Source) {
        $uri = (New-Object -TypeName Uri -ArgumentList $item.Source)
        $filename = $uri.Segments[-1]
        $filename_split = $filename.Split(".")

        if ($filename_split[-1] -eq "tgz") {
            $split = 2
        } else {
            $split = 3
        }

        if (($filename_split[-2] -ne "tar") -and ($filename_split[-1] -ne "tgz")) {
            Write-Error "File must be tar archive"
            exit
        }

        if (!(Test-Path "$project_dir/$filename")) {
            Write-Error "File $filename not found"
            exit
        }

        Write "Extracting $name"
        tar "xf" "$project_dir/$filename" -C $project_dir

        # Determine base dir automatically if not provided
        if (!($item.BaseDir)) {
            $base_dir = $filename_split[0..($filename_split.length - $split)] -join "."
            $item = $item | Add-Member -PassThru NoteProperty BaseDir $base_dir
        }
    }
}

# Apply patches
foreach ($name in $deps.psobject.properties.name) {
    if (Test-Path "$patch_dir/$name.patch") {
        cat "$patch_dir/$name.patch" | patch -p1 -d $project_dir
    }
}

# GUID for C++ projects
$guid_main = "8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942"
$guid_count = 0

# Generate vcxproj
$vcxproj_template = Get-Content $project_template

$script_dir = $(Get-ScriptDirectory)

foreach ($name in $deps.psobject.properties.name) {
    $item = $deps.$name
    $item = $item | Add-Member -PassThru NoteProperty Guid $guid.Replace("XXXX", (++$guid_count).ToString().PadLeft(4, '0'))
    $template = $vcxproj_template
    $template = $template.Replace("{GUID}", $item.Guid)
    $template = $template.Replace("{Name}", $name)
    $template = $template.Replace("{Preprocessor}", $item.Preprocessor -join ";")
    $template = $template.Replace("{Preprocessor_Debug_x86}", $item.Preprocessor_Debug_x86 -join ';')
    $template = $template.Replace("{Preprocessor_Release_x86}", $item.Preprocessor_Release_x86 -join ';')
    $template = $template.Replace("{Preprocessor_Debug_amd64}", $item.Preprocessor_Debug_amd64 -join ';')
    $template = $template.Replace("{Preprocessor_Release_amd64}", $item.Preprocessor_Release_amd64 -join ';')
    $template = $template.Replace("{Preprocessor_Debug_arm}", ($item.Preprocessor_Debug_arm -join ';') + ";_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1")
    $template = $template.Replace("{Preprocessor_Release_arm}", ($item.Preprocessor_Release_arm -join ';') + ";_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1")
    $template = $template.Replace("{IncludeDirs}", ($item.IncludeDirs | ForEach-Object {"$($item.BaseDir)/$_"}) -join ';')
    if ($item.DebugFast) {
        $template = $template.Replace("{DebugFast}", $debug_fast)
    } else {
        $template = $template.Replace("{DebugFast}", "")
    }

    # Generate HeaderDirs list
    if ($item.HeaderDirs) {
        $filelist = @()
        foreach ($searchdir in $item.HeaderDirs) {
            $searchdir = $searchdir.Replace("/", "\")
            if ($item.HeaderTargetDir) {
                $incdir = ($item.HeaderTargetDir).Replace("/", "\")
            } else {
                $incdir = $null
            }
            if ($item.HeaderDirsRecursive) {
                # Simplification: Recursive copies everything instead of *.h only
                $filelist += ("xcopy /Y /I /S $($item.BaseDir)\$searchdir $env:EASYDEV_MSVC\include\$incdir")
            } else {
                $filelist += ("xcopy /Y /I $($item.BaseDir)\$searchdir\*.h $env:EASYDEV_MSVC\include\$incdir")
            }
        }
        $template = $template.Replace("{PostBuildEvent}", "<Command>call $name.cmd</Command>")
        $filelist -join "`r`n" | Out-File "$project_dir/$name.cmd" -Encoding Default
    } else {
        $template = $template.Replace("{PostBuildEvent}", "")
    }

    # Generate SourceFiles file list
    $filelist = @()
    foreach ($file in $item.SourceFiles) {
        $filelist += ($script_dir+"/"+$project_dir+"/"+$item.BaseDir+"/"+$file).Replace("/", "\")
    }

    # Generate SourceDirs file list
    $fileout = @()
    if ($item.SourceExcludes) {
        $item.SourceExcludes = $item.SourceExcludes | % { $_.Replace("/", "\") }
    }
    foreach ($searchdir in $item.SourceDirs) {
        if ($item.SourceDirsRecursive) {
            $dirlist = dir ("$project_dir/$($item.BaseDir)/$searchdir") -Recurse
        } else {
            $dirlist = dir ("$project_dir/$($item.BaseDir)/$searchdir")
        }
        foreach ($exclude in $item.SourceExcludes) {
            $dirlist = $dirlist | Where-Object {$_.FullName -notlike "*$exclude*"}
        }
        $filelist += ($dirlist |
            Where-Object {$_.FullName.EndsWith(".c") -or $_.FullName.EndsWith(".cpp")}).FullName
    }
    foreach ($file in $filelist) {
        $fileout += ("<ClCompile Include=`"$($file.Substring(($script_dir+"/"+$project_dir).Length+1))`" />")
    }
    $template = $template.Replace("{SourceDirs}", $fileout -join "`r`n    ")

    Write-Output "Generating $name.vcxproj"
    $template | Out-File "$project_dir/$name.vcxproj" -Encoding UTF8
}

# Generate sln
$template = Get-Content $solution_template
$template_global = Get-Content $solution_template2

# Generate GUID list of dependencies
foreach ($name in $deps.psobject.properties.name) {
    $item = $deps.$name
    $dep_guids = @()

    foreach ($dep in $item.DependsOn) {
        $dep_guids += $deps.$dep.Guid
    }

    $item = $item | Add-Member -PassThru NoteProperty DependsOnGuid $dep_guids
}

# Create entries in sln
$project_out = $null
$glob_out = $null

foreach ($name in $deps.psobject.properties.name) {
    $item = $deps.$name
    $item_guid = $item.Guid
    $project_out += "Project(`"{$guid_main}`") = `"$name`", `"$project_dir\$name.vcxproj`", `"{$item_guid}`"`r`n"
    if ($item.DependsOnGuid) {
        $project_out += "`tProjectSection(ProjectDependencies) = postProject`r`n"
        foreach ($dep_guid in $item.DependsOnGuid) {
            $project_out += "`t"*2
            $project_out += "{$dep_guid} = {$dep_guid}`r`n"
        }
        $project_out += "`t"
        $project_out += "EndProjectSection`r`n"
    }
    $project_out += "EndProject`r`n"

    $glob_out += $template_global.Replace("{Guid}", "$item_guid")
}

$template = $template.Replace("{Projects}", $project_out)
$template = $template.Replace("{GlobalSection}", $glob_out -join "`r`n")
Write-Output "Generating $sln_name"
$template | Out-File $sln_name -Encoding UTF8
Write-Output "Done!"
