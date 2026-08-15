# Dockerized Automation Job

A small Dockerized Bash automation job that fetches monitor check data from an API endpoint, summarizes the health status of those checks, prints the result in the terminal, and sends a webhook alert when failed checks are found.

The project is built around a single shell script, `entrypoint.sh`, and is packaged with Docker so it can run consistently with `bash`, `curl`, `jq`, and `awk` available.
