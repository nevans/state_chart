<!--
# @markup markdown
-->
# StateChart

A state machine is a finite set of states that can transition to each other
deterministically due to events.  A statechart is an extension of state
machines, which can have:

* hierarchical (nested) states,
* orthogonal (parallel) states
* history states,
* and more

StateChart is inspired by ["Statecharts: a Visual Formalism for Complex
Systems"][statecharts.pdf], [SCXML], and [the javascript xstate
library][xstate].  In addition to its simple ruby DSL, it aims to (eventually)
be compatible with both SCXML and with xchart's JSON serialization.

![state chart diagram from "Statecharts: a Visual Formalism for Complex Systems" paper by David Harel](docs/images/statecharts-visual-formalism-david-harel.png)

[xstate]: https://xstate.js.org
[statecharts.pdf]: http://www.inf.ed.ac.uk/teaching/courses/seoc/2005_2006/resources/statecharts.pdf
[SCXML]: https://www.w3.org/TR/scxml

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'state_chart'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install state_chart

## Usage

_TODO: Write usage instructions here_

*This gem is not really usable or useful yet!* _...which is why it hasn't been
pushed to rubygems yet._

_The API is still a little bit in flux before the first release, so... until
this README has more instructions, this is just a fun thought experiment._

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/nevans/state_chart. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of
conduct](https://github.com/nevans/state_chart/blob/master/CODE_OF_CONDUCT.md).

## Alternatives

These ruby state machine gems have been well-loved and used in many production
environments for many years:

* [aasm gem](https://github.com/aasm/aasm)
* [state_machines gem](https://github.com/state-machines/state_machines)

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the StateChart project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/nevans/state_chart/blob/master/CODE_OF_CONDUCT.md).
