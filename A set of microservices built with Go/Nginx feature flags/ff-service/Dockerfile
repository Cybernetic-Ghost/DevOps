# build
FROM golang:1.23 AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /ff-service

# run
FROM gcr.io/distroless/base-debian12
EXPOSE 8080
USER nonroot:nonroot
COPY --from=build /ff-service /ff-service
ENTRYPOINT ["/ff-service"]

