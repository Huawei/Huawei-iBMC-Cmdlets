<# NOTE: Common Utilities #>

# . $PSScriptRoot/I18n.ps1
# . $PSScriptRoot/Logger.ps1
# . $PSScriptRoot/Threads.ps1

function Write-Input {
  param($input)
  return $input
}

function Convert-IPV4Segment($IPSegment) {
<#
.DESCRIPTION
Convert a specified ip segment expression to all possible int ip segment array

.EXAMPLE
PS C:\>  Convert-IPV4Segment 3-4,5,10
PS C:\> 3 4 5 10

#>
  $result = @()
  $IPSegment.Split(',') | ForEach-Object {
    $split = $_.Split('-')
    $result += $($([int]$split[0])..$([int]$split[-1]))
  }
  return $result
}

function ConvertFrom-IPRangeString {
  param (
    [String][parameter(Mandatory = $true)] $IPRangeString
  )

  $port_regex = ':([1-9]|[1-9]\d|[1-9]\d{2}|[1-9]\d{3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5])'

  $hostnameSection = "([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])"
  [regex] $hostnameRegex = "^$hostnameSection(\.$hostnameSection)+($port_regex)?`$"

  # $ipv4Section = '(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])'
  # $ipv4RangedSection = "$ipv4Section(-$ipv4Section)?"
  # $ipv4RangeSectionWithComma = "$ipv4RangedSection(,$ipv4RangedSection)*"
  # [regex] $ipv4_regex = "^($ipv4RangeSectionWithComma(\.$ipv4RangeSectionWithComma){3})($port_regex)?`$"

  # TODO add ipv6 range support
  # $ipv6Section='[0-9A-Fa-f]{1,4}'
  # $ipv6RangedSection="$ipv6Section(-$ipv6Section)?"
  # $ipv6RangedSectionWithComma="$ipv6RangedSection(,$ipv6RangedSection)*"

  # try to treat it as ipv4
  $IPV4 = ConvertFrom-IPV4RangeString $IPRangeString
  if ($IPV4 -ne $false) {
    return ,$IPV4
  }

  # try to treat it as hostname
  if ($IPRangeString -match $hostnameRegex) {
    return ,@($IPRangeString)
  }

  # try to treat it as ipv6
  $IPV6 = ConvertFrom-IPV6RangeString $IPRangeString
  if ($IPV6 -ne $false) {
    return ,$IPV6
  }

  throw $([string]::Format($(Get-i18n ERROR_ILLEGAL_ADDR), $IPRangeString))
}


function ConvertFrom-IPV4RangeString {
  param(
    [String][parameter(Mandatory = $false)] $IPRangeString
  )
  $port_regex = ':([1-9]|[1-9]\d|[1-9]\d{2}|[1-9]\d{3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5])'
  $ipv4Section = '(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])'
  $ipv4RangedSection = "$ipv4Section(-$ipv4Section)?"
  $ipv4RangeSectionWithComma = "$ipv4RangedSection(,$ipv4RangedSection)*"
  [regex] $ipv4_regex = "^($ipv4RangeSectionWithComma(\.$ipv4RangeSectionWithComma){3})($port_regex)?`$"

  $matches = $ipv4_regex.Matches($IPRangeString)
  if ($matches.Count -eq 1) {
    $singleIpRange = $matches[0].Groups[1].Value
    $port = $IPRangeString -replace $singleIpRange, ''

    $segments = $singleIpRange.Split('.')
    $segment1 =  Convert-IPV4Segment $segments[0]
    $segment2 =  Convert-IPV4Segment $segments[1]
    $segment3 =  Convert-IPV4Segment $segments[2]
    $segment4 =  Convert-IPV4Segment $segments[3]

    $IPArray = New-Object System.Collections.ArrayList
    foreach ($s1 in $segment1) {
      foreach ($s2 in $segment2) {
        foreach ($s3 in $segment3) {
          foreach ($s4 in $segment4) {
            [Void] $IPArray.Add("$(@($s1, $s2, $s3, $s4) -join '.')$port")
          }
        }
      }
    }
    return ,$IPArray.ToArray()
  }

  return $false
}

function ConvertFrom-IPV6RangeString {
  param(
    [String][parameter(Mandatory = $false)] $IPRangeString
  )
  try {

    $Zone = ''
    $Suffix = ''
    $Prefix = ''

    # handle []
    if ($IPRangeString.StartsWith('[')) {
      $Prefix = '['
      $Suffix = $IPRangeString.Substring($IPRangeString.IndexOf(']'))
      $IPRangeString = $IPRangeString.Substring(1, $IPRangeString.IndexOf(']') - 1)
    }

    # handle %eth0
    if ($IPRangeString.IndexOf('%') -gt 0) {
      $Zone = $IPRangeString.Substring($IPRangeString.IndexOf('%'))
      $IPRangeString = $IPRangeString.Substring(0, $IPRangeString.IndexOf('%'))
    }

    # if ($IPRangeString.StartsWith("::")) {
    #   $IPRangeString = "0$IPRangeString"
    # }

    $segments = New-Object System.Collections.ArrayList
    $split = $IPRangeString -split ':'
    $split | ForEach-Object {
      [void] $segments.Add($(Convert-IPV6Segment $_))
    }

    $IPV6Array = $(Merge-IPSegments $segments.ToArray() ':')
    $Results = New-Object System.Collections.ArrayList
    for ($idx = 0; $idx -lt $IPV6Array.Count; $idx++) {
      $IsIPV6 = $false
      [IPAddress]$ipv6 = $null
      if ([IPAddress]::TryParse($IPV6Array[$idx], [ref]$ipv6)) {
        if ($ipv6.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
          $IsIPV6 = $true
        }
      }

      if (-not $IsIPV6) {
        throw $([string]::Format($(Get-i18n ERROR_ILLEGAL_ADDR), $IPRangeString))
      }

      [void] $Results.add("$Prefix$($IPV6Array[$idx])$Zone$Suffix")
    }
    return ,$Results.ToArray()
  } catch {
    throw $([string]::Format($(Get-i18n ERROR_ILLEGAL_ADDR), $IPRangeString))
  }
}

function Merge-IPSegments {
  [CmdletBinding()]
  param(
    [String[][]]$segments,
    [String]$join
  )

  if ($segments.Length -gt 2) {
    $results = New-Object System.Collections.ArrayList
    $First, $Rest = $segments
    $merged = $(Merge-IPSegments $Rest ':')
    foreach ($s1 in $First) {
      foreach ($s2 in $merged) {
        [Void] $results.Add("$s1$join$s2")
      }
    }
    return ,$results.ToArray()
  }

  if ($segments.Length -eq 2) {
    $results = New-Object System.Collections.ArrayList
    foreach ($s1 in $segments[0]) {
      foreach ($s2 in $segments[1]) {
        [Void] $results.Add("$s1$join$s2")
      }
    }
    return ,$results.ToArray()
  }
}

function Convert-IPV6Segment {
<#
.DESCRIPTION
Convert a specified ip segment expression to all possible int ip segment array

.EXAMPLE
PS C:\> $result = Convert-IPV6Segment "20F1-20F2,20F4,20F6-20F8"
PS C:\> $result | Should -be @('20F1', '20F2', '20F4', '20F6', '20F7', '20F8')

#>
  param([string]$IPSegment)

  $IntResults = @()
  if ($null -ne $IPSegment -and $IPSegment -ne '') {
    if ($IPSegment.indexOf('.') -ge 0) {
      return ConvertFrom-IPV4RangeString $IPSegment
    }

    $IPSegment.Split(',') | ForEach-Object {
      # if segment contains '.', treat it as ipv4
      $split = $_.Split('-')
      if ($split.count -gt 2) {
        throw $(Get-i18n ERROR_ILLEGAL_ADDR)
      }
      $from = Invoke-Expression "0x$($split[0])"
      $to = Invoke-Expression "0x$($split[-1])"
      $IntResults += $($from..$to)
    }
  } else {
    return @('')
  }

  $result = New-Object System.Collections.ArrayList
  for ($idx = 0; $idx -lt $IntResults.Count; $idx++) {
    [void] $result.add($IntResults[$idx].ToString('x'))
  }
  return ,$result.ToArray()
}


function Get-MatchedSizeArray {
  [CmdletBinding()]
  param($Source, $Target, $SourceName, $TargetName)

  if ($Target.Count -eq 1 -and $Source.Count -ne 1) {
    $Target = $Target * $Source.Count
  }
  if ($Source.Count -ne $Target.Count) {
    throw $([string]::Format($(Get-i18n ERROR_PARAMETER_COUNT_DIFFERERNT), $SourceName, $TargetName))
  }

  return , $Target
}

function Get-OptionalMatchedSizeArray {
  [CmdletBinding()]
  param($Source, $Target)

  if ($null -eq $Target -or $Target.Count -eq 0) {
    $empty = @($null) * $Source.Count
    return , $empty
  }
  else {
    $matched = Get-MatchedSizeArray $Source $Target 'source' 'target'
    return , $matched
  }
}


function Get-OptionalMatchedSizeMatrix {
  [CmdletBinding()]
  param($Source, $Target, $ValidSet, $SourceName, $TargetName)

  if ($null -eq $Target -or $Target.Count -eq 0) {
    $empty = @($null) * $Source.Count
    return , $empty
  }
  else {
    # every element in the matrix should be an array
    if ($Target -isnot [array]) {
      throw [String]::Format($(Get-i18n ERROR_MUST_BE_MATRIX), $TargetName)
    }

    for ($idx = 0; $idx -lt $Target.Count; $idx++) {
      $element = $Target[$idx]
      if ($element -isnot [array]) {
        throw [String]::Format($(Get-i18n ERROR_ELEMENT_NOT_ARRAY), $TargetName)
      }

      if ($null -ne $ValidSet) {
        $diff = Compare-Object $ValidSet $element | ? {$_.sideindicator -eq "=>"} | % {$_.inputobject}
        if ($null -ne $diff -and $diff.Count -gt 0) {
          $ValidSetString = $ValidSet -join ", "
          $DiffString = $diff -join ", "
          throw [String]::Format($(Get-i18n ERROR_ELEMENT_ILLEGAL), $TargetName, $DiffString, $ValidSetString)
        }
      }
    }

    $matched = Get-MatchedSizeArray $Source $Target $SourceName $TargetName
    return , $matched
  }
}

function Assert-NotNull($Parameter, $ParameterName) {
  if ($null -eq $Parameter) {
    throw $([string]::Format($(Get-i18n ERROR_PARAMETER_EMPTY), $ParameterName))
  }
}

function Assert-ArrayNotNull($Parameter, $ParameterName) {
  if ($null -eq $Parameter -or $Parameter.Count -eq 0 -or $Parameter -contains $null) {
    throw $([string]::Format($(Get-i18n ERROR_PARAMETER_ARRAY_EMPTY), $ParameterName))
  }
}

function Remove-EmptyValues {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Target
  )

  $hash = @{}
  if ($null -ne $Target) {
    # foreach ($pair in $Target.GetEnumerator()) {
    #   $key = $pair.Name
    #   $value = $pair.Value
    #   if ($null -ne $value) {
    #     if ($value -is [array] -and $value.count -eq 0) {
    #       continue
    #     }
    #     if ($value -is [string] -and $value -ne '') {
    #       continue
    #     }
    #     [Void]$hash.Add($key, $value)
    #   }
    # }

    foreach ($key in $Target.Keys) {
      $value = $Target.Item($key)
      if ($null -ne $value) {
        if ($value -is [array] -and $value.count -eq 0) {
          continue
        }
        if ($value -is [string] -and $value -eq '') {
          continue
        }
        [Void]$hash.Add($key, $value)
      }
    }

    # for ($idx=0; $idx -lt $Target.Keys.Count; $idx++) {
    #   $key = $Target.keys[$idx]
    #   $value = $Target.Item($key)
    #   if ($null -ne $value) {
    #     if ($value -is [array] -and $value.count -eq 0) {
    #       continue
    #     }
    #     if ($value -is [string] -and $value -eq '') {
    #       continue
    #     }
    #     [Void]$hash.Add($key, $value)
    #   }
    # }
    # $Target.Keys | ForEach-Object {
    #   $value = $Target.Item($_)
    #   if ($null -ne $value) {
    #     if ($value -is [array] -and $value.count -eq 0) {
    #       continue
    #     }
    #     if ($value -is [string] -and $value -eq '') {
    #       continue
    #     }
    #     [Void]$hash.Add($_, $value)
    #   }
    # }
  }
  return $hash
}

function Remove-NoneValues {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Source
  )

  $hash = @{}
  if ($null -ne $Source) {
    foreach ($key in $Source.Keys) {
      $value = $Source.Item($key)
      if ($null -ne $value) {
        [Void]$hash.Add($key, $value)
      }
    }
  }
  return $hash
}

function Get-PlainPassword {
  [CmdletBinding()]
  param ($SecurePassword)

  if ($null -ne $SecurePassword -and $SecurePassword -is [SecureString]) {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }
  return $SecurePassword
}

function Get-RandomIntGuid {
  return $(Get-Random -Maximum 1000000)
}

function Trace-Session ($Session, $message) {
  return "[$($Session.Address)] $message"
}

function Copy-ObjectProperties ($Source, $Properties) {
  $Clone = New-Object PSObject
  $Properties | ForEach-Object {
    $Clone | Add-Member -MemberType NoteProperty "$_" $Source."$_"
  }
  return $Clone
}

function Copy-ObjectExcludes ($Source, $excludes) {
  $Clone = New-Object PSObject
  $Properties = $Source | Get-Member -MemberType NoteProperty | Select-Object -Expand Name
  $Properties | ForEach-Object {
    if ($_ -notin $excludes) {
      $Clone | Add-Member -MemberType NoteProperty "$_" $Source."$_"
    }
  }
  return $Clone
}


function Resolve-EnumValues {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Source
  )
  $hash = @{}
  if ($null -ne $Source) {
    foreach ($key in $Source.Keys) {
      $value = $Source.Item($key)
      if ($value -is [Enum]) {
        [Void] $hash.Add($key, $value.toString())
      }
      elseif ($value -is [Array]) {
        $Converted = New-Object System.Collections.ArrayList
        $value | ForEach-Object {
          [Void] $Converted.Add($_.toString())
        }
        [Void] $hash.Add($key, $Converted)
      }
      else {
        [Void]$hash.Add($key, $value)
      }
    }
  }
  return $hash
}


function Get-EnumNames {
  param(
    [string]$enum
  )

  $Names = New-Object System.Collections.ArrayList
  [enum]::getvalues([type]$enum) | ForEach-Object {
    [Void] $Names.add($_.toString())
  }
  return $Names.ToArray()
}

function Protect-NetworkUriUserInfo {
  [CmdletBinding()]
  param (
    [string] $NetworkPath
  )
  try {
    $NetworkUri = New-Object System.Uri($NetworkPath)
    if($NetworkUri.UserInfo.Length -gt 0) {
      return $NetworkUri.AbsoluteUri -replace $NetworkUri.UserInfo, "***:***"
    }
    return $NetworkUri
  } catch {
    return $NetworkPath
  }
}