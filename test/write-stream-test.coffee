chai            = require 'chai'
assert          = chai.assert
should          = chai.should()
ReadStream      = require '../lib/read-stream'
WriteStream     = require '../lib/write-stream'
consts          = require '../lib/consts'
Memdown         = require 'memdown-sync'


FILTER_INCLUDED = consts.FILTER_INCLUDED
FILTER_EXCLUDED = consts.FILTER_EXCLUDED
FILTER_STOPPED  = consts.FILTER_STOPPED

allData = {}
for k in [0..100]
  allData[k] = Math.random().toString()

initTestDB = (location)->
  db = Memdown(location)
  db.open()
  db

describe "WriteStream", ->
  db = initTestDB()
  describe ".create", ->
    it "should create a WriteStream via db argument", ->
      stream = WriteStream(db)
      should.exist stream, "stream"
      stream.should.be.instanceOf WriteStream
      should.exist stream.db, "db should be exists"
    it "should create a WriteStream via options.db", ->
      stream = WriteStream(null, {db:db})
      should.exist stream
      stream.should.be.instanceOf WriteStream
      should.exist stream.db, "db should be exists"
  describe ".write", ->
    it "should write data to database", (done)->
      ws = WriteStream(db)
      ws.on "finish", ()->
        for k,v of allData
          value = db.getSync(k)
          assert.equal value, v
        done()
      .on "error", (err)->
        done(err)
      for k,v of allData
        ws.write
          key: k
          value: v
      ws.end()
    it "should pipe to database", (done)->
      db2 = initTestDB("DB2")
      rs = ReadStream(db)
      ws = WriteStream(db2)
      ws.on "finish", ->
        for k,v of allData
          value = db2.getSync(k)
          assert.equal value, v
        done()
      .on "error", (err)->
        done(err)
      rs.pipe ws
