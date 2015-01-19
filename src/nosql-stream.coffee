# Copyright (c) 2014 Riceball LEE, MIT License
Errors                = require("abstract-object/Error")
#AbstractNoSQL         = require("abstract-nosql")
#inherits              = require("abstract-object/lib/util/inherits")
#inheritsDirectly      = require("abstract-object/lib/util/inheritsDirectly")
#isInheritedFrom       = require("abstract-object/lib/util/isInheritedFrom")
isFunction            = require("abstract-object/lib/util/isFunction")
extend                = require("abstract-object/lib/util/_extend")
InvalidArgumentError  = Errors.InvalidArgumentError
ReadStream            = require("./read-stream")
WriteStream           = require("./write-stream")

module.exports = class StreamNoSQL
  #inherits StreamNoSQL, AbstractNoSQL
  constructor: (aClass)->
    if (this not instanceof StreamNoSQL)
      if isFunction aClass
        if not aClass::readStream
          extend aClass::, StreamNoSQL::
          return aClass
        throw new InvalidArgumentError("this class has been already streamable.")
    throw new InvalidArgumentError("please use StreamNoSQLTo(aClass) to add streamable to a database class.")

  readStream: (options, makeData)->
    opt = extend({}, @_options, options)
    ReadStream @, opt, makeData
  createReadStream: @::readStream
  valueStream: (options, makeData)->
    opt = extend({}, options)
    opt.keys = false
    @readStream opt, makeData
  createValueStream: @::valueStream
  keyStream: (options, makeData)->
    opt = extend({}, options)
    opt.values = false
    @readStream opt, makeData
  createKeyStream: @::keyStream
  writeStream: (options)->
    opt = extend({}, @_options, options)
    WriteStream @, opt
  createWriteStream: @::writeStream

