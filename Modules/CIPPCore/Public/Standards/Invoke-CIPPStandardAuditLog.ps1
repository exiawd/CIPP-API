function Invoke-CIPPStandardAuditLog {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) AuditLog
    .SYNOPSIS
        (Label) Enable the Unified Audit Log
    .DESCRIPTION
        (Helptext) Enables the Unified Audit Log for tracking and auditing activities. Also runs Enable-OrganizationCustomization if necessary.
        (DocsDescription) Enables the Unified Audit Log for tracking and auditing activities. Also runs Enable-OrganizationCustomization if necessary.
    .NOTES
        CAT
            Global Standards
        TAG
            "CIS"
            "mip_search_auditlog"
        ADDEDCOMPONENT
        IMPACT
            Low Impact
        ADDEDDATE
            2021-11-16
        POWERSHELLEQUIVALENT
            Enable-OrganizationCustomization
        RECOMMENDEDBY
            "CIS"
            "CIPP"
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards/global-standards#low-impact
    #>

    param($Tenant, $Settings)
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'AuditLog'

    Write-Host ($Settings | ConvertTo-Json)
    $AuditLogEnabled = [bool](New-ExoRequest -tenantid $Tenant -cmdlet 'Get-AdminAuditLogConfig' -Select UnifiedAuditLogIngestionEnabled).UnifiedAuditLogIngestionEnabled

    If ($Settings.remediate -eq $true) {
        Write-Host 'Time to remediate'

        $DehydratedTenant = (New-ExoRequest -tenantid $Tenant -cmdlet 'Get-OrganizationConfig' -Select IsDehydrated).IsDehydrated
        if ($DehydratedTenant -eq $true) {
            try {
                $null = New-ExoRequest -tenantid $Tenant -cmdlet 'Enable-OrganizationCustomization'
                Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Organization customization enabled.' -sev Info
            } catch {
                $ErrorMessage = Get-CippException -Exception $_
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to enable organization customization. Error: $($ErrorMessage.NormalizedError)" -sev Debug -LogData $ErrorMessage
            }
        }

        try {
            if ($AuditLogEnabled -eq $true) {
                Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Unified Audit Log already enabled.' -sev Info
            } else {
                $null = New-ExoRequest -tenantid $Tenant -cmdlet 'Set-AdminAuditLogConfig' -cmdParams @{UnifiedAuditLogIngestionEnabled = $true }
                Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Unified Audit Log Enabled.' -sev Info
            }

        } catch {
            $ErrorMessage = Get-CippException -Exception $_
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to apply Unified Audit Log. Error: $($ErrorMessage.NormalizedError)" -sev Error -LogData $ErrorMessage
        }
    }
    if ($Settings.alert -eq $true) {

        if ($AuditLogEnabled -eq $true) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Unified Audit Log is enabled' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Unified Audit Log is not enabled' -sev Alert
        }
    }

    if ($Settings.report -eq $true) {

        Add-CIPPBPAField -FieldName 'AuditLog' -FieldValue $AuditLogEnabled -StoreAs bool -Tenant $Tenant
    }
}
