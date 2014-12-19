# NoSQL Stream

[![Build Status](https://secure.travis-ci.org/snowyu/nosql-stream.png?branch=master)](http://travis-ci.org/snowyu/nosql-stream)

[![NPM](https://nodei.co/npm/nosql-stream.png?stars&downloads&downloadRank)](https://nodei.co/npm/nosql-stream/)

Add the streamable ability to the [abstract-nosql](https://github.com/snowyu/abstract-nosql) database.

## ReadStream

ReadStream is used to search and read the [abstract-nosql](https://github.com/snowyu/abstract-nosql) database.

You must implement the db.iterator(options), iterator.next() and iterator.end() to use. (see [abstract-nosql](https://github.com/snowyu/abstract-nosql))

* db.iterator(options): create an iterator instance
* iterator.next() and iterator.end(): the instance method of the iterator

The resulting stream is a Node.js-style [Readable Stream](http://nodejs.org/docs/latest/api/stream.html#stream_readable_stream)
where `'data'` events emit objects with `'key'` and `'value'` pairs.

You can also use the `gt`, `lt` and `limit` options to control the
range of keys that are streamed. And you can use the filter function to filter the resulting stream.

### Usage

ReadStream(db, [options[, makeData]])


__arguments__

* db: the [abstract-nosql](https://github.com/snowyu/abstract-nosql) db instance must be exists.
* options object
  * db: the same with the db argument
  * filter *(function)*: the filter function to filter the resulting stream.
  * lte/lt/gt/gte: control the range of keys that are streamed.
  * limit: limit the key's count of the resulting stream.
* makeData function
  * just overwrite this if you wanna decode or transform the data.


```js

var NoSQLStream=require('nosql-stream')
var FILTER_EXCLUDED = require('nosql-stream/lib/consts').FILTER_EXCLUDED
var ReadStream = NoSQLStream.ReadStream


function filter(key,value) {
  if (key % 2 === 0) return FILTER_EXCLUDED
}
var readStream = ReadStream(db, {filter:filter})
//or:
var readStream = new ReadStream(db, {filter:filter})

  readStream.on('data', function (data) {
    console.log(data.key, '=', data.value)
  })
  .on('error', function (err) {
    console.log('Oh my!', err)
  })
  .on('close', function () {
    console.log('Stream closed')
  })
  .on('end', function () {
    console.log('Stream closed')
  })


```

## WriteStream

WriteStream is used to write data to the [abstract-nosql](https://github.com/snowyu/abstract-nosql) database.

The WriteStream is a Node.js-style [Writable Stream](http://nodejs.org/docs/latest/api/stream.html#stream_writable_stream) which accepts objects with `'key'` and `'value'` pairs on its `write()` method.

The WriteStream will buffer writes and submit them as a `batch()` operations where writes occur *within the same tick*.

### Usage

WriteStream(db, [options])

__arguments__

* options object
  * db: the [abstract-nosql](https://github.com/snowyu/abstract-nosql) db instance must be exists.
* db: the same with options.db


```js

var NoSQLStream=require('nosql-stream')
var WriteStream = NoSQLStream.WriteStream

var ws = WriteStream(db)
//or:
var ws = new WriteStream(db)


ws.on('error', function (err) {
  console.log('Oh my!', err)
})
ws.on('finish', function () {
  console.log('Write Stream finish')
})

ws.write({ key: 'name', value: 'Yuri Irsenovich Kim' })
ws.write({ key: 'dob', value: '16 February 1941' })
ws.write({ key: 'spouse', value: 'Kim Young-sook' })
ws.write({ key: 'occupation', value: 'Clown' })
ws.end()

```

