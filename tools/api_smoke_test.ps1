param(
  [string]$BaseUrl = "http://113.44.50.108:3002/api",
  [string]$Username = $env:EATWHAT_QA_USERNAME,
  [string]$Password = $env:EATWHAT_QA_PASSWORD,
  [string]$PhotoPath = "",
  [string]$OutputPath = "test-results/api-smoke-result.json"
)

$ErrorActionPreference = "Stop"
$checks = New-Object System.Collections.ArrayList

if ([string]::IsNullOrWhiteSpace($Username) -or [string]::IsNullOrWhiteSpace($Password)) {
  throw "Provide QA credentials with -Username/-Password or EATWHAT_QA_USERNAME/EATWHAT_QA_PASSWORD."
}

function Add-Check($name, $status, $detail) {
  [void]$checks.Add([ordered]@{
      name   = $name
      status = $status
      detail = $detail
    })
  Write-Output "[$status] $name - $detail"
}

function Invoke-Api($method, $path, $token, $body) {
  $headers = @{}
  if ($token) {
    $headers["Authorization"] = "Bearer $token"
  }

  $params = @{
    Uri        = "$BaseUrl$path"
    Method     = $method
    Headers    = $headers
    TimeoutSec = 30
  }

  if ($null -ne $body) {
    $params["ContentType"] = "application/json"
    $params["Body"] = ($body | ConvertTo-Json -Compress -Depth 20)
  }

  Invoke-RestMethod @params
}

function Get-Items($value) {
  if ($null -ne $value.items) {
    return @($value.items)
  }
  if ($null -ne $value.data -and $null -ne $value.data.items) {
    return @($value.data.items)
  }
  if ($null -ne $value.data) {
    $items = @()
    foreach ($item in $value.data) {
      $items += $item
    }
    return $items
  }
  if ($value -is [array]) {
    return @($value)
  }
  return @()
}

function Get-Id($value) {
  if ($null -eq $value) {
    return $null
  }
  $mongoId = $value.PSObject.Properties["_id"]
  if ($null -ne $mongoId -and $null -ne $mongoId.Value) {
    return $mongoId.Value
  }
  $id = $value.PSObject.Properties["id"]
  if ($null -ne $id -and $null -ne $id.Value) {
    return $id.Value
  }
  return $null
}

try {
  $login = Invoke-Api POST "/auth/login" $null @{
    username = $Username
    password = $Password
  }
  $token = $login.token
  Add-Check "AUTH_LOGIN" "PASS" "user=$($login.user.username), household=$($login.household.id)"

  $me = Invoke-Api GET "/auth/me" $token $null
  Add-Check "AUTH_ME" "PASS" "user=$($me.user.username), invite=$($me.household.inviteCode)"

  $memberName = "qa_member_$((Get-Date).ToString("yyyyMMddHHmmss"))"
  $member = Invoke-Api POST "/auth/register" $null @{
    username    = $memberName
    password    = $Password
    displayName = "QA Member"
    inviteCode  = $me.household.inviteCode
  }
  Add-Check "AUTH_REGISTER_WITH_INVITE" "PASS" "member=$($member.user.username), household=$($member.household.id)"

  $beforeDefault = Invoke-Api GET "/default-meals/status" $token $null
  Add-Check "DEFAULT_STATUS" "PASS" ($beforeDefault | ConvertTo-Json -Compress -Depth 6)

  $import = Invoke-Api POST "/default-meals/import-missing" $token @{}
  Add-Check "DEFAULT_IMPORT_MISSING" "PASS" ($import | ConvertTo-Json -Compress -Depth 6)

  $meals = Invoke-Api GET "/meals?limit=3" $token $null
  $mealItems = Get-Items $meals
  $mealId = $null
  if ($null -ne $meals.data -and $meals.data.Count -gt 0) {
    $mealId = $meals.data[0].PSObject.Properties["_id"].Value
  }
  if (-not $mealId -and $mealItems.Count -gt 0) {
    $mealId = Get-Id $mealItems[0]
  }
  Add-Check "MEALS_LIST" "PASS" "count=$($mealItems.Count), firstMealId=$mealId"

  $dashboard = Invoke-Api GET "/dashboard/summary" $token $null
  Add-Check "DASHBOARD_SUMMARY" "PASS" ($dashboard | ConvertTo-Json -Compress -Depth 4)

  $today = Get-Date -Format "yyyy-MM-dd"
  $month = Get-Date -Format "yyyy-MM"
  $dow = [int](Get-Date).DayOfWeek
  if ($dow -eq 0) {
    $delta = -6
  }
  else {
    $delta = 1 - $dow
  }
  $week = (Get-Date).AddDays($delta).ToString("yyyy-MM-dd")

  $weekly = Invoke-Api GET "/weekly-plans?weekStart=$week" $token $null
  Add-Check "WEEKLY_QUERY" "PASS" ($weekly | ConvertTo-Json -Compress -Depth 4)

  $draft = Invoke-Api POST "/weekly-plans/generate" $token @{ weekStart = $week }
  Add-Check "WEEKLY_GENERATE" "PASS" ($draft | ConvertTo-Json -Compress -Depth 5)

  $applied = Invoke-Api POST "/weekly-plans/apply" $token @{ days = $draft.days }
  Add-Check "WEEKLY_APPLY" "PASS" ($applied | ConvertTo-Json -Compress -Depth 5)

  $yearNumber = (Get-Date).Year
  $monthNumber = (Get-Date).Month
  $schedule = Invoke-Api GET "/schedules?year=$yearNumber&month=$monthNumber" $token $null
  Add-Check "SCHEDULES_QUERY" "PASS" ($schedule | ConvertTo-Json -Compress -Depth 4)

  $shopping = Invoke-Api POST "/shopping-list/generate" $token @{ weekStart = $week }
  Add-Check "SHOPPING_GENERATE" "PASS" ($shopping | ConvertTo-Json -Compress -Depth 5)

  $manualName = "QA test eggs $((Get-Date).ToString("HHmmss"))"
  $manualItem = Invoke-Api POST "/shopping-list/items" $token @{
    weekStart = $week
    name      = $manualName
    amount    = "2 pcs"
    category  = "other"
  }
  if ($null -ne $manualItem.items) {
    $createdManual = @($manualItem.items | Where-Object { $_.name -eq $manualName } | Select-Object -Last 1)
    $manualId = Get-Id $createdManual[0]
  }
  elseif ($null -ne $manualItem.item) {
    $manualId = Get-Id $manualItem.item
  }
  else {
    $manualId = Get-Id $manualItem
  }
  Add-Check "SHOPPING_ADD_MANUAL" "PASS" "itemId=$manualId"
  if ($manualId) {
    $patched = Invoke-Api PATCH "/shopping-list/items/$manualId" $token @{
      weekStart = $week
      checked   = $true
    }
    Add-Check "SHOPPING_CHECK_ITEM" "PASS" ($patched | ConvertTo-Json -Compress -Depth 4)
  }

  $wish = Invoke-Api POST "/wishlist" $token @{
    title    = "QA tomato beef"
    note     = "api smoke"
    category = "home wish"
    priority = "high"
  }
  if ($null -ne $wish.item) {
    $wishId = Get-Id $wish.item
  }
  else {
    $wishId = Get-Id $wish
  }
  Add-Check "WISHLIST_CREATE" "PASS" "wishId=$wishId"
  if ($wishId) {
    $vote = Invoke-Api POST "/wishlist/$wishId/vote" $token @{}
    Add-Check "WISHLIST_VOTE" "PASS" ($vote | ConvertTo-Json -Compress -Depth 4)
    $status = Invoke-Api PATCH "/wishlist/$wishId/status" $token @{ status = "planned" }
    Add-Check "WISHLIST_STATUS" "PASS" ($status | ConvertTo-Json -Compress -Depth 4)
  }

  $memory = Invoke-Api POST "/memories" $token @{
    date         = $today
    mealType     = "dinner"
    title        = "QA dinner memory"
    mood         = "happy"
    note         = "api smoke"
    rating       = 5
    mealIds      = @($mealId)
    participants = @($login.user.id)
  }
  Add-Check "MEMORY_CREATE_JSON" "PASS" ($memory | ConvertTo-Json -Compress -Depth 5)

  $memories = Invoke-Api GET "/memories?month=$month" $token $null
  Add-Check "MEMORIES_QUERY" "PASS" ($memories | ConvertTo-Json -Compress -Depth 4)

  if (-not [string]::IsNullOrWhiteSpace($PhotoPath)) {
    $resolvedPhotoPath = (Resolve-Path $PhotoPath).Path
    $curlArgs = @(
      "-sS",
      "-X", "POST",
      "$BaseUrl/memories",
      "-H", "Authorization: Bearer $token",
      "-F", "date=$today",
      "-F", "mealType=dinner",
      "-F", "title=QA png upload memory",
      "-F", "mood=happy",
      "-F", "rating=5",
      "-F", "note=png upload smoke",
      "-F", "mealIds=[]",
      "-F", "participants=[]",
      "-F", "photos=@$resolvedPhotoPath;type=image/png"
    )
    $uploadRaw = & curl.exe @curlArgs
    if ($LASTEXITCODE -ne 0) {
      throw "curl upload failed with exit code $LASTEXITCODE"
    }
    $upload = $uploadRaw | ConvertFrom-Json
    $uploadedPhotos = @($upload.photos)
    if ($uploadedPhotos.Count -lt 1) {
      throw "PNG upload did not return photos. Response: $uploadRaw"
    }
    Add-Check "MEMORY_CREATE_PNG" "PASS" "photos=$($uploadedPhotos.Count), first=$($uploadedPhotos[0])"
  }

  $album = Invoke-Api GET "/photo-album?month=$month" $token $null
  Add-Check "PHOTO_ALBUM_QUERY" "PASS" ($album | ConvertTo-Json -Compress -Depth 4)

  $templates = Invoke-Api GET "/anniversary-templates" $token $null
  Add-Check "ANNIVERSARY_TEMPLATES" "PASS" ($templates | ConvertTo-Json -Compress -Depth 4)

  $issueCreated = Invoke-Api POST "/meal-image-issues" $token @{
    mealId    = $mealId
    issueType = "mismatch"
    note      = "api smoke"
  }
  Add-Check "IMAGE_ISSUE_CREATE" "PASS" ($issueCreated | ConvertTo-Json -Compress -Depth 4)

  $issues = Invoke-Api GET "/meal-image-issues?status=open" $token $null
  Add-Check "IMAGE_ISSUES_QUERY" "PASS" ($issues | ConvertTo-Json -Compress -Depth 4)
}
catch {
  Add-Check "API_SMOKE_EXCEPTION" "FAIL" $_.Exception.Message
}

$pass = @($checks | Where-Object { $_.status -eq "PASS" }).Count
$fail = @($checks | Where-Object { $_.status -eq "FAIL" }).Count
$result = [ordered]@{
  runAt   = (Get-Date).ToString("s")
  baseUrl = $BaseUrl
  account = $Username
  summary = [ordered]@{
    total = $checks.Count
    pass  = $pass
    fail  = $fail
  }
  checks  = $checks
}

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path $outputDir)) {
  New-Item -ItemType Directory -Force $outputDir | Out-Null
}
$result | ConvertTo-Json -Depth 30 | Set-Content -Path $OutputPath -Encoding UTF8

if ($fail -gt 0) {
  exit 1
}
