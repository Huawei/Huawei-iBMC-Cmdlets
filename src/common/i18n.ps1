$bundle = Data {
  #culture="en-US"
  ConvertFrom-StringData @'
  MSG_WAIT_PROGRESS_TITLE = Waiting multiple thread results
  MSG_PROGRESS_PERCENT = Percent Complete
  MSG_PROGRESS_COMPLETE = Task Complete
  MSG_PROGRESS_FAILED = Task Failed

  FAIL_NO_USER_WITH_NAME_EXISTS = Failure: No user with name "{0}" exists
  FAIL_NO_UPDATE_PARAMETER = Failure: at least one update parameter must be set
  FAIL_NO_PRIVILEGE = Failure: you do not have the required permissions to perform this operation
  FAIL_INTERNAL_SERVICE = Failure: the request failed due to an internal service error
  FAIL_NOT_SUPPORT = Failure: the server did not support the functionality required
  FAIL_TO_MODIFY_ALL = Failure: Fail to apply all submit settings, got failures:
  FAIL_NO_LINKUP_INTERFACE = Failure: No LinkUp state Ethernet Interfaces found.
  FAIL_SP_NOT_SUPPORT = Failure: SP Service is not supported on this server.
  FAIL_SP_FILE_TRANSFER = Failure: Transfer update firmware file to SP timeout.
  FAIL_SP_RESET_SYSTEM = Failure: Failed to restart computer system.
  FAIL_SIGNAL_URI_REQUIRED = Failure: Signal Uri is required when upgrade firmware.

  ERROR_ILLEGAL_THREAD_RETURN_COUNT = Error: Thread script should only return one element, check your code.
  ERROR_INVALID_CREDENTIALS = Error: Invalid credentials
  ERROR_PARAMETER_EMPTY = Error: parameter "{0}" should not be null or empty
  ERROR_PARAMETER_ILLEGAL = Error: parameter "{0}" is illegal, please check it
  ERROR_PARAMETER_COUNT_DIFFERERNT = Error: The array size of parameter "{1}" should be one or the same as parameter "{0}"
  ERROR_PARAMETER_ARRAY_EMPTY = Error: Array parameter "{0}" should not be null or empty or contains null element.
  ERROR_ILLEGAL_BOOT_SEQ = Error: BootSequence parameter {0} is illegal, it should exactly contains four Boot devices (HDD, Cd, Pxe, Others)
  ERROR_NO_UPDATE_PAYLOAD = Error: nothing to update, at least one update property must be specified
  ERROR_MUST_BE_MATRIX = Error: Parameter "{0}" must be a matrix-array
  ERROR_ELEMENT_NOT_ARRAY = Error: All element of Parameter "{0}" must be an array
  ERROR_ELEMENT_ILLEGAL = Error: Cannot validate argument on parameter '{0}'. The argument "{1}" is duplicate or not belong to the set "{2}".
  ERROR_NTP_MIN_GT_MAX = Error: Parameter "MaxPollingInterval" must be greater than or equal to "MinPollingInterval"
  ERROR_FILE_URI_NOT_SUPPORT = Error: File Uri "{0}" is not supported, file transfer protocols should be one of "{1}".
  ERROR_FILE_URI_ILLEGAL = Error: File Uri is illegal or not exists, please check it.
  ERROR_FILE_NOT_LOCAL = Error: File Uri "{0}" is not a local file, please check it.
  ERROR_SIGNAL_FILE_EMPTY = Error: parameter "SignalFileUri" should not be null or empty.
  ERROR_ILLEGAL_ADDR = Error: Address "{0}" is illegal.
  ERROR_ILLEGAL_BMC_FILE_URI = Error: BMC File Uri "{0}" is illegal, it should starts with "/tmp/".
  ERROR_COPYBACK_SHOULD_BE_ENABLED = Error: To enabled SmarterCopyBack, CopyBack should be enabled first.
  ERROR_VOLUMEID_MANDATORY = Error: When HotSpareType is Dedicated, VolumeId is mandatory.
  ERROR_VOLUMEID_NOT_EXISTS = Error: Could not find volume with Id "{0}".
  ERROR_STORAGE_ID_NOT_EXISTS = Error: Could not find storage with Id "{0}".
  ERROR_EXPORT_TO_SAME_NFS = Error: Should not export to a same file for multiple server.
  ERROR_INVAIL_SENSITIVE_STRING = Error: Parameter "{0}" should be a String or SecureString.
'@
}

# Not necessary for now
# Import-LocalizedData -BindingVariable bundles

function Get-i18n($key) {
  return $bundle[$Key]
}