chai            = require 'chai'
assert          = chai.assert
should          = chai.should()
ReadStream      = require '../lib/read-stream'
consts          = require '../lib/consts'
Memdown         = require 'memdown-sync'


FILTER_INCLUDED = consts.FILTER_INCLUDED
FILTER_EXCLUDED = consts.FILTER_EXCLUDED
FILTER_STOPPED  = consts.FILTER_STOPPED

allData = {}
for k in [0..100]
  allData[k] = Math.random().toString()
initTestDB = ->
  db = Memdown()
  db.open()
  for k,v of allData
    db.put(k, v)
  db

describe "ReadStream", ->
  db = initTestDB()
  describe ".create", ->
    it "should create a ReadStream via db argument", ->
      stream = ReadStream(db)
      should.exist stream, "stream"
      stream.should.be.instanceOf ReadStream
      should.exist stream._iterator, "iterator should be exists"
    it "should create a ReadStream via options.db", ->
      stream = ReadStream(null, {db:db})
      should.exist stream
      stream.should.be.instanceOf ReadStream
      should.exist stream._iterator, "iterator should be exists"
  describe ".read", ->
    it "should read all data through database", (done)->
      data = {}
      stream = ReadStream(db, {keyAsBuffer: false, ValueAsBuffer: false})
      stream.on "data", (item)->
        data[item.key] = item.value
      stream.on "error", (err)->
        done(err)
      stream.on "end", ()->
        assert.deepEqual data, allData
        done()
    it "should filter data through database", (done)->
      count = 0
      data = {}
      stream = ReadStream db,
        keyAsBuffer: false
        ValueAsBuffer: false
        filter: (k,v)->
          if k % 2 is 0
            return FILTER_EXCLUDED
          count++
          return FILTER_STOPPED if count > 10
      stream.on "data", (item)->
        data[item.key] = item.value
      stream.on "error", (err)->
        done(err)
      stream.on "end", ()->
        keys = Object.keys(data)
        count--
        assert.equal keys.length, count
        for k,v of data
          assert.ok k % 2 is 1, "key should be odd"
          assert.equal v, allData[k]
        done()
