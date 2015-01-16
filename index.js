var ReadStream  = require("./lib/read-stream")
var WriteStream = require("./lib/write-stream")
var StreamNoSQL = require("./lib/nosql-stream")

StreamNoSQL.ReadStream   = ReadStream
StreamNoSQL.WriteStream  = WriteStream

module.exports  = StreamNoSQL

