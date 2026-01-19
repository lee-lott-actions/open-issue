Describe "open_issue unit tests" {

    BeforeAll {
        # Import the PowerShell implementation of open_issue
        . "$PSScriptRoot/../action.ps1"
    }

    BeforeEach {
        # Create temp GITHUB_OUTPUT file (GitHub Actions compatible)
        $env:GITHUB_OUTPUT = New-TemporaryFile
    }

    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) {
            Remove-Item $env:GITHUB_OUTPUT -Force
        }
    }
    
    Context "Success cases" {

        It "unit: open_issue succeeds with HTTP 200" {
            Mock Invoke-WebRequest {
                return @{
                    StatusCode = 200
                    Content    = '{"state":"closed"}'
                }
            }

            { open_issue -IssueNumber "1" -Token "fake-token" -Owner "test-owner" -Repo "test-repo" } | Should -Not -Throw

            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=success"
        }
    }

    Context "HTTP failure cases" {

        It "unit: open_issue fails with HTTP 403" {
            Mock Invoke-WebRequest {
                return @{
                    StatusCode = 403
                    Content    = '{"message":"Forbidden"}'
                }
            }

            { open_issue -IssueNumber "1" -Token "fake-token" -Owner "test-owner" -Repo "test-repo" } | Should -Not -Throw

            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Failed to open issue #1. Status: 403"
        }

        It "unit: open_issue fails with HTTP 404" {
            Mock Invoke-WebRequest {
                return @{
                    StatusCode = 404
                    Content    = '{"message":"Issue not found"}'
                }
            }

            { open_issue -IssueNumber "1" -Token "fake-token" -Owner "test-owner" -Repo "test-repo" } | Should -Not -Throw

            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Failed to open issue #1. Status: 404"
        }
    }

    Context "Parameter validation failures" {

        It "unit: open_issue fails with empty issue_number" {
            { open_issue -IssueNumber "" -Token "fake-token" -Owner "test-owner" -Repo "test-repo" } | Should -Not -Throw

            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: open_issue fails with empty token" {
            { open_issue -IssueNumber "1" -Token "" -Owner "test-owner" -Repo "test-repo" } | Should -Not -Throw

            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: open_issue fails with empty owner" {
            { open_issue -IssueNumber "1" -Token "fake-token" -Owner "" -Repo "test-repo" } | Should -Not -Throw

            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: open_issue fails with empty repository" {
            { open_issue -IssueNumber "1" -Token "fake-token" -Owner "test-owner" -Repo "" } | Should -Not -Throw

            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }
    }
}
