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

## Run With Docker Compose

Build and run the job:

```bash
docker compose up --build
```

Run it again after the image has already been built:

```bash
docker compose up
```

Run in detached mode:

```bash
docker compose up -d
```

View logs:

```bash
docker compose logs automation-job
```

Stop the container:

```bash
docker compose down
```

## Run With Docker Directly

Build the image:

```bash
docker build -t automation-job .
```

Run the container with environment variables:

```bash
docker run --rm \
  -e API_URL="your-api-url" \
  -e WEBHOOK_URL="your-webhook-url" \
  automation-job
```

Or load values from `.env`:

```bash
docker run --rm --env-file .env automation-job
```

## Run Locally

Install the required tools first, then export the environment variables:

```bash
export API_URL="your-api-url"
export WEBHOOK_URL="your-webhook-url"
./entrypoint.sh
```

Make the script executable if needed:

```bash
chmod +x entrypoint.sh
```

## Example Terminal Output

The script prints a summary like this:

```text
Total Monitors: 30
ALERT: 5
Success: 25
```

Screenshot:

![Terminal output](assets/terminaloutput.png)

## Webhook Alert

When failed checks are detected, the script sends a JSON payload to `WEBHOOK_URL`.

The alert content includes:

- number of failed checks
- total number of checks
- number of successful checks

Screenshot:

![Discord alert](assets/discord%20alert.png)

## How The Script Works

The core workflow in `entrypoint.sh` is:

```bash
response=$(curl -fsS --max-time 15 --retry 3 "${API_URL}")
echo "$response" | jq '.' > data.json
```

This fetches the API response and formats it into `data.json`.

The report is generated with `jq` and `awk`:

```bash
jq -r '.checks[] | "\(.id) \(.ok) \(.status_code)"' data.json
```

The script then counts each check:

- success: `ok` is `true` and `status_code` is `200`
- failed: anything else

If `failed` is greater than `0`, the script posts an alert to the webhook URL.

## Docker Image Details

The image is based on:

```dockerfile
FROM alpine:3.18
```

Installed packages:

- `bash=5.2.15-r5`
- `curl=8.12.1-r0`
- `jq=1.6-r4`

The container runs:

```dockerfile
CMD ["./entrypoint.sh"]
```

## GitHub Actions

This project includes a Super-Linter workflow at:

```text
.github/workflows/linter.yml
```

The workflow runs:

- on pushes to branches other than `master` and `main`
- on pull requests targeting `master` or `main`

It uses:

```yaml
github/super-linter@v5
```

## Ignored Files

The following runtime or local files are ignored by Git:

- `.env`
- `data.json`

The Docker build context also ignores:

- `.git`
- `.github`
- `.env`
- `data.json`
- `*.log`

## Troubleshooting

### `API_URL environment variable is not set`

Create a `.env` file or export `API_URL` before running the job.

```bash
API_URL=your-api-url
```

### `WEBHOOK_URL environment variable is not set`

Create a `.env` file or export `WEBHOOK_URL` before running the job.

```bash
WEBHOOK_URL=your-webhook-url
```

### API request fails

The script uses:

```bash
curl -fsS --max-time 15 --retry 3
```

This means the job will:

- fail on HTTP errors
- show curl errors
- time out after 15 seconds
- retry the request up to 3 times

Check that `API_URL` is reachable from inside the container.

### JSON parsing fails

The API response must be valid JSON and must include `.checks[]`.

You can test the response manually:

```bash
curl -fsS "$API_URL" | jq '.'
```

### No webhook alert is sent

Webhook alerts are only sent when `failed` is greater than `0`.

If all checks are successful, the script prints the summary and exits without posting an alert.

## Notes

- `data.json` is generated by the script and is ignored by Git.
- The included `data.json` shows the expected API response shape.
- The container does not mount project files by default, so generated `data.json` stays inside the container unless volumes are added.
- The project is intended as a simple containerized automation job, not a long-running service.
