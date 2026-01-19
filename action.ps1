#!/usr/bin/env pwsh

function open_issue {
    param (
        [string]$IssueNumber,
        [string]$Token,
        [string]$Owner,
        [string]$RepoName
    )

    # Validate required inputs
    if (
        [string]::IsNullOrEmpty($IssueNumber) -or
        [string]::IsNullOrEmpty($RepoName)   -or
        [string]::IsNullOrEmpty($Owner)      -or
        [string]::IsNullOrEmpty($Token)
    ) {
        Write-Output "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }

    Write-Output "Attempting to open issue #$IssueNumber in $Owner/$RepoName"

    # Use MOCK_API if set, otherwise default to GitHub API
    $ApiBaseUrl = if ($env:MOCK_API) { $env:MOCK_API } else { "https://api.github.com" }

    try {
        $Response = Invoke-WebRequest `
            -Method PATCH `
            -Uri "$ApiBaseUrl/repos/$Owner/$RepoName/issues/$IssueNumber" `
            -Headers @{
                Authorization = "Bearer $Token"
                Accept        = "application/vnd.github.v3+json"
                "Content-Type" = "application/json"
            } `
            -Body '{"state":"open"}' `

        $StatusCode = $Response.StatusCode
        
        Write-Output "API Response Code: $StatusCode"

        if ($StatusCode -eq 200) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
            Write-Host "Openend issue #$IssueNumber in $Owner/$RepoName"
        }
        else {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to open issue #$IssueNumber. Status: $StatusCode"
            Write-Host "Error: Failed to open issue #$IssueNumber. Status: $StatusCode"
        }
    }
    catch {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Open Issue Failed; threw an Exception. Status: $StatusCode"
            Write-Host "Error: Failed to open issue due to an Exception: $($_.Exception.Message)"
        }
}
