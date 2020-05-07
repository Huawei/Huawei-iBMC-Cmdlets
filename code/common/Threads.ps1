# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: A PowerShell simple multiple thread support implementation. #>

# PowerShell 3+
# Foreach -parallel ( $srv in gc c:\input.txt )
# {
# Scriptblock..........
# }


try { [AsyncTask] | Out-Null } catch {
  Add-Type @'
  public class AsyncTask
  {
    public System.String ID;
    public System.Management.Automation.PowerShell PowerShell;
    public System.IAsyncResult AsyncResult;
    public System.DateTime StartTime;
    public System.Boolean isRunning;
  }
'@
}


# function New-Task([int]$Index,[scriptblock]$ScriptBlock) {
#   $ps = [Management.Automation.PowerShell]::Create()
#   $res = New-Object PSObject -Property @{
#       Index = $Index
#       Powershell = $ps
#       StartTime = Get-Date
#       Busy = $true
#       Data = $null
#       async = $null
#   }

#   [Void] $ps.AddScript($ScriptBlock)
#   [Void] $ps.AddParameter("TaskInfo",$Res)
#   $res.async = $ps.BeginInvoke()
#   $res
# }

# $ScriptBlock = {
#   param([Object]$TaskInfo)
#   $TaskInfo.Busy = $false
#   Start-Sleep -Seconds 1
#   $TaskInfo.Data = "test $($TaskInfo.Data)"
# }

# $a = New-Task -Index 1 -ScriptBlock $ScriptBlock
# $a.Data = "i was here"
# Start-Sleep -Seconds 5
# $a

function Get-RunspacePoolSize ($expectPoolSize) {
  $maxPoolSize = 16
  $poolSize = (@($expectPoolSize, $maxPoolSize) | Measure-Object -Minimum).Minimum
  return $poolSize
}


function New-RunspacePool {
  [Cmdletbinding()]
  Param
  (
    [Parameter(Position = 0, Mandatory = $true)][int]$ExpectPoolSize,
    [Parameter(Position = 1, Mandatory = $False)][Switch]$MTA
  )

  $PoolSize = Get-RunspacePoolSize $ExpectPoolSize
  $Logger.info("Create thread pool, Expect size: $ExpectPoolSize, Real size: $PoolSize")

  $pool = [RunspaceFactory]::CreateRunspacePool(1, $PoolSize)
  If (!$MTA) {
    # $Logger.info("Thread pool apartment state: STA")
    $pool.ApartmentState = 'STA'
  } else {
    # $Logger.info("Thread pool apartment state: MTA")
    $pool.ApartmentState = 'MTA'
  }
  $pool.Open()
  return $pool
}

function Start-ScriptBlockThread {
  [Cmdletbinding()]
  Param
  (
    [Parameter(Position = 0, Mandatory = $True)]$ThreadPool,
    [Parameter(Position = 1, Mandatory = $True)]$ScriptBlock,
    [Parameter(Position = 2, Mandatory = $False)]$Parameters
  )

  # $InitialSessionState = [InitialSessionState]::CreateDefault()
  # $InitialSessionState.ExecutionPolicy = 'RemoteSigned'
  # $InitialSessionState.ImportPSModule("Huawei-iBMC-Cmdlets")

  # $Logger.info("Invoke Script block in new thread")
  # $PowerShell = [System.Management.Automation.PowerShell]::Create($InitialSessionState)
  $PowerShell = [System.Management.Automation.PowerShell]::Create()
  $PowerShell.RunspacePool = $ThreadPool

  $CommonFiles = @(Get-ChildItem -Path $PSScriptRoot\..\common -Recurse -Filter *.ps1)
  # $ScriptFiles = @(Get-ChildItem -Path $PSScriptRoot\..\scripts -Recurse -Filter *.ps1)
  $CommonFiles | ForEach-Object {
    try {
      $FileFullPath = $_.FullName
      [Void] $PowerShell.AddScript(". `"$FileFullPath`"")
    } catch {
        Write-Error -Message "Failed to import file $FileFullPath"
    }
  }

  [Void] $PowerShell.AddScript($ScriptBlock, $false)
  if ($null -ne $Parameters -and $Parameters.Count -gt 0) {
    [Void] $PowerShell.AddParameters($Parameters)
    # Foreach ($Arg in $Parameters) {
    #   [Void] $PowerShell.AddArgument($Arg)
    # }
  }

  # $Logger.debug("Start script block thread")
  $AsyncResult = $PowerShell.BeginInvoke()

  $Task = New-Object AsyncTask
  $Task.PowerShell = $PowerShell
  $Task.StartTime = Get-Date
  $Task.AsyncResult = $AsyncResult
  $Task.isRunning = $true
  return $Task
}

function Start-CommandThread {
  [Cmdletbinding()]
  Param
  (
    [Parameter(Position = 0, Mandatory = $True)]$ThreadPool,
    [Parameter(Position = 1, Mandatory = $True)]$Command,
    [Parameter(Position = 2, Mandatory = $False)]$Parameters
  )

  # $Logger.info("Invoke Command: $Command , parameters: $Parameters in new thread")
  $PowerShell = [System.Management.Automation.PowerShell]::Create()
  $PowerShell.RunspacePool = $ThreadPool

  $CommonFiles = @(Get-ChildItem -Path $PSScriptRoot\..\common -Recurse -Filter *.ps1)
  # $ScriptFiles = @(Get-ChildItem -Path $PSScriptRoot\..\scripts -Recurse -Filter *.ps1)
  $CommonFiles | ForEach-Object {
    try {
      $FileFullPath = $_.FullName
      [Void] $PowerShell.AddScript(". `"$FileFullPath`"")
    } catch {
        Write-Error -Message "Failed to import file $FileFullPath"
    }
  }

  [Void] $PowerShell.AddCommand($Command)
  if ($null -ne $Parameters -and $Parameters.Count -gt 0) {
    [Void] $PowerShell.AddParameters($Parameters)
  }

  # $Logger.debug("Start script block thread")
  $AsyncResult = $PowerShell.BeginInvoke()

  $Task = New-Object AsyncTask
  $Task.PowerShell = $PowerShell
  $Task.StartTime = Get-Date
  $Task.AsyncResult = $AsyncResult
  $Task.isRunning = $true
  return $Task
}

function Get-AsyncTaskResults {
  [Cmdletbinding()]
  Param
  (
    [Parameter(Position = 0, Mandatory = $True)][AsyncTask[]] $AsyncTasks,
    [Parameter(Position = 1, Mandatory = $false)][Switch] $ShowProgress
  )

  $results = New-Object System.Collections.ArrayList
  # incrementing for Write-Progress
  $i = 0
  foreach ($AsyncTask in $AsyncTasks) {
    if ($ShowProgress) {
      Write-Progress -Activity $(Get-i18n MSG_WAIT_PROGRESS_TITLE) `
        -PercentComplete $(($i++ / $AsyncTasks.Count) * 100) `
        -Status $(Get-i18n MSG_PROGRESS_PERCENT)
    }
    try {
      # waiting for powershell invoke finished and return result
      $Result = $AsyncTask.PowerShell.EndInvoke($AsyncTask.AsyncResult)
      if ($AsyncTask.PowerShell.Streams.Error) {
        $Error = $AsyncTask.PowerShell.Streams.Error[0]
        # $Logger.Warn($AsyncTask.PowerShell.Streams.Error)
        $Logger.Warn("$Error`n$($Error.InvocationInfo.PositionMessage)`n$($Error.ScriptStackTrace)")
        [Void] $results.add($AsyncTask.PowerShell.Streams.Error)
      } else {
        if ($Result.Count -eq 1) {
          [Void] $results.add($Result[0])
        } else {
          # $Logger.Warn("Return value: $Result")
          throw $(GET-i18n "ERROR_ILLEGAL_THREAD_RETURN_COUNT")
        }
      }
    }
    catch {
      $ex = $_.Exception
      $Logger.Warn("$ex`n$($_.InvocationInfo.PositionMessage)`n$($ex.StackTrace)")
      while($null -ne $ex.InnerException) {
        $ex = $ex.InnerException
      }
      [Void] $results.add($ex)
    }
    finally {
      $AsyncTask.isRunning = $false
      $AsyncTask.PowerShell.Dispose()
    }
  }

  return , $results.ToArray()
}
