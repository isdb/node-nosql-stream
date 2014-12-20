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
for k in [0..99]
  allData[("00"+k).slice(-2)] = Math.random().toString()
initTestDB = ->
  db = Memdown()
  db.open()
  for k,v of allData
    db.put(k, v)
  db

describe "ReadStream", ->
  db = initTestDB()
  it "test readable-stream@1.0.x", ->
    ###
     this is here to be an explicit reminder that we're tied to
     readable-stream@1.0.x so if someone comes along and wants
     to bump version they'll have to come here and read that we're
     using Streams2 explicitly across Node versions and will
     probably delay Streams3 adoption until Node 0.12 is released
     as readable-stream@1.1.x causes some problems with downstream
     modules
     see: https://github.com/rvagg/node-levelup/issues/216
    ###
    assert (/^~1\.0\.\d+$/).test(require('../package.json').dependencies['readable-stream'])
      , 'using readable-stream@1.0.x'

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
    it "should be limited the count", (done)->
      total = 2
      count = 0
      stream = ReadStream db,
        limit: total
        keyAsBuffer: false
        ValueAsBuffer: false
      stream.on "data", (item)->
        count++
      .on "error", (err)->
        done(err)
      .on "end", ()->
        assert.equal count, total
        done()
    it "should be key greater than 3 and less equal than 60 through database", (done)->
      count = 0
      stream = ReadStream db,
        gt: "03"
        lte: "60"
        keyAsBuffer: false
        ValueAsBuffer: false
      stream.on "data", (item)->
        item.key.should.be.gt(3).and.lte(60)
        count++
      .on "error", (err)->
        done(err)
      .on "end", ()->
        assert.equal count, 60-3
        done()
    it "should match data through database", (done)->
      count = 0
      stream = ReadStream db,
        match: "0*"
        keyAsBuffer: false
        ValueAsBuffer: false
      stream.on "data", (item)->
        item.key.should.be.gte(0).and.lte(9)
        count++
      .on "error", (err)->
        done(err)
      .on "end", ()->
        assert.equal count, 10
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
        assert.equal keys.length, count
        for k,v of data
          assert.ok k % 2 is 1, "key should be odd"
          assert.equal v, allData[k]
        done()
    it "should be next/last", (done)->
      count = 0
      lastKey = null
      nextPage = (db, aLastKey, aPageSize, cb)->
        pageData = {}
        pageCount = 0
        ReadStream db,
          next: aLastKey
          limit: aPageSize
          keyAsBuffer: false
          ValueAsBuffer: false
        .on "last", (aLastKey)->
          lastKey = aLastKey
        .on "data", (item)->
          item.key.should.be.gt(aLastKey) if aLastKey
          pageCount++
        .on "error", (err)->
          done(err)
        .on "end", ()->
          assert.equal pageCount, aPageSize
          cb() if cb
      nextPage db, lastKey, 2, ->
        lastKey.should.be.equal "01"
        nextPage db, lastKey, 2, ->
          lastKey.should.be.equal "03"
          done()