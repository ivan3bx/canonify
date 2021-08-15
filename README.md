# Canonify

<font color="#dd0033">2021/08 - UNDER DEVELOPMENT</font>

This is a library to retrieve canonical representations of URLs. In the simplest
case, given a URL, an HTTP request is made to that URL and meta tags are parsed
in order to retrieve the canonical URL in a site's meta tag (e.g..)

```html
<link rel="canonical" href="https://example.com/article.html">
```

Using the hypothetical 'link' in a response above:

```
Input:  https://example.com/article.html?utm_source=a&utm_campaign=b
Result: https://example.com/article.html                              (http lookup)
```

If a canonical link is not found in the document, the original URL is returned un-altered,
and no additional steps are taken.

### Excluded Params

Query params present in the original URL but not present in its canonical representation
are presented back to the caller as exclusions:

|  Excluded Params |
| ---------------- |
| "utm_source"     |
| "utm_campaign"   |

### Allowed Params

If the canonical representation returns a query param, it will be marked as
allowed in any additional requests for that domain.

For example, imagine the following scenario:

```
Input:  https://example.com/article.cgi?id=12345&utm_source=foo
Result: https://example.com/article.cgi?id=12345                     (http lookup)
```

the resulting 'excluded' and 'included' params are as follows:

|  Allowed Params |  Excluded Params   |
| --------------- | ------------------ |
|     "id"        | "utm_source"       |

From that point on, the following URLs would be transformed without need of
additional HTTP lookups:

```
Input:  https://example.com/article.cgi?id=88888
Result: https://example.com/article.cgi?id=88888                   (http lookup)

Input:  https://example.com/article.cgi?id=99999&utm_source=bar
Result: https://example.com/article.cgi?id=99999                   (no http lookup)

Input:  https://example.com/article.cgi?utm_source=bar&id=131313
Result: https://example.com/article.cgi?id=131313                  (no http lookup)

etc..
```

### URL assumptions

This approach assumes a **high regularlity** to URL naming schemes originating
from the same domain.

By instantiating a new resolver with a caching store, the resolver will apply
exclusions found in earlier URLs to URLs from the same domain. For the above
example, a second article with the same `utm_source` and `utm_campaign` query
params will have those params stripped and the resulting URL returned, all
without incurring cost of an HTTP request.

In practice, large sites have a regularlity to how their URLs are composed. but
this approach will NOT work for domains has a very irregular URL structure. e.g.

```
# First Request to 'example.com'
Input:         https://example.com/article.cgi?id=111
Actual Result: https://example.com/article.cgi?id=111
Result:        https://example.com/article.cgi?id=111 (correct!)

# Invalid case!
Input:         https://example.com/article.cgi?id=222
Actual Result: https://example.com/some-redirected-url.html
Result:        https://example.com/article.cgi?id=111 (NOT correct!)
```

In the example above, the "example.com" domain has a rewrite rule for the second URL,
and so the second 'result' would be incorrect.

### Cache invalidation rules

#### Parameter differences

If a URL is encountered with a param not seen in the allowed or exclusion list
for that domain, an HTTP request will always be made, and the same rule will be
applied to the result:

```
Input:         https://example.com/article.cgi?id=111
Result:        https://example.com/article.cgi?id=111               (http lookup)
```

|  Allowed Params |  Excluded Params   |
| --------------- | ------------------ |
|     "id"        |                    |


```
Input:         https://example.com/article.cgi?id=111&new_param=abc
Result:        https://example.com/article.cgi?id=111               (http lookup)
```

|  Allowed Params |  Excluded Params   |
| --------------- | ------------------ |
|     "id"        |    "new_param"     |

The example above shows that, since `new_param` was not seen before, an HTTP
request was made. Since `new_param` is not in the second result, it is added as
an excluded param for future lookups to that domain.

#### URL Rewrites

If URL path of the canonical URL does not match the path of the original URL,
the canonical URL will be returned, but caching rules will not be enabled for
that domain, and future lookups will incur the cost of an HTTP request to
resolve canonical URLs.

If the HTTP response does not contain any meta information, no further action
will be taken, and the original URL will be returned as-is.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'canonify'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install canonify

## Usage

(This gem is still under development, and its API is likely to change)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ivan3bx/canonify.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Canonify project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ivan3bx/canonify/blob/main/CODE_OF_CONDUCT.md).
