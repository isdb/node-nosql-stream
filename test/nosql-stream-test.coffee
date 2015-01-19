chai            = require 'chai'
assert          = chai.assert
should          = chai.should()
StreamNoSQL     = require '../lib/nosql-stream'
consts          = require '../lib/consts'
ReadStream      = require '../lib/read-stream'
WriteStream     = require '../lib/write-stream'
MemDB           = StreamNoSQL require 'nosql-memdb'
#LevelDB       = require 'nosql-leveldb'

FILTER_INCLUDED = consts.FILTER_INCLUDED
FILTER_EXCLUDED = consts.FILTER_EXCLUDED
FILTER_STOPPED  = consts.FILTER_STOPPED

fillChar = (c, len=2) ->
  result = ''
  len++
  while len -= 1
    result += c
  result
toFixedInt = (value, digits=2)->
  result = fillChar 0, digits
  (result+value).slice(-digits)


allData = {}
for k in [0..99]
  allData[toFixedInt(k, 2)] = Math.random().toString()
initTestDB = (location, writeData=true)->
  db = MemDB(location)
  #db = LevelDB('tempdb')
  db.open()
  if writeData then for k,v of allData
    db.put(k, v)
  db

describe "StreamNoSQL", ->
  describe "ReadStream", ->
    db = initTestDB()
    describe ".create", ->
      it "should create a ReadStream via db argument", ->
        stream = db.readStream()
        should.exist stream, "stream"
        stream.should.be.instanceOf ReadStream
        should.exist stream._iterator, "iterator should be exists"
    describe ".read", ->
      it "should read all data through database", (done)->
        data = {}
        stream = db.readStream {keyAsBuffer: false, ValueAsBuffer: false}
        #stream = ReadStream db, {keyAsBuffer: false, ValueAsBuffer: false}

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
        stream = db.readStream
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
        stream = db.readStream
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
        stream = db.readStream
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
        stream = db.readStream
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
          assert.equal count, 11
          for k,v of data
            assert.ok k % 2 is 1, "key should be odd"
            assert.equal v, allData[k]
          done()
      it "should be next/last", (done)->
        count = 0
        lastKey = null
        pageCount = 0
        nextPage = (db, aLastKey, aPageSize, cb)->
          pageData = []
          db.readStream
            next: aLastKey
            limit: aPageSize
            keyAsBuffer: false
            ValueAsBuffer: false
          .on "last", (aLastKey)->
            lastKey = aLastKey
          .on "data", (item)->
            item.key.should.be.gt(aLastKey) if aLastKey
            pageData.push item
          .on "error", (err)->
            done(err)
          .on "end", ()->
            pageCount++
            assert.equal pageData.length, aPageSize if pageCount < 50
            cb(pageData) if cb
        runNext = ->
          if lastKey and pageCount <= 50
            nextPage db, lastKey, 2, (data)->
              lastId = (pageCount-1)*2+1
              lastKey.should.be.equal toFixedInt(lastId,2) if lastKey
              if data.length
                data.should.be.deep.equal [
                  {key: toFixedInt(lastId-1), value: allData[toFixedInt(lastId-1)]}
                  {key: toFixedInt(lastId), value: allData[toFixedInt(lastId)]}
                ]
              else
                pageCount.should.be.equal 51
                should.not.exist lastKey
              runNext()
          else
            pageCount.should.be.equal 51
            should.not.exist lastKey
            done()
        nextPage db, lastKey, 2, (data)->
          lastId = (pageCount-1)*2+1
          #console.log "p=",pageCount, toFixedInt(lastId,2), lastKey
          lastKey.should.be.equal toFixedInt(lastId,2)
          data.should.be.deep.equal [
            {key: toFixedInt(lastId-1), value: allData[toFixedInt(lastId-1)]}
            {key: toFixedInt(lastId), value: allData[toFixedInt(lastId)]}
          ]
          runNext()
  describe "WriteStream", ->
    db = initTestDB('ws', false)
    describe ".create", ->
      it "should create a WriteStream via db argument", ->
        stream = db.writeStream()
        should.exist stream, "stream"
        stream.should.be.instanceOf WriteStream
        should.exist stream.db, "db should be exists"
    describe ".write", ->
      it "should write data to database", (done)->
        ws = db.writeStream()
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
        db2 = initTestDB("DB2", false)
        rs = db.readStream()
        ws = db2.writeStream()
        ws.on "finish", ->
          for k,v of allData
            value = db2.getSync(k)
            assert.equal value, v
          done()
        .on "error", (err)->
          done(err)
        rs.pipe ws
