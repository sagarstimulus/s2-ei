Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$siteRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$repoRoot = Resolve-Path (Join-Path $siteRoot "..")
$photoRoot = Resolve-Path (Join-Path $repoRoot "OneDrive_1_2-26-2026\JOB PHOTOS\Main Folder(Prejectwise Pictures)")
$descRoot = Resolve-Path (Join-Path $repoRoot "OneDrive_1_2-26-2026\Project & Descriptions")
$mapPath = Join-Path $siteRoot "files\project-map.psv"
$projectImageRoot = Join-Path $siteRoot "assets\img\projects"

if (!(Test-Path $projectImageRoot)) {
  New-Item -ItemType Directory -Path $projectImageRoot | Out-Null
}

$docByCategory = @{
  "source-inspection" = "S2 Website Project Category 1 - Soruce Inspection Projects.docx"
  "quality-testing" = "S2 Website Project Category 2 - QM&MT.docx"
  "consultant-cm" = "S2 Website Project Category 3 - Consultant CM.docx"
  "port-rail-transit" = "S2 Website Project Category 4 - Port-Rail-Transit.docx"
}

$categories = @(
  [ordered]@{
    Key = "consultant-cm"
    Title = "Consultant Construction Management & Inspection Projects"
    File = "category-consultant-cm.html"
    Description = "Bridge and roadway programs with resident engineering, inspection, quality oversight, and stakeholder coordination."
  },
  [ordered]@{
    Key = "quality-testing"
    Title = "Quality Management & Materials Testing Projects"
    File = "category-quality-testing.html"
    Description = "Program-level quality management and materials testing support for concrete, asphalt, aggregates, soils, and plant operations."
  },
  [ordered]@{
    Key = "source-inspection"
    Title = "Source Inspection Projects"
    File = "category-source-inspection.html"
    Description = "Fabrication verification, source inspections, and compliance reporting for structural and transportation projects."
  },
  [ordered]@{
    Key = "port-rail-transit"
    Title = "Port / Rail / Transit Projects"
    File = "category-port-rail-transit.html"
    Description = "Port modernization, transit upgrades, and rail-adjacent delivery support with complete project controls and documentation."
  }
)

$sectionHeaders = @(
  "PROJECT BACKGROUND",
  "PROJECT DETAILS",
  "PROJECT SCOPE",
  "OUR ROLE",
  "OUR ADDED VALUE",
  "SERVICES PERFORMED"
)

function Clip([string]$text, [int]$maxLen = 230) {
  if ([string]::IsNullOrWhiteSpace($text)) { return "" }
  $clean = (($text -replace "\s+", " ").Trim())
  if ($clean.Length -le $maxLen) { return $clean }
  return $clean.Substring(0, $maxLen).TrimEnd() + "..."
}

function Get-DocLines([string]$docPath) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $docPath))
  try {
    $entry = $zip.Entries | Where-Object { $_.FullName -eq "word/document.xml" } | Select-Object -First 1
    $reader = New-Object System.IO.StreamReader($entry.Open())
    try {
      [xml]$xml = $reader.ReadToEnd()
    } finally {
      $reader.Close()
    }
  } finally {
    $zip.Dispose()
  }

  $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
  $ns.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
  $paras = $xml.SelectNodes("//w:body/w:p", $ns)
  $lines = @()
  foreach ($p in $paras) {
    $parts = $p.SelectNodes(".//w:t", $ns) | ForEach-Object { $_.InnerText }
    $line = (($parts -join " ") -replace "\s+", " ").Trim()
    if ($line) { $lines += $line }
  }
  return ,$lines
}

function Find-LineIndex([string[]]$lines, [string]$needle) {
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -like "*$needle*") { return $i }
  }
  return -1
}

function Get-SectionText([string[]]$segment, [string]$header) {
  $start = -1
  for ($i = 0; $i -lt $segment.Count; $i++) {
    if ($segment[$i].ToUpperInvariant().StartsWith($header)) {
      $start = $i
      break
    }
  }
  if ($start -lt 0) { return "" }

  $buffer = @()
  $line = $segment[$start]
  if ($line.Length -gt $header.Length) {
    $tail = $line.Substring($header.Length).Trim(" ", "-", ":")
    if ($tail) { $buffer += $tail }
  }

  for ($j = $start + 1; $j -lt $segment.Count; $j++) {
    $candidate = $segment[$j]
    $upper = $candidate.ToUpperInvariant()
    if ($sectionHeaders -contains $upper) { break }
    if ($upper -like "CATEGORY *") { break }
    if ($candidate -like "Website Image Placeholder*") { break }
    $buffer += $candidate
  }
  return (($buffer -join " ") -replace "\s+", " ").Trim()
}

function Extract-Field([string]$details, [string]$label) {
  $pattern = [regex]::Escape($label) + "\s*:\s*(.+?)(?=(Owner|Owners|Point of Contact|Delivery Method|Location|Construction Completion|Completion|Professional Services|Status)\s*:|$)"
  $m = [regex]::Match($details, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return ""
}

function Resolve-Folder([string]$hint) {
  $folder = Get-ChildItem -Path $photoRoot -Recurse -Directory | Where-Object { $_.FullName -like "*$hint*" } | Select-Object -First 1
  if ($null -eq $folder) { throw "Photo folder not found for hint: $hint" }
  return $folder.FullName
}

function Copy-Images([string]$sourceFolder, [string]$slug) {
  $allowed = @(".jpg", ".jpeg", ".png", ".webp", ".avif")
  $images = @(Get-ChildItem -Path $sourceFolder -File | Where-Object { $allowed -contains $_.Extension.ToLowerInvariant() } | Sort-Object Name)
  if ($images.Count -lt 2) { throw "Need at least 2 images for $slug ($sourceFolder)" }
  $take = [Math]::Min(4, [Math]::Max(2, $images.Count))
  $selected = $images | Select-Object -First $take

  $destFolder = Join-Path $projectImageRoot $slug
  if (Test-Path $destFolder) { Remove-Item -Path $destFolder -Recurse -Force }
  New-Item -ItemType Directory -Path $destFolder | Out-Null

  $result = @()
  $i = 1
  foreach ($img in $selected) {
    $name = "img-{0:D2}{1}" -f $i, $img.Extension.ToLowerInvariant()
    Copy-Item -Path $img.FullName -Destination (Join-Path $destFolder $name) -Force
    $result += [ordered]@{
      path = "assets/img/projects/$slug/$name"
      caption = (($img.BaseName -replace "[-_]+", " ") -replace "\s+", " ").Trim()
    }
    $i++
  }
  return ,$result
}

function HeaderHtml([string]$title) {
  return @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href="assets/css/main.css" rel="stylesheet">
</head>
<body>
  <header>
    <div class="container bar">
      <a class="brand brand-link" href="index.html"><img src="assets/img/logo-s2.svg" alt="S2 Engineering logo"><span>S2 Engineering</span></a>
      <nav>
        <a href="index.html">Home</a>
        <a href="about.html">About</a>
        <a href="services.html">Services</a>
        <a href="projects.html">Projects</a>
        <a href="careers.html">Careers</a>
        <a href="index.html#contact">Contact</a>
      </nav>
      <button class="theme-toggle" type="button" data-theme-toggle>Dark</button>
    </div>
  </header>
  <main class="container">
"@
}

$footerHtml = @'
  </main>
  <footer class="site-footer">
    <div class="container footer-grid">
      <section class="footer-col footer-brand-col">
        <a class="brand brand-link footer-brand" href="index.html"><img class="brand-logo footer-brand-logo" src="assets/img/logo-s2.svg" alt="S2 Engineering logo" width="229" height="104"><span>S2 Engineering</span></a>
      </section>
      <section class="footer-col footer-links-col">
        <ul class="footer-links footer-links-inline">
          <li><a href="about.html">About Us</a></li>
          <li><a href="services.html">Services</a></li>
          <li><a href="projects.html">Projects</a></li>
          <li><a href="careers.html">Careers</a></li>
          <li><a href="index.html#contact">Contact</a></li>
        </ul>
      </section>
    </div>
    <div class="container footer-bottom">
      <p>&copy; 2026 S2 Engineering. All rights reserved.</p>
    </div>
  </footer>
  <script src="assets/js/site.js"></script>
</body>
</html>
'@

$map = Import-Csv -Path $mapPath -Delimiter "|"

$docLines = @{}
foreach ($k in $docByCategory.Keys) {
  $docLines[$k] = Get-DocLines -docPath (Join-Path $descRoot $docByCategory[$k])
}

$records = @()
foreach ($item in $map) {
  $lines = $docLines[$item.category_key]
  $start = Find-LineIndex -lines $lines -needle $item.title_key
  if ($start -lt 0) { throw "Title not found in doc: $($item.title_key)" }

  $starts = @()
  foreach ($x in ($map | Where-Object { $_.category_key -eq $item.category_key })) {
    $idx = Find-LineIndex -lines $lines -needle $x.title_key
    if ($idx -gt $start) { $starts += $idx }
  }
  $end = if ($starts.Count -gt 0) { ($starts | Measure-Object -Minimum).Minimum } else { $lines.Count }
  $segment = $lines[$start..($end - 1)]

  $title = ($segment[0] -replace "^\d+\.\s*", "").Trim()
  $bg = Get-SectionText -segment $segment -header "PROJECT BACKGROUND"
  $details = Get-SectionText -segment $segment -header "PROJECT DETAILS"
  $role = Get-SectionText -segment $segment -header "OUR ROLE"
  $added = Get-SectionText -segment $segment -header "OUR ADDED VALUE"
  $services = Get-SectionText -segment $segment -header "SERVICES PERFORMED"
  $scope = Get-SectionText -segment $segment -header "PROJECT SCOPE"

  $images = Copy-Images -sourceFolder (Resolve-Folder -hint $item.folder_hint) -slug $item.slug

  $owner = Extract-Field -details $details -label "Owner"
  if (!$owner) { $owner = Extract-Field -details $details -label "Owners" }
  $location = Extract-Field -details $details -label "Location"
  $delivery = Extract-Field -details $details -label "Delivery Method"
  $completion = Extract-Field -details $details -label "Construction Completion"
  if (!$completion) { $completion = Extract-Field -details $details -label "Completion" }
  if (!$completion) { $completion = Extract-Field -details $details -label "Status" }

  if (!$location) {
    $normalizedTitle = $title -replace ([char]8211), "-" -replace ([char]8212), "-"
    $locMatch = [regex]::Match($normalizedTitle, "\s-\s*([^,]+,\s*CA(?:\)|)?)$")
    if ($locMatch.Success) { $location = $locMatch.Groups[1].Value.Trim() }
  }

  $records += [ordered]@{
    slug = $item.slug
    category_key = $item.category_key
    group_name = $item.group_name
    title = $title
    background = if ($bg) { $bg } else { Clip $scope 550 }
    scope = $scope
    role = $role
    added = $added
    services = $services
    owner = if ($owner) { $owner } else { "Public agency program" }
    location = if ($location) { $location } else { "California" }
    delivery = if ($delivery) { $delivery } else { "Project-specific delivery" }
    completion = if ($completion) { $completion } else { "Program support" }
    images = $images
  }
}

$categoryByKey = @{}
foreach ($c in $categories) { $categoryByKey[$c.Key] = $c }

# Build project detail pages
foreach ($r in $records) {
  $cat = $categoryByKey[$r.category_key]
  $compactLayout = @("consultant-cm", "quality-testing", "source-inspection") -contains $r.category_key
  $serviceText = ($r.services -replace "\u2022", "|" -replace "\s{2,}", "|")
  $serviceLines = @($serviceText.Split("|") | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -First 6)
  if ($serviceLines.Count -eq 0) { $serviceLines = @("Project-specific quality management and inspection services.") }
  $serviceHtml = ($serviceLines | ForEach-Object { "<li>$([System.Net.WebUtility]::HtmlEncode($_))</li>" }) -join "`n            "
  if ($compactLayout) {
    $heroImage = if ($r.slug -eq "project-manhattan-beach-sepulveda-bridge-widening") { $r.images[-1] } else { $r.images[0] }
    $galleryImages = if ($r.slug -eq "project-manhattan-beach-sepulveda-bridge-widening") {
      @($r.images | Where-Object { $_.path -ne $heroImage.path } | Select-Object -First 2)
    } else {
      @($r.images | Where-Object { $_.path -ne $heroImage.path } | Select-Object -First 3)
    }
    $serviceSummary = [System.Net.WebUtility]::HtmlEncode(($serviceLines -join "; "))
    $galleryClass = if ($galleryImages.Count -le 2) { "service-media service-media-2" } else { "service-media" }
    $imageHtml = ($galleryImages | ForEach-Object { "<article class=""card""><img src=""$($_.path)"" alt=""$([System.Net.WebUtility]::HtmlEncode($r.title))""></article>" }) -join "`n        "
    $body = @"
    <section class="hero compact">
      <img src="$($heroImage.path)" alt="$([System.Net.WebUtility]::HtmlEncode($r.title))">
    </section>
    <section class="section">
      <div class="section-head">
        <h2>$([System.Net.WebUtility]::HtmlEncode($r.title))</h2>
        <p>$([System.Net.WebUtility]::HtmlEncode($r.background))</p>
      </div>
      <article class="card about-copy about-intro-copy">
        <p><strong>Project Details:</strong> Owner: $([System.Net.WebUtility]::HtmlEncode($r.owner)); Location: $([System.Net.WebUtility]::HtmlEncode($r.location)); Delivery Method: $([System.Net.WebUtility]::HtmlEncode($r.delivery)); Status / Completion: $([System.Net.WebUtility]::HtmlEncode($r.completion)).</p>
        <p><strong>Our Role:</strong> $([System.Net.WebUtility]::HtmlEncode($r.role))</p>
        <p><strong>Services Provided:</strong> $serviceSummary.</p>
        <p><strong>Added Value:</strong> $([System.Net.WebUtility]::HtmlEncode($r.added))</p>
      </article>
      <h3 class="section-title">Project Images</h3>
      <div class="$galleryClass">
        $imageHtml
      </div>
      <p class="service-backlink"><a class="btn" href="$($cat.File)">Back to Category</a></p>
    </section>
"@
  } else {
    $imageHtml = ($r.images | ForEach-Object { "<article class=""card""><img src=""$($_.path)"" alt=""$([System.Net.WebUtility]::HtmlEncode($r.title))""><p>$([System.Net.WebUtility]::HtmlEncode($_.caption))</p></article>" }) -join "`n        "

    $body = @"
    <section class="hero compact">
      <img src="$($r.images[0].path)" alt="$([System.Net.WebUtility]::HtmlEncode($r.title))">
    </section>
    <section class="section">
      <div class="section-head">
        <h2>$([System.Net.WebUtility]::HtmlEncode($r.title))</h2>
        <p>$([System.Net.WebUtility]::HtmlEncode($r.background))</p>
      </div>
      <div class="grid">
        <article class="card">
          <h3>Project Details</h3>
          <ul class="list">
            <li><strong>Category:</strong> $([System.Net.WebUtility]::HtmlEncode($cat.Title))</li>
            <li><strong>Owner:</strong> $([System.Net.WebUtility]::HtmlEncode($r.owner))</li>
            <li><strong>Location:</strong> $([System.Net.WebUtility]::HtmlEncode($r.location))</li>
            <li><strong>Delivery Method:</strong> $([System.Net.WebUtility]::HtmlEncode($r.delivery))</li>
            <li><strong>Status / Completion:</strong> $([System.Net.WebUtility]::HtmlEncode($r.completion))</li>
          </ul>
        </article>
        <article class="card">
          <h3>Our Role</h3>
          <p>$([System.Net.WebUtility]::HtmlEncode($r.role))</p>
          <h3>Services Performed</h3>
          <ul class="list">
            $serviceHtml
          </ul>
        </article>
      </div>
      <h3 class="section-title">Added Value</h3>
      <article class="card"><p>$([System.Net.WebUtility]::HtmlEncode($r.added))</p></article>
      <h3 class="section-title">Project Images</h3>
      <div class="service-media">
        $imageHtml
      </div>
      <p class="service-backlink"><a class="btn" href="$($cat.File)">Back to Category</a></p>
    </section>
"@
  }
  Set-Content -Path (Join-Path $siteRoot ($r.slug + ".html")) -Value ((HeaderHtml ("S2 Engineering | " + $r.title)) + $body + $footerHtml) -NoNewline
}

# Build category pages
foreach ($c in $categories) {
  $catItems = @($records | Where-Object { $_.category_key -eq $c.Key })
  $grouped = $catItems | Group-Object -Property group_name
  $sections = @()
  foreach ($g in $grouped) {
    if ($g.Name) { $sections += "<h3 class=""section-title"">$([System.Net.WebUtility]::HtmlEncode($g.Name))</h3>" }
    $cards = ($g.Group | ForEach-Object {
      "<article class=""card service-card""><a class=""service-card-link"" href=""$($_.slug).html""><img src=""$($_.images[0].path)"" alt=""$([System.Net.WebUtility]::HtmlEncode($_.title))""><div class=""service-card-body""><h3>$([System.Net.WebUtility]::HtmlEncode($_.title))</h3><p class=""meta"">$([System.Net.WebUtility]::HtmlEncode($_.location)) | $([System.Net.WebUtility]::HtmlEncode($_.completion))</p><p>$([System.Net.WebUtility]::HtmlEncode((Clip $_.background 180)))</p><span class=""service-cta"">Open Project</span></div></a></article>"
    }) -join ""
    $sections += "<div class=""services-grid"">$cards</div>"
  }
  $body = @"
    <section class="hero compact">
      <img src="$($catItems[0].images[0].path)" alt="$([System.Net.WebUtility]::HtmlEncode($c.Title))">
    </section>
    <section class="section">
      <div class="section-head">
        <h2>$([System.Net.WebUtility]::HtmlEncode($c.Title))</h2>
        <p>$([System.Net.WebUtility]::HtmlEncode($c.Description))</p>
      </div>
      $($sections -join "`n      ")
    </section>
"@
  Set-Content -Path (Join-Path $siteRoot $c.File) -Value ((HeaderHtml ("S2 Engineering | " + $c.Title)) + $body + $footerHtml) -NoNewline
}

# Build projects landing page
$categoryCards = ($categories | ForEach-Object {
  $cat = $_
  $firstProject = $records | Where-Object { $_.category_key -eq $cat.Key } | Select-Object -First 1
  "<article class=""card service-card""><a class=""service-card-link"" href=""$($cat.File)""><img src=""$($firstProject.images[0].path)"" alt=""$([System.Net.WebUtility]::HtmlEncode($cat.Title))""><div class=""service-card-body""><h3>$([System.Net.WebUtility]::HtmlEncode($cat.Title))</h3><p>$([System.Net.WebUtility]::HtmlEncode($cat.Description))</p><span class=""service-cta"">View Category Projects</span></div></a></article>"
}) -join ""

$projectsBody = @"
    <section class="hero compact">
      <img src="$($records[0].images[0].path)" alt="S2 Engineering projects">
    </section>
    <section class="section">
      <div class="section-head">
        <h2>Projects</h2>
      </div>
      <article class="card about-copy">
        <p>At S2 Engineering, we partner with contractors, design firms, construction managers, and local and state government agencies throughout California. Our team specializes in highways and roadways, airports, railways, ports, and intermodal projects. Our involvement with each project is tailored to the needs of our partners and is an integral part of what makes each one successful.</p>
      </article>
      <h3 class="section-title">Project Categories</h3>
      <div class="services-grid">
        $categoryCards
      </div>
    </section>
"@
Set-Content -Path (Join-Path $siteRoot "projects.html") -Value ((HeaderHtml "S2 Engineering | Projects") + $projectsBody + $footerHtml) -NoNewline

Write-Output "Generated projects.html, 4 category pages, and $($records.Count) project detail pages."
