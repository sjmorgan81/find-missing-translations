$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

if ($args.Count -ne 2) {
    Write-Output "Please specify some resource files."
    Write-Output "Usage: $($MyInvocation.ScriptName) file1 file2"
    exit -1
}

# Define the paths to the two .resx files
$resxFile1 = $args[0]
$resxFile2 = $args[1]

# Load the System.Windows.Forms assembly to access the ResXResourceSet class
Add-Type -AssemblyName System.Windows.Forms

# Create ResXResourceSet objects for both files
$resourceSet1 = New-Object System.Resources.ResXResourceSet -ArgumentList $resxFile1
$resourceSet2 = New-Object System.Resources.ResXResourceSet -ArgumentList $resxFile2

# Get all the keys from both resource sets
$keys1 = $resourceSet1.GetEnumerator() | ForEach-Object { $_.Key }
$keys2 = $resourceSet2.GetEnumerator() | ForEach-Object { $_.Key }

foreach ($key in $keys1) {
    $value1 = $resourceSet1.GetString($key)
    $value2 = $resourceSet2.GetString($key)

    if (-not $keys2.Contains($key)) {
        Write-Host "MISSING: '$key' (""$value1"") is missing from $resxFile2"
    }
    elseif ($value1 -eq $value2) {
        Write-Host "IDENTICAL: '$key' (""$value1"") has the same value in both files"
    }
}

foreach ($key in $keys2) {
    $value1 = $resourceSet1.GetString($key)
    $value2 = $resourceSet2.GetString($key)

    if (-not $keys1.Contains($key)) {
        Write-Host "MISSING: '$key' (""$value2"") is missing from $resxFile1"
    }
}

# Clean up the resource sets
$resourceSet1.Close()
$resourceSet2.Close()
