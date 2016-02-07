# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git dci -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Building

Requires Go 1.5 (using `GOVENDOREXPERIMENT=1`).

Using [`gvt`](https://github.com/FiloSottile/gvt) to manage dependencies.

To run tests locally:

0. `GOVENDOREXPERIMENT=1 go test ./...`
0. Install [`bats`](https://github.com/sstephenson/bats.git)
0. `GOVENDOREXPERIMENT=1 go install ./...` (make sure the artifacts end up in your `$PATH`)
0. `bats test`
