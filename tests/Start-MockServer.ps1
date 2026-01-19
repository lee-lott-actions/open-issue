param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath
        $method = $request.HttpMethod
        
        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan
        
        $responseJson = $null
        $statusCode = 200

        # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # Mock endpoint: PATCH /repos/:owner/:repo/issues/:issue_number
		elseif ($method -eq "PATCH" -and $path -match '^/repos/([^/]+)/([^/]+)/issues/(\d+)$') {
			$owner = $Matches[1]
		  	$repo = $Matches[2]
		  	$issueNumber = $Matches[3]
			
		  	Write-Host "PATCH /repos/$owner/$repo/issues/$issueNumber" -ForegroundColor Cyan
			
		  	# ---- Read request body ----
		  	$reader = New-Object System.IO.StreamReader($request.InputStream)
		  	$requestBody = $reader.ReadToEnd()
		  	$reader.Close()
			
			Write-Host "Request body: $requestBody"
			Write-Host "Request headers:" 
			$request.Headers.AllKeys | ForEach-Object {
		    	Write-Host "  $_ : $($request.Headers[$_])"
			}
			
			$bodyObj = $null
			if ($requestBody) {
				$bodyObj = $requestBody | ConvertFrom-Json
		  	}
			
		  	# ---- Validate Authorization header ----
		  	$authHeader = $request.Headers["Authorization"]
		  	if (-not $authHeader -or -not $authHeader.StartsWith("Bearer ")) {
			  	$statusCode = 401
			  	$responseJson = @{ message = "Unauthorized: Missing or invalid Bearer token" } | ConvertTo-Json
			}
			
			# ---- Validate body ----
			elseif ($bodyObj.state -ne "open") {
				$statusCode = 400
		    	$responseJson = @{ message = 'Invalid request: state must be "open"' } | ConvertTo-Json
		  	}
		 	# ---- Simulate success case ----
		  	elseif ($owner -eq "test-owner" -and $repo -eq "test-repo" -and $issueNumber -eq "1") {
				$statusCode = 200
				$responseJson = @{ state = "open" } | ConvertTo-Json
		  	}
		  	# ---- Issue not found ----
		  	else {
				$statusCode = 404
			  	$responseJson = @{ message = "Issue not found" } | ConvertTo-Json
		  	}
    	}
		else {
			$statusCode = 404
			$responseJson = @{ message = "Not Found" } | ConvertTo-Json
		}
	
		# Send response
		$response.StatusCode = $statusCode
		$response.ContentType = "application/json"
		if ($statusCode -eq 204) {
			$response.ContentLength64 = 0
		}
		else {
			$buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
			$response.ContentLength64 = $buffer.Length
			$response.OutputStream.Write($buffer, 0, $buffer.Length)
		}
		$response.Close()
	}
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}
