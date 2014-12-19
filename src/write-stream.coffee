BatchWriteStream  = require('batch-write-stream')
util              = require('abstract-object/lib/util')
Errors            = require('./errors')
consts            = require('./consts')

inherits      = util.inherits
extend        = util._extend
setImmediate  = global.setImmediate || process.nextTick

defaultOptions =
  highWaterMark: 1e5
  maxConcurrentBatches: 4
  type: 'put'
  flushWait: 10

module.exports = class WriteStream
  inherits WriteStream, BatchWriteStream

  constructor: (db, aOptions)->
    if (!(this instanceof WriteStream))
      return new WriteStream(db, aOptions)

    @_options = extend({}, defaultOptions)
    @_options = extend(@_options, aOptions || {})
    db = aOptions.db unless db?
    @db = db
    @_type = @_options.type

    BatchWriteStream.call this,
        objectMode: true
        highWaterMark: @_options.highWaterMark
        maxConcurrentBatches: @_options.maxConcurrentBatches
        flushWait: @_options.flushWait

    @once 'finish', =>
      @emit('close') # backwards compatibility


  _writeBatch: (aBatch, aCallback)->
    @db.batch aBatch, aCallback
  _map: (aItem)->
    type: aItem.type || @_type
    key: aItem.key
    value: aItem.value
    keyEncoding: aItem.keyEncoding || @_options.keyEncoding
    valueEncoding: aItem.valueEncoding || @encoding || @_options.valueEncoding
  toString: ->
      'NoSQLWriteStream'