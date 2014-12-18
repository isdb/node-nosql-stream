Errors        = require('abstract-object/Error')
createError   = Errors.createError

EncodingError         = createError('Encoding', 0x80)
Errors.EncodingError  = EncodingError

module.exports = Errors
