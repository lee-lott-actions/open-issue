Describe "Open-Issue unit tests" {

    BeforeAll {
        # Import the PowerShell implementation of Open-Issue
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
        It "unit: Open-Issue succeeds with HTTP 200" {
            Mock Invoke-WebRequest {
                return @{
                    StatusCode = 200
                    Content    = '{"state":"closed"}'
                }
            }

            Open-Issue -IssueNumber "1" -Token "fake-token" -Owner "test-owner" -Repo "test-repo"
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=success"
        }
    }

    Context "HTTP failure cases" {
        It "unit: Open-Issue fails with HTTP 403" {
            Mock Invoke-WebRequest {
                return @{
                    StatusCode = 403
                    Content    = '{"message":"Forbidden"}'
                }
            }

            Open-Issue -IssueNumber "1" -Token "fake-token" -Owner "test-owner" -Repo "test-repo"
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Failed to open issue #1. HTTP Status: 403"
        }

        It "unit: Open-Issue fails with HTTP 404" {
            Mock Invoke-WebRequest {
                return @{
                    StatusCode = 404
                    Content    = '{"message":"Issue not found"}'
                }
            }

            Open-Issue -IssueNumber "1" -Token "fake-token" -Owner "test-owner" -Repo "test-repo"
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Failed to open issue #1. HTTP Status: 404"
        }
    }

    Context "Parameter validation failures" {
        It "unit: Open-Issue fails with empty issue_number" {
            Open-Issue -IssueNumber "" -Token "fake-token" -Owner "test-owner" -Repo "test-repo"
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: Open-Issue fails with empty token" {
            Open-Issue -IssueNumber "1" -Token "" -Owner "test-owner" -Repo "test-repo"
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: Open-Issue fails with empty owner" {
            pen_issue -IssueNumber "1" -Token "fake-token" -Owner "" -Repo "test-repo"
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: Open-Issue fails with empty repository" {
            Open-Issue -IssueNumber "1" -Token "fake-token" -Owner "test-owner" -Repo ""
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }
    }
}
