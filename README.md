# MockWebService

MockWebService is a thin wrapper around a [Sinatra](https://github.com/sinatra/sinatra) to make a Mock API (particularly useful for integration testing).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mock_web_service'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mock_web_service

## Usage

**mock_web_service** can be used in two ways.

The first most simpliest way is to just `require 'mock_web_service'` and then include it into
your file (`include MockWebService`) doing this adds a method to the scope in which it was
included.

That method is `mock`. When mock is called it will create a `global` instance of
`MockWebService::Service` which is removed there after.

This can easy be used like this:
```ruby
require 'mock_web_service'
include MockWebService

mock.start 'localhost', 8080

mock.get '/' do
  [200, 'Hello World!']
end

mock.stop
```

It is also possible to inherit from `MockWebService::Service` to extend it further:
```ruby
require 'mock_web_service'

class MyService < MockWebService::Service
  def initialize
    super
    @host = '0.0.0.0'
    @port = 3000
    start @host, @port
  end
end

mock = MyService.new

mock.get '/' do
  [200, 'Hello World!']
end

mock.stop
```

### Service

#### Creating an Endpoint:
Mocking and endpoint is quiet simple. You simply call one of the following instance methods
to the relevant HTTP Verb of the request you would like to make giving it a pathname<string>
and a handler<Proc>:
##### service#get
```ruby
mock.get '/string/pathname' do
  'response'
end

# or

mock.get('/string/pathname') { 'response' }

```
##### service#post
```ruby
mock.post '/string/pathname' do
  # response
end
```
##### service#put
```ruby
mock.put '/string/pathname' do
  # response
end
```
##### service#delete
```ruby
mock.delete '/string/pathname' do
  # response
end
```
##### service#head
##### service#options

An endpoint handler can return anything that a normal Sinatra response can reply with:
i```ruby
# we can return a string

mock.get '/path' do
  'Hello World!'
end

# or an Array

# The array can contain only the response body
mock.get '/path' do
  ['Hello World!']
end

# The first item in the Array can be the HTTP status code
# followed by the response body
mock.get '/path' do
  [200, 'Hello World!']
end

# And you can optionally return HTTP headers as the second array item
mock.get '/path' do
  headers = { 'Content-Type' => 'text/html' }
  [200, headers, 'Hello World!']
end
```

It is possible to access information about the incoming request in the handler
by providing the `Proc` an argument:
```ruby
mock.get '/path' do |request|
  'Hello World'
end
```
### service#reset
To reset a services endpoints (and all history) so you are able to reuse the same service
instance without stopping and starting the HTTP server you can call the `reset` method:
```ruby
mock.reset
```

#### service#log

It is also possible to get a history of the requests made on a verb with a specific
endpoint.

In this example `requests` will be an array of the requests made (which in this case)
will contain an instance of the `Request` object detailed below
```ruby
mock.get '/something' do
  'Hello World!'
end

# GET /something

requests = mock.log(:get, '/something')
```
at this point the request's `response` getter will return an object representing the response, but not before.

### Request
When a request is made to your mock server a Request object is made as a representation
of this request retaining relevant information about that request. This can be accessed
in the endpoint itself:
```ruby
mock.get '/path' do |request|
  if request.query['abc'] == 123
    [200, 'Hello World!']
  else
    [404, 'Sorry Page Not Found']
  end
end
```
The request object has the following getter methods returning their relevant values related to the
incoming request

- body (body of the incoming request) <string>
- method (Verb used for the request) <string>
- headers (Incoming headers) <Hash>
- path <string>
- host <string>
- port <integer>
- url <string>
- fullpath <string>
- base_url <string>
- host_with_port <string>
- query <Hash> (querystring key value pairs)
- params <Hash> (synonymous wtih `query`)
- cookies <Hash>
- user_agent <string>
- accept_encoding <string>
- accept_language <string>
- content_charset <string>
- content_type <string>
- content_length <string>
- referrer <string> (and also `referer`)
- session <Hash>
- response <MockWebService::Response> (this is not available until after the endpoint has responded - see `service#log`)

#### Response
This contains info on the response which corresponds to the request which is belongs to:
```ruby
mock.get '/something' do
  'Hello World!'
end

# GET /something

request = mock.log(:get, '/something').last

response = request.response
```
A response contains the following getters:
- body
- status
- code (synonymous with `status`)
- headers

Is is also possible to make multiple requests to an endpoint set up with no querystring
that is then called with different querystrings. This will match the route handle
and when calling the log with that uri it will return all of the matched requests
```ruby
mock.get '/something' do
  [200]
end

# GET /something?abc=123
# GET /something
# GET /something?def=456

requests = mock.log(:get, '/something')
```
**Routes are matched in the order they are assigned.** It is worth mentioning that the
route which is matched will be the first matching route which has been defined
```ruby
mock.get '/something' do
  'Something!!'
end

mock.get '/something?abc=123' do
  'Something specific'
end

# when making the following request
# GET /something?abc=123&def=456

# this will match the first handler and never reach the more specific one.
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mock_web_service/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
