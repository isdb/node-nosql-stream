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
* options object(note: some options depend on the implementation of the Iterator)
  * db: the same with the db argument
  * `'next'`: the raw key data to ensure the readStream return keys is greater than the key. See `'last'` event.
    * note: this will affect the range[gt/gte or lt/lte(reverse)] options.
  * `'filter'` *(function)*: to filter data in the stream
    * function filter(key, value) if return:
      *  0(consts.FILTER_INCLUDED): include this item(default)
      *  1(consts.FILTER_EXCLUDED): exclude this item.
      * -1(consts.FILTER_STOPPED): stop stream.
    * note: the filter function argument 'key' and 'value' may be null, it is affected via keys and values of this options.
  * `'range'` *(string or array)*: the keys are in the give range as the following format:
    * string:
      * "[a, b]": from a to b. a,b included. this means {gte:'a', lte: 'b'}
      * "(a, b]": from a to b. b included, a excluded. this means {gt:'a', lte:'b'}
      * "[, b)" : from begining to b, begining included, b excluded. this means {lt:'b'}
      * "(, b)" : from begining to b, begining excluded, b excluded. this means {gt:null, lt:'b'}
      * note: this will affect the gt/gte/lt/lte options.
        * "(,)": this is not be allowed. the ending should be a value always.
    * array: the key list to get. eg, ['a', 'b', 'c']
      * `gt`/`gte`/`lt`/`lte` options will be ignored.
  * `'gt'` (greater than), `'gte'` (greater than or equal) define the lower bound of the range to be streamed. Only records where the key is greater than (or equal to) this option will be included in the range. When `reverse=true` the order will be reversed, but the records streamed will be the same.
  * `'lt'` (less than), `'lte'` (less than or equal) define the higher bound of the range to be streamed. Only key/value pairs where the key is less than (or equal to) this option will be included in the range. When `reverse=true` the order will be reversed, but the records streamed will be the same.
  * `'start', 'end'` legacy ranges - instead use `'gte', 'lte'`
  * `'match'` *(string)*: use the minmatch to match the specified keys.
    * Note: It will affect the range[gt/gte or lt/lte(reverse)] options maybe.
  * `'limit'` *(number, default: `-1`)*: limit the number of results collected by this stream. This number represents a *maximum* number of results and may not be reached if you get to the end of the data first. A value of `-1` means there is no limit. When `reverse=true` the highest keys will be returned instead of the lowest keys.
  * `'reverse'` *(boolean, default: `false`)*: a boolean, set true and the stream output will be reversed. 
  * `'keys'` *(boolean, default: `true`)*: whether the `'data'` event should contain keys. If set to `true` and `'values'` set to `false` then `'data'` events will simply be keys, rather than objects with a `'key'` property.
  * `'values'` *(boolean, default: `true`)*: whether the `'data'` event should contain values. If set to `true` and `'keys'` set to `false` then `'data'` events will simply be values, rather than objects with a `'value'` property.

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

