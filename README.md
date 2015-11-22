# Shortener

`Shortener` is a small URL shortener application.

Basically, it's a small API where you can create your own shortened urls.

## Summary

1. [Development](#development)
    1. [Dependencies](#dependencies)
    2. [Configuration](#configuration)
    3. [Server](#development-server)
    4. [Console](#development-console)
    5. [Test suite](#test-suite)
2. [API documentation](#api-documentation)
    1. [Create a shortened url](#create-a-shortened-url)
    2. [Fetch a target url from a shortened url](#fetch-a-target-url-from-a-shortened-url)
3. [Deployment](#deployment)

## Development

### Dependencies

* Ruby 2.2.3
* Redis

### Setup

You can run `bin/setup` to configure your development workstation.

Before running the setup command, you must have `Ruby` 2.2.3 installed.

This command won't install nor verify if you have `Redis` installed, since you
can use it from another machine/container. So, don't forget to have a `Redis`
instance up and running.

### Configuration

#### Redis

You can set another `Redis` instance by providing the env var `REDIS_URL`.
Otherwise, it will use `localhost`. Read more about
[redis url scheme](http://www.iana.org/assignments/uri-schemes/prov/redis).

### Development server

    $ bin/rails s

### Development console

If you want to debug something, you can use the application console.

    $ bin/rails c

### Test suite

To execute the test suite you need to execute the following command:

    $ bin/rspec

## API documentation

### Create a shortened url

```
POST /

Content-Type: application/json
```

#### Parameters

Name | Type | Description
---- | ---- | -----------
`target_url` | `string` | **Required**. This is the target url.
`slug` | `string` | You can provide your own slug to use as the path of the shortened url. (i.e: http://sho.rt/[slug]). If you don't provide any, it will be generated.

#### Example

1. **Without a slug**

        $ curl http://localhost:3000 -i -XPOST -d '{"target_url": "http://blog.tealdi.com.br"}' -H 'Content-Type: application/json'

2. **Providing a slug**

        $ curl http://localhost:3000 -i -XPOST -d '{"slug":"tealdi","target_url": "http://blog.tealdi.com.br"}' -H 'Content-Type: application/json'

#### Response

**Success**

```
HTTP/1.1 201 Created
Location: http://localhost:3000/3b
Content-Type: application/json; charset=utf-8

{"slug":"3b","target_url":"http://blog.tealdi.com.br","self":"http://localhost:3000/3b"}
```


**When the slug has already been takem**

```
HTTP/1.1 409 Conflict
Content-Type: application/json; charset=utf-8

{"error":{"message":"Slug has already been taken: \"tealdi\""}}
```

**When the target url is invalid**

```
HTTP/1.1 400 Bad Request
Content-Type: application/json; charset=utf-8

{"error":{"message":"Invalid target url: \"ftp://www.tealdi.com.br\""}}
```

### Fetch a target url from a shortened url

```
GET /[:slug]
```

#### Parameters

Name | Type | Description
---- | ---- | -----------
`slug` | `string` | **Required**. This is the id of your shortened url.

#### Example

    $ curl http://localhost:3000/3b -i

#### Response

**Success**

```
HTTP/1.1 301 Moved Permanently
Location: http://www.tealdi.com.br

```

**When the slug has not been found**

```
HTTP/1.1 404 Not Found
Content-Type: application/json; charset=utf-8

{"error":{"message":"Slug has not been found: \"not-found\""}}
```

## Deployment

### Redis

[Redis](http://redis.io) is the main data store of this application, since it's
very fast and lightweight. In addition it provides all we need for this
application. So, it's very important to configure your `Redis` instance with
some disk persistance like RDB and/or AOF to avoid losing all the data when
restart your `Redis` instance. You can read more in
[Redis persistence](http://redis.io/topics/persistence).

It's also very important that you keep monitoring the memory usage of your
`Redis` instance, since `Redis` is memory based. If the database increases a
lot, you might have to partition the data. See more in
[Redis partitioning](http://redis.io/topics/partitioning).
