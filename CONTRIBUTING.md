# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git dci -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Building

Requires Go 1.7

Using [`gvt`](https://github.com/FiloSottile/gvt) to manage dependencies.

To run tests locally:

0. Install [`bats`](https://github.com/sstephenson/bats.git)
0. `./scripts/build`
0. `./scripts/install`
0. `./scripts/test`
