Readable      = require('readable-stream').Readable
util          = require('abstract-object/lib/util')
Errors        = require('./errors')
consts        = require('./consts')
inherits      = util.inherits
isFunction    = util.isFunction
isObject      = util.isObject
extend        = util._extend

FILTER_INCLUDED = consts.FILTER_INCLUDED
FILTER_EXCLUDED = consts.FILTER_EXCLUDED
FILTER_STOPPED  = consts.FILTER_STOPPED
EncodingError   = Errors.EncodingError

defaultOptions =
  highWaterMark: 1e5

###
readStream is used to search and read the [abstract-nosql](https://github.com/snowyu/abstract-nosql) database.

you must implement the iterator.next() and iterator.end() to use. (see [abstract-nosql](https://github.com/snowyu/abstract-nosql))

The resulting stream is a Node.js-style [Readable Stream](http://nodejs.org/docs/latest/api/stream.html#stream_readable_stream) 
where `'data'` events emit objects with `'key'` and `'value'` pairs. 

You can also use the `gt`, `lt` and `limit` options to control the 
range of keys that are streamed.


###
module.exports = class ReadStream
  inherits ReadStream, Readable

  constructor: (db, aOptions, aMakeData)->
    if (!(this instanceof ReadStream))
      return new ReadStream(db, aOptions, aMakeData)

    @_options = extend({}, defaultOptions)
    @_options = extend(@_options, aOptions || {})
    aOptions  = @_options

    Readable.call(this, { objectMode: true, highWaterMark: aOptions.highWaterMark })

    if aOptions.next
        if aOptions.reverse isnt true
          aOptions.gt = aOptions.next
          aOptions.gte= aOptions.next
        else
          aOptions.lt = aOptions.next
          aOptions.lte= aOptions.next
    @_waiting = false
    db = aOptions.db unless db?
    if isFunction(aOptions.filter)
      @_filter = (item)->
        vKey = vValue = null
        if isObject(item)
          vKey = item.key
          vValue = item.value
        else if aOptions.keys isnt false
          vKey = item
        else vValue = item if aOptions.values isnt false
        aOptions.filter vKey, vValue

    if aMakeData
      @_makeData = aMakeData
    else
      @_makeData = if aOptions.keys isnt false and aOptions.values isnt false then (key, value) ->
          key: key
          value: value
      else if aOptions.values is false then (key) -> key
      else if aOptions.keys   is false then (_, value) -> value
      else ->
    if db
      if !db.isOpen or db.isOpen()
        @setIterator db.iterator(aOptions)
      else
        db.once 'ready', =>
          @setIterator db.iterator(aOptions)

  setIterator: (aIterator)->
    @_iterator = aIterator
    return aIterator.end(->) if @_destroyed
    if @_waiting
      @_waiting = false
      return @_read()
    return this

  _read: ->
    return if @_destroyed
    return @_waiting = true if !@_iterator

    self = this
    @_iterator.next (err, key, value)->
      if err or (key is undefined and value is undefined)
        self.push(null) if !err && !self._destroyed
        return self._cleanup(err)
      try
        value = self._makeData(key, value)
      catch e
        return self._cleanup(new EncodingError(e))

      if !self._destroyed
        if self._filter then switch self._filter(value)
          when FILTER_EXCLUDED
            # skip and read the next.
            self._read()
            return
          when FILTER_STOPPED #halt and this key is excluded.
            self.push(null)
            return self._cleanup()
        self.last = key
        self.push(value)

  _cleanup: (aError)->
    return if @_destroyed
    @_destroyed = true

    if (aError)
      @emit('error', err)

    if @_iterator
      @emit 'last', @last
      @_iterator.end =>
        @_iterator = null
        @emit('close')
    else
      @emit('close')

  destroy: ->
    @cleanup()

  toString: ->
    'NoSQLReadStream'
