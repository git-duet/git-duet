# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git dci -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

To run tests locally:

1. Install [`bats`](https://github.com/sstephenson/bats.git)
1. `go install ./...` (make sure this ends up in your `$PATH`)
1. `bats test`
