FROM alpine:3.18

RUN apk add --no-cache bash curl

WORKDIR /app

COPY entrypoint.sh .
COPY data.json .

RUN chmod +x entrypoint.sh

CMD ["./entrypoint.sh"]