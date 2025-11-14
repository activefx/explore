# Explore::Head Usage Guide

The `Explore::Head` class provides a convenient way to make HTTP HEAD requests and inspect response headers and status information.

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Initialization](#initialization)
- [Response Methods](#response-methods)
- [Error Handling](#error-handling)
- [Advanced Usage](#advanced-usage)
- [Integration with Resource](#integration-with-resource)

## Quick Start

```ruby
require 'explore'

# Basic HEAD request
head = Explore::Head.new("https://example.com")

if head.success?
  puts "Status: #{head.status_code} #{head.status_text}"
  puts "Content-Type: #{head.content_type}"
  puts "Final URL: #{head.uri}"
else
  puts "Request failed: #{head.errors.join(', ')}"
end
```

## Features

- **Automatic Redirect Following**: Follows HTTP redirects by default (configurable)
- **Graceful Error Handling**: Captures errors instead of raising exceptions
- **Timeout Management**: Configurable connection and read timeouts
- **Retry Logic**: Automatically retries failed requests (default: 2 retries)
- **URI Reuse**: Accepts pre-parsed `Explore::URI` objects to avoid reparsing
- **Delegation**: Clean delegation to underlying Request object for all response methods

## Initialization

### Basic Initialization

```ruby
# With a string URL
head = Explore::Head.new("https://example.com")

# With an Explore::URI object (avoids reparsing)
uri = Explore::URI.new("https://example.com")
head = Explore::Head.new(uri)
```

### With Custom Options

```ruby
head = Explore::Head.new("https://example.com",
  connection_timeout: 10,  # Wait up to 10 seconds for connection
  read_timeout: 20,        # Wait up to 20 seconds for response
  retries: 5,              # Retry up to 5 times
  allow_redirections: false # Don't follow redirects
)
```

### Available Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `connection_timeout` | Integer | 5 | Seconds to wait for connection |
| `read_timeout` | Integer | 10 | Seconds to wait for response |
| `retries` | Integer | 2 | Number of retry attempts |
| `allow_redirections` | Boolean | true | Whether to follow HTTP redirects |
| `faraday_options` | Hash | `{redirect: {limit: 3}}` | Options passed to Faraday |
| `headers` | Hash | `{}` | Custom HTTP headers |

## Response Methods

### Status Information

```ruby
head = Explore::Head.new("https://example.com")

head.success?      # => true (2xx status codes)
head.status_code   # => 200
head.status_text   # => "OK"
```

### URI Information

```ruby
# Get the final URI after any redirects
head = Explore::Head.new("http://github.com")
head.uri.to_s      # => "https://github.com/" (after redirect)
head.uri.scheme    # => "https"
head.uri.host      # => "github.com"
```

### Headers

```ruby
head = Explore::Head.new("https://example.com")

# Get all headers
head.headers       # => Faraday::Utils::Headers object

# Get specific headers
head.content_type      # => "text/html"
head.content_encoding  # => "gzip" (or nil)
head.last_modified     # => "2025-01-13 20:11:20 UTC" (or nil)

# Access any header directly
head.headers['cache-control']  # => "max-age=1161"
```

### Response Object

```ruby
head = Explore::Head.new("https://example.com")

# Access the raw Faraday response
response = head.response
response.env.url          # Faraday environment details
response.env.method       # :head
```

### Request Object

```ruby
head = Explore::Head.new("https://example.com")

# Access the underlying Request object
request = head.request
request.url               # The final URL
request.response          # Same as head.response
```

## Error Handling

The `Head` class handles errors gracefully by capturing them in an errors array rather than raising exceptions.

```ruby
head = Explore::Head.new("https://non-existent-domain-12345.com")

if head.success?
  puts "Success!"
else
  puts "Failed with errors:"
  head.errors.each do |error|
    puts "  - #{error}"
  end
end
```

### When Errors Occur

When a request fails:
- `head.request` will be `nil`
- `head.success?` will return `nil` (falsy)
- `head.uri` will return `nil`
- All delegated methods return `nil` (due to `allow_nil: true`)
- `head.errors` will contain error messages

```ruby
head = Explore::Head.new("https://invalid-url.com")

head.request       # => nil
head.success?      # => nil
head.status_code   # => nil
head.headers       # => nil
head.uri           # => nil
head.errors        # => ["Connection failed: ..."]
```

## Advanced Usage

### Following Redirects

By default, HEAD requests follow up to 3 redirects:

```ruby
head = Explore::Head.new("http://github.com")
head.uri.to_s  # => "https://github.com/" (followed redirect)
```

To disable redirects:

```ruby
head = Explore::Head.new("http://github.com",
  allow_redirections: false
)
```

To change the redirect limit:

```ruby
head = Explore::Head.new("http://github.com",
  faraday_options: { redirect: { limit: 5 } }
)
```

### Custom Headers

```ruby
head = Explore::Head.new("https://api.example.com",
  headers: {
    'Authorization' => 'Bearer token123',
    'User-Agent' => 'MyApp/1.0'
  }
)
```

### Timeout Configuration

```ruby
# For slow servers
head = Explore::Head.new("https://slow-server.com",
  connection_timeout: 30,
  read_timeout: 60
)
```

### Aggressive Retries

```ruby
# For unreliable connections
head = Explore::Head.new("https://unreliable-server.com",
  retries: 10
)
```

## Integration with Resource

The `Head` class is typically used through the `Resource` class:

```ruby
explore = Explore.new("https://example.com")

# Access the parsed URI
explore.uri.to_s   # => "https://example.com"

# Make a HEAD request (cached)
head = explore.head
head.success?      # => true
head.status_code   # => 200

# The URI is passed directly without reparsing
# explore.head calls: Explore::Head.new(@uri)
# where @uri is already an Explore::URI object
```

### Accessing Final URL After Redirects

```ruby
explore = Explore.new("http://github.com")

# Get the final URL after any redirects
explore.head.uri.to_s  # => "https://github.com/"

# Use this for building robots.txt URL
robots_url = "#{explore.head.uri.scheme}://#{explore.head.uri.host}/robots.txt"
# => "https://github.com/robots.txt"
```

### Reset Cached Data

```ruby
explore = Explore.new("https://example.com")
explore.head  # Makes first request

# Later, reset to make a fresh request
explore.reset!
explore.head  # Makes a new request
```

## Performance Tips

1. **Reuse URI objects**: Pass `Explore::URI` objects instead of strings to avoid reparsing
2. **Cache HEAD results**: The `Resource` class caches HEAD requests automatically
3. **Adjust timeouts**: Lower timeouts for fast servers, higher for slow ones
4. **Disable retries**: Set `retries: 0` for time-sensitive applications
5. **Limit redirects**: Set a lower redirect limit if you don't expect many redirects

## Thread Safety

The `Head` class is not thread-safe. Create separate instances for concurrent requests:

```ruby
threads = urls.map do |url|
  Thread.new do
    head = Explore::Head.new(url)
    # Process head response
  end
end
threads.each(&:join)
```

## Debugging

To inspect what's happening:

```ruby
head = Explore::Head.new("https://example.com")

# Check if request was made
puts "Request object: #{head.request.inspect}"

# Check errors
puts "Errors: #{head.errors.inspect}"

# Inspect response
if head.request
  puts "Response status: #{head.status_code}"
  puts "Response headers: #{head.headers.inspect}"
  puts "Final URL: #{head.uri}"
end
```

## Common Patterns

### Check if Resource is Accessible

```ruby
def accessible?(url)
  head = Explore::Head.new(url)
  head.success? == true
end
```

### Get Content Type

```ruby
def content_type(url)
  head = Explore::Head.new(url)
  head.content_type || "unknown"
end
```

### Follow Redirect Chain

```ruby
original_url = "http://bit.ly/shortlink"
head = Explore::Head.new(original_url)

if head.success?
  puts "#{original_url} → #{head.uri}"
end
```

### Conditional Requests

```ruby
def modified_since?(url, date)
  head = Explore::Head.new(url)
  return true unless head.last_modified
  
  Time.parse(head.last_modified) > date
end
```

## See Also

- [Explore::Resource](RESOURCE_USAGE.md) - Main interface for exploring web resources
- [Explore::URI](URI_USAGE.md) - URI parsing and manipulation
- [Explore::Request](REQUEST_USAGE.md) - Lower-level HTTP request handling

