# Dockerized Automation Job

A small Dockerized Bash automation job that fetches monitor check data from an API endpoint, summarizes the health status of those checks, prints the result in the terminal, and sends a webhook alert when failed checks are found.

The project is built around a single shell script, `entrypoint.sh`, and is packaged with Docker so it can run consistently with `bash`, `curl`, `jq`, and `awk` available.

## What It Does

1. Reads `API_URL` and `WEBHOOK_URL` from environment variables.
2. Calls `API_URL` with `curl`.
3. Saves the API response to `data.json`.
4. Parses `.checks[]` from the JSON response.
5. Counts:
   - total monitor checks
   - successful checks where `ok` is `true` and `status_code` is `200`
   - failed checks for everything else
6. Prints the summary to the terminal.
7. Sends a webhook alert when one or more checks failed.

## Project Structure

```text
.
├── .dockerignore
├── .env.example
├── .github/
│   └── workflows/
│       └── linter.yml
├── .gitignore
├── Dockerfile
├── README.md
├── assets/
│   ├── discord alert.png
│   └── terminaloutput.png
├── data.json
├── docker-compose.yml
└── entrypoint.sh
```

## Main Files

| File | Purpose |
| --- | --- |
| `entrypoint.sh` | Main Bash script that fetches API data, parses checks, prints a report, and sends webhook alerts. |
| `Dockerfile` | Builds an Alpine-based image with pinned versions of `bash`, `curl`, and `jq`. |
| `docker-compose.yml` | Defines the `automation-job` service and loads environment variables from `.env`. |
| `.env.example` | Template for required environment variables. |
| `data.json` | Example monitor-check response and runtime output file used by the script. |
| `.github/workflows/linter.yml` | GitHub Actions workflow using Super-Linter. |
| `assets/` | Screenshots of terminal output and webhook alert output. |

## Requirements

For Docker usage:

- Docker
- Docker Compose

For local usage without Docker:

- Bash
- curl
- jq
- awk

The Docker image installs the required runtime tools automatically.

## Environment Variables

The job requires two environment variables:

| Variable | Required | Description |
| --- | --- | --- |
| `API_URL` | Yes | API endpoint that returns monitor check data as JSON. |
| `WEBHOOK_URL` | Yes | Webhook endpoint used to send alerts when failures are detected. |

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Then update `.env`:

```env
API_URL=your-api-url
WEBHOOK_URL=your-webhook-url
```

The real `.env` file is ignored by Git.

## Expected API Response

The script expects the API response to contain a `checks` array.

Each item in `checks` should include:

- `id`
- `ok`
- `status_code`

Example:

```json
{
  "messages": "Monitor list check",
  "checks": [
    {
      "id": 3654,
      "monitor_id": 2,
      "checked_at": "2026-08-13T11:05:15.786Z",
      "ok": true,
      "status_code": 200
    },
    {
      "id": 3629,
      "monitor_id": 2,
      "checked_at": "2026-08-13T11:02:55.473Z",
      "ok": false,
      "status_code": 200
    }
  ],
  "next_cursor": 3309
}
```

A check is counted as successful only when:

```text
ok == true AND status_code == 200
```

All other checks are counted as failed.
