<# NOTE: A PowerShell Logger implementation. #>

function Enable-Log4Net() {
  $env:LogFileRoot = "$PSScriptRoot\..\logs"
  $Log4NetDllPath = "$PSScriptRoot\log4net.dll"
  $Log4NetConfigFilePath = "$PSScriptRoot\Log4Net.xml"

  # load the log4net library
  [void][Reflection.Assembly]::LoadFile($Log4NetDllPath)
  # configure logging
  [log4net.LogManager]::ResetConfiguration()

  $LogConfigFileInfo = New-Object System.IO.FileInfo($Log4NetConfigFilePath)
  [log4net.Config.XmlConfigurator]::Configure($LogConfigFileInfo)

  $Global:Logger = [log4net.LogManager]::GetLogger("root")
  # $Global:Logger.info("Log4Net initialized.")
  return $Global:Logger
}

function Get-Logger ($name) {
  if ($null -eq $name) {
    return $Global:Logger
  }
  return [log4net.LogManager]::GetLogger($name)
}

# function Set-LoggerNDC ($session) {
#   if ($null -eq $session) {
#     [log4net.ThreadContext]::Stacks["NDC"].Push("[Main]")
#   } else {
#     [log4net.ThreadContext]::Stacks["NDC"].Push("[$($Session.Address)]")
#   }
# }

# to null to avoid output
$Null = @(
  Enable-Log4Net
)