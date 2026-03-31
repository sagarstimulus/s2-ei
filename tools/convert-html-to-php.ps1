param(
  [string]$Root = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'

$rootPath = (Resolve-Path $Root).Path
$htmlFiles = Get-ChildItem -Path $rootPath -Filter *.html | Sort-Object Name
$skipNames = @(
  'index.html',
  'about.html',
  'services.html',
  'projects.html',
  'category-source-inspection.html'
)

$linkMap = @{}
foreach ($file in $htmlFiles) {
  $linkMap[$file.Name] = ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + '.php')
}

function Convert-InternalLinks {
  param(
    [string]$Content,
    [hashtable]$Map
  )

  $updated = $Content
  foreach ($entry in $Map.GetEnumerator()) {
    $updated = $updated.Replace($entry.Key, $entry.Value)
  }

  return $updated
}

foreach ($file in $htmlFiles) {
  if ($skipNames -contains $file.Name) {
    continue
  }

  $raw = Get-Content -LiteralPath $file.FullName -Raw

  $titleMatch = [regex]::Match($raw, '<title>(.*?)</title>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  $mainMatch = [regex]::Match($raw, '<main\b[^>]*>.*?</main>', [System.Text.RegularExpressions.RegexOptions]::Singleline)

  if (-not $titleMatch.Success -or -not $mainMatch.Success) {
    Write-Warning "Skipping $($file.Name): unable to extract title or main block."
    continue
  }

  $pageTitle = $titleMatch.Groups[1].Value.Trim()
  $mainContent = Convert-InternalLinks -Content $mainMatch.Value -Map $linkMap

  $pageScripts = @()
  $scriptMatches = [regex]::Matches($raw, '<script\s+src="([^"]+)"></script>')
  foreach ($match in $scriptMatches) {
    $scriptPath = $match.Groups[1].Value
    if ($scriptPath -ne 'assets/js/site.js') {
      $pageScripts += $scriptPath
    }
  }

  $builder = New-Object System.Text.StringBuilder
  [void]$builder.AppendLine('<?php')
  [void]$builder.AppendLine('declare(strict_types=1);')
  [void]$builder.AppendLine()
  [void]$builder.AppendLine('$pageTitle = ' + "'" + ($pageTitle.Replace("'", "\'")) + "';")

  if ($pageScripts.Count -gt 0) {
    $quotedScripts = $pageScripts | ForEach-Object { "'" + ($_.Replace("'", "\'")) + "'" }
    [void]$builder.AppendLine('$pageScripts = [' + ($quotedScripts -join ', ') + '];')
  }

  [void]$builder.AppendLine("require __DIR__ . '/includes/header.php';")
  [void]$builder.AppendLine('?>')
  [void]$builder.AppendLine($mainContent.TrimEnd())
  [void]$builder.AppendLine("<?php require __DIR__ . '/includes/footer.php'; ?>")

  $phpPath = Join-Path $rootPath (([System.IO.Path]::GetFileNameWithoutExtension($file.Name)) + '.php')
  [System.IO.File]::WriteAllText($phpPath, $builder.ToString(), [System.Text.Encoding]::UTF8)
}
