$global:EDITOR = 'C:\Program Files (x86)\Notepad++\notepad++.exe'
$alias:e = $EDITOR

function s() {cd ..}
function touch ($path) 
{
  if (-not $path)
  {
    "Der skal angives en sti inkl. filnavn og extension"
  }
  $dir = [System.IO.Path]::GetDirectoryName($path)
  if (-not [string]::IsNullOrWhiteSpace($dir)) {[System.IO.Directory]::CreateDirectory($dir) | out-null}
  [System.IO.File]::Create($path) | out-null
}

# Locate files or directories
function locate($filter)
{
  if ($filter)
  {
    dir -r -filter $filter | Where Fullname -notmatch ".*\\.hg\\.*|.*\\generated\\.*" | Select FullName | Format-Table -wrap
  }
  else
  {
    echo "syntax: locate <file>"
    echo "Finder filer eller directories. Brug wildcards hvis fulde filnavn ikke er kendt."
    echo "Soeger ikke i 'hg' og 'generated' foldere."
    echo "eks. locate *dims.*"
  }
}


function loginsToday([switch]$useLogins, [int]$daysago=0)
{
  if ($useLogins)
  {
    $events = Get-Eventlog -LogName Security -after (get-date).AddDays(-$daysago).Date.AddHours(4) | 
      Where-Object {$_.EventID -eq 4624 -and $_.ReplacementStrings[5] -eq $env:UserName}
  }
  else
  {
    $events = Get-Eventlog -LogName System -after (get-date).AddDays(-$daysago).Date.AddHours(4)
  }
  
  return $events | Sort-Object TimeGenerated 
}

function tid([switch]$l, [int]$logindex, [switch]$help, [switch]$useLogins)
{
  if ($help)
  {
    write-host ""
    write-host "usage: tid [-help | -l | -useLogins | <logindex>]"
    write-host "Viser tid siden første logon idag"
    write-host ""
    write-host "options: "
    write-host "-help      = Denne hjælp"
    write-host "-l         = vis alle evententries idag og igår og deres index"
    write-host "-useLogins = Kig kun på Logons i Secyrity loggen istedet for alle typer af events i System eventloggen."
    write-host "<logindex> = Vis tidsinfo for bestemt loginindex."
    write-host "             Kan bruges hvis man har arbejdet efter midnat dagen før eller lige har tjekket post hjemme inden arbejde."
    return
  }
  
  function trunc([Object]$tid, [int] $noChars)
  {
    return $tid.ToString().substring(0,$noChars)
  }

  if ($l)
  {
    return loginsToday -useLogins:$useLogins 1 | select-object -property index, timegenerated, entrytype
  }
    
  if ($logindex -gt 0)
  {
    $i=(loginstoday -useLogins:$useLogins 1 | Where-Object {$_.index -eq $logindex})[0]
  }
  else{
    $i = (loginsToday -useLogins:$useLogins)[0]
  }
  
  $start =$i.TimeGenerated.TimeOfDay
  $slut = (get-date).TimeOfDay
  $deltaTid = New-TimeSpan -Start $i.TimeGenerated -End (get-date)
  $30min = New-TimeSpan -Minutes 30
  write-host "Person:" $i.ReplacementStrings[5]
  write-host "Dato:" (trunc $i.TimeGenerated.Date 10)
  write-host "Fra:"(trunc $start 5)
  write-host "Til:"(trunc $slut 5)"(nu)"
  write-host "Diff:"(trunc $deltaTid 5)
  if ($deltaTid -gt $30min)
  {
      write-host "Diff minus frokost:"(trunc ($deltaTid - $30min) 5) -ForegroundColor Green
  }
}

function findAll($data, [string[]]$filetypes)
{
  if ($filetypes) 
  {
    dir -rec -include $filetypes | ?{ $_.fullname -notmatch "\\obj\\?" -and $_.fullname -notmatch "\\.hg\\?" }| select-string $data
  }
  else
  {
    dir -rec -exclude *.dll, *.pdb | ?{ $_.fullname -notmatch "\\obj\\?" -and $_.fullname -notmatch "\\.hg\\?" }| select-string $data
  }
}

function ex($path=".")
{
  explorer $path
}
