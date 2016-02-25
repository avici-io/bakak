Bakak
==================

[![Circle CI](https://circleci.com/gh/avici-io/bakak.svg?style=svg)](https://circleci.com/gh/avici-io/bakak)
Avici.io's backend is code-named "Bakak".

### Setup

Install the following first:

```ruby
ruby # probably anything above 2.0.0 will be fine
redis
```

Have the following environment variables set

```ruby
QINIU_AK # Qiniu Access Key
QINIU_SK # Qiniu Secret Key
QINIU_BASEPATH # Your Qiniu Hosted Url
REDIS_HOST
REDIS_PORT
REDIS_DB # redis connection settings
```

You also need to install ```bundler```.

Clone this repository; enter the directory; run

```shell
bundle install
bundle exec ruby index.rb
```

For tests, run

```shell
bundle exec rspec
```

### Documentation

None for now. I will write a basic reference sheet later, after all the api is settled.

### Code Quality & Design

It is mediocre at best, to be honest. I really do not like this piece of code but it is just
somewhat workable.

### Contributing

This project is still in early alpha. While I do appreciate
interests into this project, I feel like I should rather focus
on finishing the basics first.

Everyone is welcomed to comment on the code or provide suggestions
in "Issues". All comments will be carefully read, considered, replied,
and possibly taken.

### License

MIT License