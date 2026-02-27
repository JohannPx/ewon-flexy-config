# Config.ps1 - Parameter definitions, manifest loading, condition evaluation

$Script:ParameterDefinitions = @(
    # Common parameters (always asked)
    @{File="comcfg.txt"; Param="EthIP"; Default="192.168.253.254"; Description="Desc_EthIP"; Type="IPv4"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_LAN"}
    @{File="comcfg.txt"; Param="EthMask"; Default="255.255.255.0"; Description="Desc_EthMask"; Type="IPv4"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_LAN"}
    @{File="config.txt"; Param="Identification"; Default="Clauger auto registered Ewon"; Description="Desc_Identification"; Type="Text"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_Identification"}
    @{File="config.txt"; Param="NtpServerAddr"; Default="ntp.talk2m.com"; Description="Desc_NtpServer"; Type="Text"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_NTP"}
    @{File="config.txt"; Param="NtpServerPort"; Default="123"; Description="Desc_NtpPort"; Type="Integer"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_NTP"}
    @{File="config.txt"; Param="Timezone"; Default="Europe/Paris"; Description="Desc_Timezone"; Type="Text"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_NTP"}
    @{File="config.txt"; Param="Password"; Default="adm"; Description="Desc_Password"; Type="Password"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_Security"}
    @{File="program.bas"; Param="AccountName"; Default=""; Description="Desc_AccountName"; Type="Text"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_MyPortal"}
    @{File="program.bas"; Param="AccountAuthorization"; Default=""; Description="Desc_AccountAuth"; Type="Password"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_MyPortal"}

    # Connection type specific (automatic values - never shown in UI)
    @{File="comcfg.txt"; Param="WANCnx"; Default=$null; Description=$null; Value4G="1"; ValueEthernet="2"; ValueDatalogger="0"; Type="Auto"; AlwaysAsk=$false; ConnectionType=$null; Condition=$null; Choices=$null; Group=$null}
    @{File="comcfg.txt"; Param="WANItfProt"; Default=$null; Description=$null; Value4G="1"; ValueEthernet="3"; ValueDatalogger="0"; Type="Auto"; AlwaysAsk=$false; ConnectionType=$null; Condition=$null; Choices=$null; Group=$null}
    @{File="comcfg.txt"; Param="WANPermCnx"; Default=$null; Description=$null; Value4G="1"; ValueEthernet="1"; ValueDatalogger="0"; Type="Auto"; AlwaysAsk=$false; ConnectionType=$null; Condition=$null; Choices=$null; Group=$null}
    @{File="comcfg.txt"; Param="LANWANConfig"; Default=$null; Description=$null; Value4G="8"; ValueEthernet="8"; ValueDatalogger="0"; Type="Auto"; AlwaysAsk=$false; ConnectionType=$null; Condition=$null; Choices=$null; Group=$null}

    # Ethernet specific
    @{File="comcfg.txt"; Param="UseBOOTP2"; Default="2"; Description="Desc_UseBOOTP2"; Type="Choice"; Choices=@("0","2"); ConnectionType="Ethernet"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Group="Group_WAN"}
    @{File="comcfg.txt"; Param="EthIpAddr2"; Default=""; Description="Desc_EthIpAddr2"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Required=$true; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_WAN"}
    @{File="comcfg.txt"; Param="EthIpMask2"; Default="255.255.255.0"; Description="Desc_EthIpMask2"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Required=$true; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_WAN"}
    @{File="comcfg.txt"; Param="EthGW"; Default=""; Description="Desc_EthGW"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Required=$true; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_WAN"}
    @{File="comcfg.txt"; Param="EthDns1"; Default="8.8.8.8"; Description="Desc_EthDns1"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Required=$true; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_WAN"}
    @{File="comcfg.txt"; Param="EthDns2"; Default="1.1.1.1"; Description="Desc_EthDns2"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Required=$true; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_WAN"}

    # Ethernet Proxy
    @{File="comcfg.txt"; Param="WANPxyMode"; Default="0"; Description="Desc_WANPxyMode"; Type="Choice"; Choices=@("0","1","2","10"); ConnectionType="Ethernet"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Group="Group_Proxy"}
    @{File="comcfg.txt"; Param="WANPxyAddr"; Default=""; Description="Desc_WANPxyAddr"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="WANPxyMode!=0"; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_Proxy"}
    @{File="comcfg.txt"; Param="WANPxyPort"; Default="8080"; Description="Desc_WANPxyPort"; Type="Integer"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="WANPxyMode!=0"; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_Proxy"}
    @{File="comcfg.txt"; Param="WANPxyUsr"; Default=""; Description="Desc_WANPxyUsr"; Type="Text"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="WANPxyMode=1,WANPxyMode=2"; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_Proxy"}
    @{File="comcfg.txt"; Param="WANPxyPass"; Default=""; Description="Desc_WANPxyPass"; Type="Password"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="WANPxyMode=1,WANPxyMode=2"; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_Proxy"}

    # 4G specific
    @{File="comcfg.txt"; Param="PIN"; Default="0000"; Description="Desc_PIN"; Type="PIN"; ConnectionType="4G"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_SIM"}
    @{File="comcfg.txt"; Param="PdpApn"; Default="orange"; Description="Desc_PdpApn"; Type="Text"; ConnectionType="4G"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_APN"}
    @{File="comcfg.txt"; Param="PPPClUserName1"; Default="orange"; Description="Desc_PPPUser"; Type="Text"; ConnectionType="4G"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_APN"}
    @{File="comcfg.txt"; Param="PPPClPassword1"; Default="orange"; Description="Desc_PPPPass"; Type="Password"; ConnectionType="4G"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_APN"}

    # Datalogger specific
    @{File="comcfg.txt"; Param="EthGW"; Default=""; Description="Desc_EthGW"; Type="IPv4"; ConnectionType="Datalogger"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_NetConfig"}
    @{File="comcfg.txt"; Param="EthDns1"; Default="8.8.8.8"; Description="Desc_EthDns1"; Type="IPv4"; ConnectionType="Datalogger"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_NetConfig"}
    @{File="comcfg.txt"; Param="EthDns2"; Default="1.1.1.1"; Description="Desc_EthDns2"; Type="IPv4"; ConnectionType="Datalogger"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; ValueDatalogger=$null; Choices=$null; Group="Group_NetConfig"}
)

function Get-ParameterDefinitions {
    return $Script:ParameterDefinitions
}

function Get-CommonParameters {
    return @($Script:ParameterDefinitions | Where-Object { $_.AlwaysAsk -eq $true })
}

function Get-ConnectionParameters {
    param([string]$ConnectionType)
    return @($Script:ParameterDefinitions | Where-Object { $_.ConnectionType -eq $ConnectionType })
}

function Get-AutoParameters {
    return @($Script:ParameterDefinitions | Where-Object { $_.Type -eq "Auto" })
}

function Test-ParameterCondition {
    param(
        [string]$Condition,
        [hashtable]$CollectedParams
    )

    if (-not $Condition) { return $true }

    $conditions = $Condition -split ','
    $anyConditionMet = $false

    foreach ($cond in $conditions) {
        if ($cond -match '^(.+)!=(.+)$') {
            $condParam = $Matches[1]
            $condValue = $Matches[2]
            if ($CollectedParams[$condParam] -ne $condValue) {
                $anyConditionMet = $true
                break
            }
        } elseif ($cond -match '^(.+)=(.+)$') {
            $condParam = $Matches[1]
            $condValue = $Matches[2]
            if ($CollectedParams[$condParam] -eq $condValue) {
                $anyConditionMet = $true
                break
            }
        }
    }

    return $anyConditionMet
}

function Get-ConditionTriggers {
    param([string]$Condition)
    if (-not $Condition) { return @() }
    $triggers = @()
    foreach ($part in ($Condition -split ',')) {
        if ($part -match '^(.+?)[!=]') {
            $triggers += $Matches[1]
        }
    }
    return $triggers | Select-Object -Unique
}

function Get-ChoiceLabels {
    param([string]$ParamName)
    switch ($ParamName) {
        "UseBOOTP2"  { return [ordered]@{ "0" = (T "Choice_Static"); "2" = (T "Choice_DHCP") } }
        "WANPxyMode" { return [ordered]@{ "0" = (T "Choice_NoProxy"); "1" = (T "Choice_BasicAuth"); "2" = (T "Choice_NTLMAuth"); "10" = (T "Choice_NoAuth") } }
        default      { return [ordered]@{} }
    }
}

function Get-UnusedParams {
    param(
        [string]$ConnectionType,
        [hashtable]$CollectedParams
    )

    $unused = @()
    if ($ConnectionType -eq "4G") {
        $unused = @("UseBOOTP2", "EthIpAddr2", "EthIpMask2", "EthGW", "EthDns1", "EthDns2", "WANPxyMode", "WANPxyAddr", "WANPxyPort", "WANPxyUsr", "WANPxyPass")
    } elseif ($ConnectionType -eq "Datalogger") {
        $unused = @("PIN", "PdpApn", "PPPClUserName1", "PPPClPassword1", "UseBOOTP2", "EthIpAddr2", "EthIpMask2", "WANPxyMode", "WANPxyAddr", "WANPxyPort", "WANPxyUsr", "WANPxyPass")
    } else {
        $unused = @("PIN", "PdpApn", "PPPClUserName1", "PPPClPassword1")

        if ($CollectedParams["UseBOOTP2"] -eq "2") {
            $unused += @("EthIpAddr2", "EthIpMask2", "EthGW", "EthDns1", "EthDns2")
        }

        if ($CollectedParams["WANPxyMode"] -eq "0") {
            $unused += @("WANPxyAddr", "WANPxyPort", "WANPxyUsr", "WANPxyPass")
        } elseif ($CollectedParams["WANPxyMode"] -eq "10") {
            $unused += @("WANPxyUsr", "WANPxyPass")
        }
    }

    return $unused
}

function Get-AutoParamValues {
    param([string]$ConnectionType)

    $values = @{}
    foreach ($paramDef in (Get-AutoParameters)) {
        $val = switch ($ConnectionType) {
            "4G"         { $paramDef.Value4G }
            "Ethernet"   { $paramDef.ValueEthernet }
            "Datalogger" { $paramDef.ValueDatalogger }
        }
        if ($null -ne $val) {
            $values[$paramDef.Param] = $val
        }
    }
    return $values
}
