FROM alpine:3.18

RUN apk add --no-cache \
    bash=5.2.15-r5 \
    curl=8.12.1-r0 \
    jq=1.6-r4

WORKDIR /app

COPY entrypoint.sh .
COPY data.json .

RUN chmod +x entrypoint.sh

CMD ["./entrypoint.sh"]