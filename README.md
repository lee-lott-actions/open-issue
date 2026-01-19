# Re-open Issue Action

This GitHub Action opens a specified GitHub issue using the GitHub API. It returns the result of the closure attempt, indicating success or failure, along with an error message if the operation fails.

## Features
- opens a GitHub issue by making a PATCH request to the GitHub API.
- Outputs the result of the closure attempt (`success` or `failure`) and an error message if applicable.
- Requires a GitHub token with repository write access for authentication.

## Inputs
| Name          | Description                                           | Required | Default |
|---------------|-------------------------------------------------------|----------|---------|
| `issue-number`| The issue number to open.                          | Yes      | N/A     |
| `token`       | GitHub token with repository write access.            | Yes      | N/A     |
| `owner`       | The owner of the organization (user or organization). | Yes      | N/A    |
| `repo-name`  | The repository name to which the issue is assigned.    | Yes      | N/A     |

## Outputs
| Name           | Description                                                   |
|----------------|---------------------------------------------------------------|
| `result`       | Result of the issue closure attempt ("success" or "failure"). |
| `error-message`| Error message if the issue closure fails.                     |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/open-issue.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`).

3. **Example Workflow**:
   ```yaml
   name: open Issue
   on:
     issues:
       types: [labeled]
   jobs:
     open-issue:
       runs-on: ubuntu-latest
       steps:
         - name: open Issue
           id: open
           uses: la-actions/open-issue-action@v1
           with:
             issue-number: ${{ github.event.issue.number }}
             token: ${{ secrets.GITHUB_TOKEN }}
             owner: ${{ github.repository_owner }}
             repo-name: ${{ github.event.repository.name }}
         - name: Print Result
           run: |
             if [[ "${{ steps.open.outputs.result }}" == "success" ]]; then
               echo "Issue #${{ github.event.issue.number }} successfully opened."
             else
               echo "Error: ${{ steps.open.outputs.error-message }}"
               exit 1
             fi
