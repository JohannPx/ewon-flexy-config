# Validation.ps1 - Input validation functions

function Test-IPv4 {
    param([string]$Value)
    return $Value -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
}

function Test-PIN {
    param([string]$Value)
    return $Value -match '^\d{4}$'
}

function Test-Integer {
    param([string]$Value)
    return ($Value -as [int]) -ne $null
}

function Test-NotEmpty {
    param([string]$Value)
    return -not [string]::IsNullOrWhiteSpace($Value)
}

function Test-ParameterValue {
    param(
        [string]$Type,
        [string]$Value,
        [string]$ParamName,
        [bool]$IsRequired = $false
    )

    # Empty value with no requirement = valid
    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($IsRequired) {
            return @{ IsValid = $false; Message = (T "ValRequired") }
        }
        return @{ IsValid = $true; Message = "" }
    }

    switch ($Type) {
        "IPv4" {
            if (-not (Test-IPv4 $Value)) {
                return @{ IsValid = $false; Message = (T "ValInvalidIP") }
            }
        }
        "PIN" {
            if (-not (Test-PIN $Value)) {
                return @{ IsValid = $false; Message = (T "ValInvalidPIN") }
            }
        }
        "Integer" {
            if (-not (Test-Integer $Value)) {
                return @{ IsValid = $false; Message = (T "ValInteger") }
            }
        }
        "Password" {
            if ($Value.Length -gt 24) {
                return @{ IsValid = $false; Message = (T "ValMaxLength") }
            }
        }
    }

    return @{ IsValid = $true; Message = "" }
}
