# Explore Project - AI Agent Guidelines

> **⚠️ IMPORTANT: This is the primary agent configuration file.**
> 
> - **DO NOT edit** `.cursorrules` or `CLAUDE.md` - they are symlinks to this file
> - **ONLY edit** `AGENTS.md` when adding or modifying agent rules
> - Changes to `AGENTS.md` automatically apply to all agent specifications
> - The symlinks ensure compatibility across different AI assistants (Cursor, Claude, etc.)

## Project Overview
Ruby library for exploring web resources via HTTP requests, parsing URIs, and analyzing website metadata.

## Code Style & Testing

### Testing Framework: Minitest
- Use Minitest spec style with `describe` blocks for test organization
- **Never use comment-based test grouping** - use proper `describe` blocks instead
- Use `let` for test fixtures and shared data
- Use `it` blocks for individual test cases
- Prefer predicate assertions: `assert_predicate obj, :method?` over `assert obj.method?`
- Follow Minitest best practices from: https://docs.seattlerb.org/minitest/

### Test Organization Pattern
```ruby
describe MyClass do
  let(:fixture) { "value" }
  
  describe "feature group" do
    it "does something specific" do
      # test code
    end
  end
end
```

### Ruby Style
- Follow existing `.rubocop.yml` configuration
- Use frozen string literals
- Prefer delegation over manual method definitions
- Use ActiveSupport extensions where appropriate

## Architecture Patterns

### URI Handling
- Parse URIs once and pass `Explore::URI` objects through the system
- Never reparse URIs unnecessarily
- Use `input.is_a?(Explore::URI) ? input : Explore::URI.new(input)` pattern

### Delegation
- Use ActiveSupport's `delegate` macro for clean delegation
- Include `allow_nil: true` for methods that should return nil on failure
- Document delegated methods with YARD `@!method` directives

### Error Handling
- Capture errors in arrays rather than raising for user-facing classes
- Provide `.errors` accessor for error inspection
- Use custom error classes: `Explore::TimeoutError`, `Explore::RequestError`

### Caching
- Cache expensive operations (HTTP requests, parsing)
- Provide `reset!` methods to clear caches
- Use `||=` pattern for lazy initialization

## Documentation

### YARD Documentation (Configured)
- Project uses YARD for API documentation generation
- All public methods must have YARD documentation
- Include `@param`, `@return`, `@option` tags with types
- Add `@example` blocks for complex methods
- Document error conditions and edge cases
- Generate docs with: `rake yard`
- View docs: open `doc/index.html`

### YARD Documentation Style
```ruby
# Brief description of what the method does
#
# @param name [Type] Description of parameter
# @param options [Hash] Options hash
# @option options [Type] :key Description of option
# @return [Type] Description of return value
# @raise [ErrorClass] When this error occurs
#
# @example Basic usage
#   obj.method(arg)
#   # => result
def method(name, options = {})
  # implementation
end
```

### Usage Documentation
- Create comprehensive usage guides in `docs/` directory
- Include quick start, API reference, examples, and common patterns
- Use real-world examples
- **Do not create refactoring summaries or implementation notes**

## Files to Modify with Permission Only
- `lib/explore.rb` - Core module definition
- Any files not explicitly mentioned in the task
- Git configuration
- Gemspec or Gemfile (unless specifically requested)

## Testing Requirements
- All new features must have comprehensive tests
- Test both success and failure paths
- Test edge cases (nil, empty, malformed input)
- Create VCR cassettes for HTTP interactions
- Ensure all tests pass: `rake test`
- Fix any RuboCop violations: `rubocop`

## VCR Cassettes
- Store in `test/vcr_cassettes/`
- Use descriptive names: `head_example_org.yml`, `head_github_redirect.yml`
- Keep cassettes minimal and focused on specific scenarios

## Performance Considerations
- Avoid unnecessary object allocation
- Reuse parsed objects (URI, Domain)
- Minimize HTTP requests through caching
- Profile with `minitest/benchmark` when needed

## Common Patterns

### Resource Exploration Flow
```ruby
explore = Explore.new("https://example.com")  # Creates Resource
explore.uri                                    # Returns parsed Explore::URI
explore.head                                   # Makes HEAD request (cached)
explore.head.uri                              # Final URI after redirects
```

### Options Merging
```ruby
DEFAULT_OPTIONS = { /* defaults */ }.freeze

def initialize(uri, options = {})
  @options = DEFAULT_OPTIONS.deep_merge(options)
  # use @options
end
```

### Safe Delegation
```ruby
delegate :method_name, to: :object, allow_nil: true

def custom_method
  @object&.attribute
end
```

## Version Compatibility
- Ruby 2.7+
- Minitest 5.x
- Follow semantic versioning

## References
- [Minitest Documentation](https://docs.seattlerb.org/minitest/)
- [Minitest Cheatsheet](https://devhints.io/minitest)
- Project README for usage examples

