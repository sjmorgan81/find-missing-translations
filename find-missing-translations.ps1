$getTranslationRegex = "GetTranslation\(`"(?<TranslationKey>.+?)`"\)"
$getTranslationWithIconRegex = "GetTranslationWithIcon\(`".+?`", ?`"(?<TranslationKey>.+?)`"\)"

$existingTranslationKeys = New-Object 'System.Collections.Generic.HashSet[string]'
$translationKeys = New-Object 'System.Collections.Generic.HashSet[string]'

function findRegexInPath($regex, $filePath) {
    Get-Content $filePath | Select-String -Pattern $regex -AllMatches | Select-Object -Expand Matches | ForEach-Object {
        $match = $_.Groups["TranslationKey"].Value
        #Write-Output "$($filePath): $($match)"
        $translationKeys.Add($match) | Out-Null
    }
}

function loadExistingTranslationKeys($filePath) {
    [xml]$XmlDocument = Get-Content $filePath
    $XmlDocument.root.data | ForEach-Object {
        $existingTranslationKeys.Add($_.name) | Out-Null
    }
}

Get-ChildItem -Recurse -Filter "*.aspx" | ForEach-Object {
    $filePath = $_.FullName
    findRegexInPath $getTranslationRegex $filePath
    findRegexInPath $getTranslationWithIconRegex $filePath
}

foreach ($filePath in $args) {
    Write-Output "Loading translation keys from $($filePath)..."
    loadExistingTranslationKeys $filePath
}

$translationKeys | ForEach-Object {
    if (!$existingTranslationKeys.Contains($_)) {
        Write-Output $_
    }
}
