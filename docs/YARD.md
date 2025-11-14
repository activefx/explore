# YARD Documentation Guide

This project uses [YARD](https://yardoc.org/) for API documentation generation.

## Quick Start

### Generate Documentation

```bash
bundle exec rake yard
```

### View Documentation

Open the generated documentation in your browser:

```bash
open doc/index.html
```

Or on Linux:

```bash
xdg-open doc/index.html
```

### Documentation Statistics

See how much of the codebase is documented:

```bash
bundle exec yard stats --list-undoc
```

## YARD Configuration

### `.yardopts`

Project-wide YARD options are configured in `.yardopts`:

```
--markup markdown          # Use Markdown for documentation
--readme README.md         # Use README.md as the index page
--output-dir doc          # Output to doc/ directory
--protected               # Include protected methods
--private                 # Include private methods
lib/**/*.rb               # Document all Ruby files in lib/
-                         # Separator for extra files
README.md                 # Include README
LICENSE.txt               # Include license
docs/*.md                 # Include all docs
```

### Rake Task

The `yard` rake task is configured in `Rakefile`:

```ruby
require "yard"
YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
  t.options = ["--output-dir", "doc", "--readme", "README.md"]
end
```

## Documentation Style Guide

### Class Documentation

```ruby
# Brief description of the class purpose
#
# Longer description with details about behavior, usage patterns,
# and any important considerations.
#
# @example Basic usage
#   obj = MyClass.new("arg")
#   obj.method
#   # => result
#
# @see OtherClass for related functionality
class MyClass
end
```

### Method Documentation

```ruby
# Brief one-line description of what the method does
#
# Longer description with details about the method's behavior,
# edge cases, and usage patterns.
#
# @param name [String] Description of the parameter
# @param options [Hash] Options hash
# @option options [Integer] :timeout Timeout in seconds (default: 30)
# @option options [Boolean] :verbose Enable verbose output
# @return [Array<String>] Description of what is returned
# @raise [ArgumentError] When name is empty
# @raise [TimeoutError] When operation times out
#
# @example Basic usage
#   result = method("value")
#   # => ["result"]
#
# @example With options
#   result = method("value", timeout: 60, verbose: true)
#   # => ["result"]
def method(name, options = {})
  # implementation
end
```

### Attribute Documentation

```ruby
# @return [String] The name of the resource
attr_reader :name

# @return [Integer, nil] The timeout value in seconds, or nil if not set
attr_accessor :timeout
```

### Constant Documentation

```ruby
# Default timeout value in seconds
DEFAULT_TIMEOUT = 30

# Mapping of error codes to error messages
ERROR_MESSAGES = {
  404 => "Not Found",
  500 => "Internal Server Error"
}.freeze
```

### Delegation Documentation

When using `delegate`, document the methods being delegated:

```ruby
# @!method response
#   Get the raw Faraday response object
#   @return [Faraday::Response, nil]
#
# @!method success?
#   Check if the request was successful
#   @return [Boolean, nil]
delegate :response, :success?, to: :request, allow_nil: true
```

## YARD Tags Reference

### Common Tags

- `@param name [Type] description` - Document method parameters
- `@option options [Type] :key description` - Document hash options
- `@return [Type] description` - Document return value
- `@raise [ExceptionClass] description` - Document exceptions
- `@example title` - Provide usage examples
- `@see OtherClass#method` - Cross-reference related code
- `@since version` - Document when added
- `@deprecated Use other_method instead` - Mark as deprecated
- `@note` - Add important notes
- `@todo` - Document future improvements

### Type Specifications

```ruby
[String]                    # Single type
[String, nil]              # Type or nil
[Array<String>]            # Array of strings
[Hash{Symbol => String}]   # Hash with symbol keys and string values
[Boolean]                  # true or false
[Integer, Float]           # Multiple possible types
[#to_s]                    # Duck typing (responds to to_s)
[Explore::URI]             # Custom class type
```

### Visibility Tags

```ruby
# @!visibility private
def internal_method
end

# @!visibility protected
def protected_helper
end
```

## Best Practices

### 1. Document Public API

All public methods, classes, and modules should have complete documentation:

```ruby
# Good: Fully documented
# Perform a HEAD request to the URI
#
# @param uri [Explore::URI, String] The URI to request
# @return [Explore::Head] The HEAD request response
def head(uri)
end

# Bad: No documentation
def head(uri)
end
```

### 2. Provide Examples

Complex methods should include examples:

```ruby
# @example Basic usage
#   head = Head.new("https://example.com")
#   head.success?  # => true
#
# @example With custom timeout
#   head = Head.new("https://example.com", connection_timeout: 10)
```

### 3. Document Edge Cases

Mention important behavior and edge cases:

```ruby
# Returns the final URI after following redirects.
# If no redirects occurred, returns the original URI.
# Returns nil if the request failed.
#
# @return [Explore::URI, nil]
def uri
end
```

### 4. Link Related Methods

Use `@see` to connect related functionality:

```ruby
# @see Resource#head for making HEAD requests
# @see URI#origin for getting the URI origin
```

### 5. Keep It Current

Update documentation when changing method signatures or behavior.

## Continuous Integration

Add YARD documentation checks to your CI pipeline:

```bash
# Check for undocumented code
bundle exec yard stats --list-undoc

# Fail if documentation coverage is below threshold
bundle exec yard stats | grep "documented" | grep -v "100.00%"
```

## Current Documentation Status

As of the latest generation:

```
Files:          13
Modules:         2 (    1 undocumented)
Classes:        15 (   10 undocumented)
Constants:      16 (   11 undocumented)
Attributes:     18 (    0 undocumented)
Methods:        68 (   17 undocumented)
 67.23% documented
```

## Resources

- [YARD Documentation](https://yardoc.org/)
- [YARD Tags Overview](https://rubydoc.info/gems/yard/file/docs/Tags.md)
- [YARD Types Parser](https://rubydoc.info/gems/yard/file/docs/Tags.md#Types)
- [YARD Examples](https://rubydoc.info/gems/yard/file/docs/GettingStarted.md)

