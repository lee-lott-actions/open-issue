Describe "Open-Issue Unit Tests" {
    BeforeAll {
        $script:IssueNumber = "1"
        $script:Token       = "fake-token"
        $script:Owner       = "test-owner"
        $script:RepoName    = "test-repo"
        $script:MockApiUrl  = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }

    BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }

    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) {
            Remove-Item $env:GITHUB_OUTPUT -Force
            Remove-Variable -Name MOCK_API -Scope Global -ErrorAction SilentlyContinue
        }
    }
    
    Context "Success Cases" {
        It "unit: Open-Issue succeeds with HTTP 200" {
            Mock Invoke-WebRequest {
                return @{
                    StatusCode = 200
                    Content    = '{"state":"open"}'
                }
            }

            Open-Issue -IssueNumber $IssueNumber -Token $Token -Owner $Owner -RepoName $RepoName
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=success"
        }
    }

    Context "HTTP Failure Cases" {
        It "unit: Open-Issue fails with HTTP 404" {
            Mock Invoke-WebRequest {
                return @{
                    StatusCode = 404
                    Content    = '{"message":"Issue not found"}'
                }
            }

            Open-Issue -IssueNumber $IssueNumber -Token $Token -Owner $Owner -RepoName $RepoName
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Error: Failed to open issue #1. HTTP Status: 404"
        }
    }

    Context "Parameter Validation Failure Cases" {
        It "unit: Open-Issue fails with empty issue number" {
            Open-Issue -IssueNumber "" -Token $Token -Owner $Owner -Repo $RepoName
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: Open-Issue fails with empty token" {
            Open-Issue -IssueNumber $IssueNumber -Token "" -Owner $Owner -Repo $RepoName
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: Open-Issue fails with empty owner" {
            Open-Issue -IssueNumber $IssueNumber -Token $Token -Owner "" -Repo $RepoName
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }

        It "unit: Open-Issue fails with empty repository" {
            Open-Issue -IssueNumber $IssueNumber -Token $Token -Owner $Owner -Repo ""
            $output = Get-Content $env:GITHUB_OUTPUT
            $output | Should -Contain "result=failure"
            $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
        }
    }

    Context "Execption Failure Cases" {
        It "unit: Open-Issue fails with exception" {
    		Mock Invoke-WebRequest { throw "API Error" }
    
    		try {
    			Open-Issue -IssueNumber $IssueNumber -Token $Token -Owner $Owner -RepoName $RepoName
    		} catch {}
    
    		$output = Get-Content $env:GITHUB_OUTPUT
    		$output | Should -Contain "result=failure"
    		$output | Where-Object { $_ -match "^error-message=Error: Failed to open issue #1. Exception:" } |
    			Should -Not -BeNullOrEmpty
    	}	
    }    
}
