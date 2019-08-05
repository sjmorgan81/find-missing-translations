# Traverses the current directory searching for files that make use of GetTranslation and GetTranslationWithIcon

$getTranslationRegex = "GetTranslation\(`"(?<TranslationKey>.+?)`"\)"
$getTranslationWithIconRegex = "GetTranslationWithIcon\(`".+?`", ?`"(?<TranslationKey>.+?)`"\)"

$existingTranslationKeys = New-Object 'System.Collections.Generic.HashSet[string]'
$usedTranslationKeys = @{}

function addTranslationUsage($translationKey, $filename) {
    if (-Not $usedTranslationKeys.ContainsKey($translationKey)) {
        $usedTranslationKeys[$translationKey] = New-Object 'System.Collections.Generic.HashSet[string]'
    }
    $usedTranslationKeys[$translationKey].Add($filename)
}

# Search for occurences of the specified regular expression in the specified file.
function findMatchesInFile($regex, $filePath) {
    Get-Content $filePath | Select-String -Pattern $regex -AllMatches | Select-Object -Expand Matches | ForEach-Object {
        $translationKey = $_.Groups["TranslationKey"].Value
        addTranslationUsage $translationKey $filePath | Out-Null
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
    loadExistingTranslationKeys $filePath
}

# Recursively search the current directory searching for files that make use of translations.
Get-ChildItem -Recurse -Include "*.aspx", "*.ascx" | ForEach-Object {
    $filePath = $_.FullName
    findMatchesInFile $getTranslationRegex $filePath
    findMatchesInFile $getTranslationWithIconRegex $filePath
}

# Check whether the keys we've found exist in the resource files.
$usedTranslationKeys.Keys | Sort-Object | ForEach-Object {
    if (!$existingTranslationKeys.Contains($_)) {
        Write-Host -BackgroundColor White -ForegroundColor Black $_
        $usedTranslationKeys[$_] | ForEach-Object {
            Write-Host $_
        }
    }
}
