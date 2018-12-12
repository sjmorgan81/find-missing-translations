$getTranslationRegex = "GetTranslation\(`"(?<TranslationKey>.+?)`"\)"
$getTranslationWithIconRegex = "GetTranslationWithIcon\(`".+?`", ?`"(?<TranslationKey>.+?)`"\)"

$existingTranslationKeys = New-Object 'System.Collections.Generic.HashSet[string]'
$translationKeys = New-Object 'System.Collections.Generic.HashSet[string]'

# Load the file
function findRegexInPath($regex, $filePath) {
    Get-Content $filePath | Select-String -Pattern $regex -AllMatches | Select-Object -Expand Matches | ForEach-Object {
        $match = $_.Groups["TranslationKey"].Value
        $translationKeys.Add($match) | Out-Null
    }
}

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

Get-ChildItem -Recurse -Filter "*.aspx" | ForEach-Object {
    $filePath = $_.FullName
    Write-Output "Searching for translation keys in $($filePath)"
    findRegexInPath $getTranslationRegex $filePath
    findRegexInPath $getTranslationWithIconRegex $filePath
}

Write-Host "The following translation keys seem to be missing:" -BackgroundColor Red -ForegroundColor White
# Check whether the keys we've found exist in the resource files.
$translationKeys | ForEach-Object {
    if (!$existingTranslationKeys.Contains($_)) {
        Write-Output $_
    }
}
