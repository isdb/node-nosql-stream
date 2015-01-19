### NoSQL Stream [![Build Status](https://img.shields.io/travis/snowyu/node-nosql-stream/master.svg)](http://travis-ci.org/snowyu/node-nosql-stream) [![npm](https://img.shields.io/npm/v/nosql-stream.svg)](https://npmjs.org/package/nosql-stream) [![downloads](https://img.shields.io/npm/dm/nosql-stream.svg)](https://npmjs.org/package/nosql-stream) [![license](https://img.shields.io/npm/l/nosql-stream.svg)](https://npmjs.org/package/nosql-stream)


Add the streamable ability to the [abstract-nosql](https://github.com/snowyu/node-abstract-nosql) database.


## Usage

Once the Database implements the [AbstractIterator](https://github.com/snowyu/node-abstract-iterator):

* AbstractIterator.\_nextSync() or AbstractIterator.\_next().
* AbstractIterator.\_endSync() or AbstractIterator.\_end().

the db should be the streamable.

But, you should install the [nosql-stream](https://github.com/snowyu/node-nosql-stream) package first.

    npm install nosql-stream
you should install the [nosql-stream](https://github.com/snowyu/node-nosql-stream) package first.

    npm install nosql-stream


```js

var addStreamFeatureTo = require('nosql-stream')
var LevelDB = addStreamFeatureTo(require('nosql-leveldb'))

```
The readStream/createReadStream, keyStream/createKeyStream, valueStream/createValue
and writeStream/createWriteStream methods will be added to the database.


### AbstractNoSql.keyStream(createKeyStream)

create a readable stream.

the data item is key.

### AbstractNoSql.valueStream(createValueStream)

create a readable stream.

the data item is value.

### AbstractNoSql.readStream(createReadStream)

create a readable stream.

the data item is an object: {key:key, value:value}.

* AbstractNoSql.readStream([options])
* AbstractNoSql.createReadStream

__arguments__

* options: the optional options object(note: some options depend on the implementation of the Iterator)
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
      * "[a, b]": from a to b. a,b included. this means {gte='a', lte = 'b'}
      * "(a, b]": from a to b. b included, a excluded. this means {gt='a', lte='b'}
      * "[, b)"   from begining to b, begining included, b excluded. this means {lt='b'}
      * note: this will affect the gt/gte/lt/lte options.
    * array: the key list to get. eg, ['a', 'b', 'c']
  * `'gt'` (greater than), `'gte'` (greater than or equal) define the lower bound of the range to be streamed. Only records where the key is greater than (or equal to) this option will be included in the range. When `reverse=true` the order will be reversed, but the records streamed will be the same.
  * `'lt'` (less than), `'lte'` (less than or equal) define the higher bound of the range to be streamed. Only key/value pairs where the key is less than (or equal to) this option will be included in the range. When `reverse=true` the order will be reversed, but the records streamed will be the same.
  * `'start', 'end'` legacy ranges - instead use `'gte', 'lte'`
  * `'match'` *(string)*: use the minmatch to match the specified keys.
    * Note: It will affect the range[gt/gte or lt/lte(reverse)] options maybe.
  * `'limit'` *(number, default: `-1`)*: limit the number of results collected by this stream. This number represents a *maximum* number of results and may not be reached if you get to the end of the data first. A value of `-1` means there is no limit. When `reverse=true` the highest keys will be returned instead of the lowest keys.
  * `'reverse'` *(boolean, default: `false`)*: a boolean, set true and the stream output will be reversed. 
  * `'keys'` *(boolean, default: `true`)*: whether the `'data'` event should contain keys. If set to `true` and `'values'` set to `false` then `'data'` events will simply be keys, rather than objects with a `'key'` property. Used internally by the `createKeyStream()` method.
  * `'values'` *(boolean, default: `true`)*: whether the `'data'` event should contain values. If set to `true` and `'keys'` set to `false` then `'data'` events will simply be values, rather than objects with a `'value'` property. Used internally by the `createValueStream()` method.

__return__

* object: the read stream object


#### Events

the standard `'data'`, '`error'`, `'end'` and `'close'` events are emitted.
the `'last'` event will be emitted when the last data arrived, the argument is the last raw key.
if no more data the last key is `undefined`.

```js
var MemDB = require("memdown-sync")


var db1 = MemDB("db1")
var db2 = MemDB("db2")

var ws = db1.writeStream()
var ws2 = db2.createWriteStream()

ws.on('error', function (err) {
  console.log('Oh my!', err)
})
ws.on('finish', function () {
  console.log('Write Stream finish')
  //read all data through the ReadStream
  db1.readStream().on('data', function (data) {
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
  .pipe(ws2) //copy Database db1 to db2:
})

ws.write({ key: 'name', value: 'Yuri Irsenovich Kim' })
ws.write({ key: 'dob', value: '16 February 1941' })
ws.write({ key: 'spouse', value: 'Kim Young-sook' })
ws.write({ key: 'occupation', value: 'Clown' })
ws.end()
```

filter usage:

```js
db.createReadStream({filter: function(key, value){
    if (/^hit/.test(key))
        return db.FILTER_INCLUDED
    else key == 'endStream'
        return db.FILTER_STOPPED
    else
        return db.FILTER_EXCLUDED
}})
  .on('data', function (data) {
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

next and last usage for paged data demo:

``` js

var callbackStream = require('callback-stream')

var lastKey = null;

function nextPage(db, aLastKey, aPageSize, cb) {
  var stream = db.readStream({next: aLastKey, limit: aPageSize})
  stream.on('last', function(aLastKey){
    lastKey = aLastKey;
  });

  stream.pipe(callbackStream(function(err, data){
    cb(data, lastKey)
  }))

}

var pageNo = 1;
dataCallback = function(data, lastKey) {
    console.log("page:", pageNo);
    console.log(data);
    ++pageNo;
    if (lastKey) {
      nextPage(db, lastKey, 10, dataCallback);
    }
    else
      console.log("no more data");
}
nextPage(db, lastKey, 10, dataCallback);
```


## ReadStream

ReadStream is used to search and read the [abstract-nosql](https://github.com/snowyu/node-abstract-nosql) database.

You must implement the db.iterator(options), iterator.next() and iterator.end() to use. (See [AbstractIterator](https://github.com/snowyu/node-abstract-iterator))

* db.iterator(options): create an iterator instance
* iterator.next() and iterator.end(): the instance method of the iterator

The resulting stream is a Node.js-style [Readable Stream](http://nodejs.org/docs/latest/api/stream.html#stream_readable_stream)
where `'data'` events emit objects with `'key'` and `'value'` pairs.

You can also use the `gt`, `lt` and `limit` options to control the
range of keys that are streamed. And you can use the filter function to filter the resulting stream.



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

# AbstractIterator

You must implement the AbstractIterator if you wanna the database supports the ReadStreamable ability.

[AbstractIterator](https://github.com/snowyu/node-abstract-iterator)


* AbstractIterator(db[, options])
  * db: Provided with the current instance of [AbstractNoSql](https://github.com/snowyu/node-abstract-nosql).
  * options: the iterator options. see the ReadStream's options.
* next([callback]):
* nextSync():
* end([callback]):
  * it's the alias for free method() to keep comaptiable with abstract-leveldown.
* endSync():
  * it's the alias for freeSync method() to keep comaptiable with abstract-leveldown.
* free():
* freeSync():

The following methods need to be implemented:

## Sync methods:

### AbstractIterator#_nextSync()

Get the next element of this iterator.

__return__

* if any result: return a two elements of array
  * the first is the key, the first element could be null or undefined if options.keys is false
  * the second is the value, the second element could be null or undefined if options.values is false
* or return false, if no any data yet.


#### AbstractIterator#_endSync()

end the iterator.

### Async methods:

these async methods are optional to be implemented.

#### AbstractIterator#_next(callback)
#### AbstractIterator#_end(callback)

