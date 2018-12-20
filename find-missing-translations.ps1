# Traverses the current directory searching for files that make use of GetTranslation and GetTranslationWithIcon

$getTranslationRegex = "GetTranslation\(`"(?<TranslationKey>.+?)`"\)"
$getTranslationWithIconRegex = "GetTranslationWithIcon\(`".+?`", ?`"(?<TranslationKey>.+?)`"\)"

$existingTranslationKeys = New-Object 'System.Collections.Generic.HashSet[string]'
$usedTranslationKeys = New-Object 'System.Collections.Generic.HashSet[string]'

# Search for occurencdes of the specified regular expression in the specified file.
function findRegexInPath($regex, $filePath) {
    Get-Content $filePath | Select-String -Pattern $regex -AllMatches | Select-Object -Expand Matches | ForEach-Object {
        $match = $_.Groups["TranslationKey"].Value
        $usedTranslationKeys.Add($match) | Out-Null
    }
}

# Load translation keys from the specified file.
function loadExistingTranslationKeys($filePath) {
    [xml]$XmlDocument = Get-Content $filePath
    $XmlDocument.root.data | ForEach-Object {
        $existingTranslationKeys.Add($_.name) | Out-Null
    }
}

if ($args.Count -eq 0) {
    Write-Output "Please specify some resource files."
    Write-Output "Usage: $($MyInvocation.ScriptName) [file1 [file2 [...]]]"
    exit -1
}

# Load a collection of existing keys from the resource files specified on the command line.
foreach ($filePath in $args) {
    Write-Output "Loading translation keys from $($filePath)..."
    loadExistingTranslationKeys $filePath
}

# Recursively search the current directory searching for files that make use of translations.
Get-ChildItem -Recurse -Include "*.aspx", "*.ascx" | ForEach-Object {
    $filePath = $_.FullName
    Write-Output "Searching for translation keys in $($filePath)"
    findRegexInPath $getTranslationRegex $filePath
    findRegexInPath $getTranslationWithIconRegex $filePath
}

Write-Host "The following translation keys seem to be missing:" -BackgroundColor Red -ForegroundColor White
# Check whether the keys we've found exist in the resource files.
$usedTranslationKeys | ForEach-Object {
    if (!$existingTranslationKeys.Contains($_)) {
        Write-Output $_
    }
}
