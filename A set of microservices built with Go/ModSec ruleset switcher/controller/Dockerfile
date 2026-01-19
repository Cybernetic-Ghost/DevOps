FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o controller main.go

FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /root/
COPY --from=builder /app/controller .

EXPOSE 8081

USER 65534:65534

CMD ["./controller"]